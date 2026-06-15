part of 'add_device_screen.dart';

// ignore: library_private_types_in_public_api
extension AddDeviceLogic on _AddDeviceScreenState {
  void _calculateNextBilling({bool force = false}) {
    // Editing an existing subscription should keep the saved due date unless the
    // user explicitly changes the cycle.
    if (widget.device != null && !force) return;
    if (_cycleType == null || _cycleType == CycleType.oneTime) return;

    updateState(
      () => _nextBillingDate = SubscriptionUtils.calculateNextBillingDate(
        _purchaseDate,
        _cycleType!,
        calculationMode: _isAutoRenew
            ? _cycleCalculationMode
            : CycleCalculationMode.calendar,
        cycleDays: _isAutoRenew ? _cycleDays : null,
      ),
    );
  }

  void _normalizeCycleCalculation() {
    _cycleCalculationMode = CycleCalculationMode.calendar;
    _cycleDays = null;
  }

  Future<void> _pickDate({
    bool isWarranty = false,
    bool isBackup = false,
    bool isScrap = false,
    bool isBilling = false,
  }) async {
    final initialDate = isBilling
        ? (_nextBillingDate ?? DateTime.now())
        : isWarranty
        ? (_warrantyDate ?? DateTime.now())
        : isBackup
        ? (_backupDate ?? DateTime.now())
        : isScrap
        ? (_scrapDate ?? DateTime.now())
        : _purchaseDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CH'),
    );
    if (picked != null) {
      updateState(() {
        if (isBilling) {
          _nextBillingDate = picked;
        } else if (isWarranty) {
          _warrantyDate = picked;
        } else if (isBackup) {
          _backupDate = picked;
        } else if (isScrap) {
          _scrapDate = picked;
        } else {
          _purchaseDate = picked;
          if (_isSub && widget.device == null) _calculateNextBilling();
        }
      });
    }
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) return _showSnack('请选择分类');
    if (_isSub && _cycleType == null) return _showSnack('请选择周期类型');

    updateState(() => _isLoading = true);
    try {
      Category finalCat = _selectedCategory!;
      final customCategory = _catCtr.text.trim();
      if (_selectedCategory?.name == '其它' && customCategory.isNotEmpty) {
        finalCat = await ref
            .read(categoryRepositoryProvider)
            .ensureCategory(customCategory, parent: _selectedCategory);
      } else if (_selectedCategory?.uuid == null || _selectedCategory!.id < 0) {
        finalCat = await ref
            .read(categoryRepositoryProvider)
            .ensureCategory(
              customCategory.isNotEmpty ? customCategory : finalCat.name,
            );
      }

      final selectedPlatformName =
          (_selectedPlatform == '其它' ? _platformCtr.text : _selectedPlatform)
              ?.trim();
      final selectedPlatform =
          selectedPlatformName != null && selectedPlatformName.isNotEmpty
          ? await ref
                .read(platformRepositoryProvider)
                .ensurePlatform(selectedPlatformName)
          : null;
      final normalizedReminderDays = _isSub
          ? _normalizeReminderDays(_reminderDays)
          : 0;

      final device = widget.device ?? Device();
      device
        ..name = _nameCtr.text.trim().isEmpty
            ? finalCat.name
            : _nameCtr.text.trim()
        ..price = double.parse(_priceCtr.text)
        ..purchaseDate = _purchaseDate
        ..platform = selectedPlatform?.name ?? ''
        ..platformUuid = selectedPlatform?.uuid
        ..warrantyEndDate = _warrantyDate
        ..backupDate = _backupDate
        ..scrapDate = _scrapDate
        ..customIconPath = _customIconPath
        ..imagePath = _imagePath
        ..notes = _notesCtr.text.trim().isEmpty ? null : _notesCtr.text.trim()
        ..tags = _tagsCtr.text.trim().isEmpty
            ? []
            : _tagsCtr.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
        ..category.value = finalCat
        ..cycleType = _isSub ? _cycleType : null
        ..cycleCalculationMode = _isSub && _isAutoRenew
            ? _cycleCalculationMode
            : CycleCalculationMode.calendar
        ..cycleDays = _isSub && _isAutoRenew ? _cycleDays : null
        ..isAutoRenew = _isSub ? _isAutoRenew : true
        ..nextBillingDate = _isSub ? _nextBillingDate : null
        ..reminderDays = normalizedReminderDays
        ..hasReminder = normalizedReminderDays > 0
        ..renewalPrice = (_isSub && _isAutoRenew)
            ? double.tryParse(_renewalPriceCtr.text)
            : null
        ..periodPrice = _isSub ? double.parse(_priceCtr.text) : null;

      // Pruning Logic: Remove history records that are "in the future" relative to the new billing date
      if (_isSub && _nextBillingDate != null) {
        // Ensure history is mutable
        device.history = device.history.toList();
        device.history.removeWhere((h) {
          final end = h.endDate;
          return end != null && end.isAfter(_nextBillingDate!);
        });
      }

      if (widget.device == null && _isSub) {
        device.totalAccumulatedPrice = device.price;
      }
      device.totalAccumulatedPrice = _isSub
          ? _calculatedSubscriptionTotal(device)
          : double.parse(_priceCtr.text);

      if (widget.device != null) {
        await ref.read(deviceRepositoryProvider).updateDevice(device);
      } else {
        await ref.read(deviceRepositoryProvider).addDevice(device);
      }

      ref.invalidate(categoryTreeProvider);
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();

      // Handle Notifications
      final subService = ref.read(subscriptionServiceProvider);

      // Subscriptions
      if (device.hasReminder && device.nextBillingDate != null) {
        await subService.scheduleSubscriptionNotification(device);
      } else {
        await subService.cancelSubscriptionNotification(device);
      }

      // Warranty
      if (device.warrantyEndDate != null) {
        await subService.scheduleWarrantyNotification(device);
      } else {
        await subService.cancelWarrantyNotification(device);
      }

      if (mounted) {
        _showSnack(widget.device != null ? '修改成功' : '添加成功');
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) _showSnack('保存失败: ${userErrorMessage(e)}');
    } finally {
      if (mounted) updateState(() => _isLoading = false);
    }
  }

  double _calculatedSubscriptionTotal(Device device) {
    if (device.history.isEmpty) return device.price;
    return device.history.fold<double>(0, (sum, item) => sum + item.price);
  }

  void _showSnack(String msg) => AppToast.show(
    context,
    msg,
    isError: msg.contains('失败') || msg.contains('错误') || msg.contains('请选择'),
  );
}
