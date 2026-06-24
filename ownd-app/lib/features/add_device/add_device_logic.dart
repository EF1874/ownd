part of 'add_device_screen.dart';

// ignore: library_private_types_in_public_api
extension AddDeviceLogic on _AddDeviceScreenState {
  void _calculateNextBilling({bool force = false}) {
    // Existing subscription dates are edited from the subscription records.
    if (widget.device != null) return;
    if (_cycleType == null || _cycleType == CycleType.oneTime) return;

    updateState(
      () => _nextBillingDate = SubscriptionUtils.calculateNextBillingDate(
        _purchaseDate,
        _cycleType!,
        calculationMode: _cycleCalculationMode,
        cycleDays: _cycleDays,
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
    final inputPrice = double.tryParse(_priceCtr.text.trim());
    if (!_isSub && inputPrice == null) return _showSnack('请输入价格');
    if (_isSub && widget.device == null && inputPrice == null) {
      return _showSnack('请输入首期价格');
    }

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
      final editingExistingSubscription = _isSub && widget.device != null;
      final originalDevice = widget.device;
      final price = editingExistingSubscription
          ? originalDevice!.price
          : inputPrice!;

      final device = widget.device ?? Device();
      device
        ..name = _nameCtr.text.trim().isEmpty
            ? finalCat.name
            : _nameCtr.text.trim()
        ..price = price
        ..purchaseDate = editingExistingSubscription
            ? originalDevice!.purchaseDate
            : _purchaseDate
        ..platform = selectedPlatform?.name ?? ''
        ..platformUuid = selectedPlatform?.uuid
        ..warrantyEndDate = _warrantyDate
        ..backupDate = _backupDate
        ..scrapDate = _scrapDate
        ..customIconPath = _customIconPath
        ..imagePath = _imagePath
        ..notes = _isSub ? null : _notesCtr.text.trim()
        ..tags = _tagsCtr.text.trim().isEmpty
            ? []
            : _tagsCtr.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
        ..category.value = finalCat
        ..cycleType = _isSub
            ? editingExistingSubscription
                  ? originalDevice!.cycleType
                  : _cycleType
            : null
        ..cycleCalculationMode = _isSub
            ? editingExistingSubscription
                  ? originalDevice!.cycleCalculationMode
                  : _cycleCalculationMode
            : CycleCalculationMode.calendar
        ..cycleDays = _isSub
            ? editingExistingSubscription
                  ? originalDevice!.cycleDays
                  : _cycleDays
            : null
        ..isAutoRenew = _isSub ? _isAutoRenew : true
        ..nextBillingDate = _isSub
            ? editingExistingSubscription
                  ? originalDevice!.nextBillingDate
                  : _nextBillingDate
            : null
        ..hasReminder = _isSub && _hasReminder
        ..renewalPrice = (_isSub && _isAutoRenew)
            ? double.tryParse(_renewalPriceCtr.text)
            : null
        ..periodPrice = _isSub
            ? editingExistingSubscription
                  ? originalDevice!.periodPrice
                  : price
            : null;

      if (widget.device == null && _isSub) {
        device.totalAccumulatedPrice = device.price;
      }
      if (!editingExistingSubscription) {
        device.totalAccumulatedPrice = _isSub
            ? _calculatedSubscriptionTotal(device)
            : price;
      }

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

  double _currentSubscriptionPrice() {
    final current = _currentSubscriptionHistory();
    return current?.price ??
        widget.device?.price ??
        double.tryParse(_priceCtr.text) ??
        0;
  }

  double _subscriptionTotalPreview() {
    final histories = widget.device?.history ?? const <SubscriptionHistory>[];
    if (histories.isEmpty) return _currentSubscriptionPrice();
    return histories.fold<double>(0, (sum, item) => sum + item.price);
  }

  SubscriptionHistory? _currentSubscriptionHistory() {
    final histories =
        widget.device?.history.toList() ?? <SubscriptionHistory>[];
    if (histories.isEmpty) return null;

    final today = SubscriptionUtils.dateOnly(DateTime.now());
    for (final history in histories) {
      final start = history.startDate;
      final end = history.endDate;
      if (start == null || end == null) continue;
      final startDay = SubscriptionUtils.dateOnly(start);
      final endDay = SubscriptionUtils.dateOnly(end);
      if (!today.isBefore(startDay) && !today.isAfter(endDay)) return history;
    }

    histories.sort((a, b) {
      final aDate = a.startDate ?? a.endDate ?? DateTime(0);
      final bDate = b.startDate ?? b.endDate ?? DateTime(0);
      return aDate.compareTo(bDate);
    });
    return histories.last;
  }

  void _showSnack(String msg) => AppToast.show(
    context,
    msg,
    isError: msg.contains('失败') || msg.contains('错误') || msg.contains('请选择'),
  );
}
