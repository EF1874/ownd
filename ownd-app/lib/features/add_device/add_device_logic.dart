part of 'add_device_screen.dart';

// ignore: library_private_types_in_public_api
extension AddDeviceLogic on _AddDeviceScreenState {
  double _getCurrentFirstCost() {
    double? price = double.tryParse(_priceCtr.text);
    double? first = double.tryParse(_firstPriceCtr.text);

    if (_discount && first != null) {
      return first;
    }
    return price ?? 0.0;
  }

  void _updateTotalStr() {
    double cost = _getCurrentFirstCost();
    double newTotal = _baseAccumulatedPrice + cost;

    String newText =
        newTotal == 0.0 &&
            _priceCtr.text.isEmpty &&
            _firstPriceCtr.text.isEmpty &&
            _baseAccumulatedPrice == 0.0
        ? ''
        : newTotal % 1 == 0
        ? newTotal.toInt().toString()
        : newTotal.toStringAsFixed(2);

    // Remove trailing zeros if decimal
    if (newText.contains('.')) {
      newText = double.parse(newText).toString();
      if (newText.endsWith('.0')) {
        newText = newText.substring(0, newText.length - 2);
      }
    }

    if (_totalAccumulatedPriceCtr.text != newText) {
      // Temporarily remove listener to prevent loop
      _totalAccumulatedPriceCtr.removeListener(_updateBase);
      _totalAccumulatedPriceCtr.text = newText;
      _totalAccumulatedPriceCtr.addListener(_updateBase);
    }
  }

  void _updateBase() {
    double? total = double.tryParse(_totalAccumulatedPriceCtr.text);
    double cost = _getCurrentFirstCost();
    _baseAccumulatedPrice = (total ?? 0.0) - cost;
  }

  void _calculateNextBilling({bool force = false}) {
    // Editing an existing subscription should keep the saved due date unless the
    // user explicitly changes the cycle.
    if (widget.device != null && !force) return;
    if (_cycleType == null || _cycleType == CycleType.oneTime) return;

    updateState(
      () => _nextBillingDate = SubscriptionUtils.calculateNextBillingDate(
        _purchaseDate,
        _cycleType!,
      ),
    );
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
        ..isAutoRenew = _isSub ? _isAutoRenew : true
        ..nextBillingDate = _isSub ? _nextBillingDate : null
        ..reminderDays = normalizedReminderDays
        ..hasReminder = normalizedReminderDays > 0
        ..firstPeriodPrice = (_isSub && _discount)
            ? double.tryParse(_firstPriceCtr.text)
            : null
        ..periodPrice = _isSub ? double.parse(_priceCtr.text) : null
        ..totalAccumulatedPrice =
            double.tryParse(_totalAccumulatedPriceCtr.text) ??
            _totalAccumulatedPrice;

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
        // If user input total accumulated price, use it. Otherwise default to first period or price.
        final inputTotal = double.tryParse(_totalAccumulatedPriceCtr.text);
        if (inputTotal != null) {
          device.totalAccumulatedPrice = inputTotal;
        } else {
          device.totalAccumulatedPrice =
              device.firstPeriodPrice ?? device.price;
        }
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

  void _showSnack(String msg) => AppToast.show(
    context,
    msg,
    isError: msg.contains('失败') || msg.contains('错误') || msg.contains('请选择'),
  );
}
