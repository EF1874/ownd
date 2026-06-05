import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../shared/services/image_service.dart';

import '../../data/models/category.dart';
import '../../data/models/device.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/platform_repository.dart';
import '../../features/navigation/navigation_provider.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/services/subscription_service.dart';

import 'widgets/basic_info_section.dart';
import 'widgets/date_section.dart';
import 'widgets/subscription_section.dart';
import 'widgets/renew_dialog.dart';

import 'widgets/additional_info_section.dart';

part 'add_device_logic.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  final Device? device;
  const AddDeviceScreen({super.key, this.device});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _priceCtr = TextEditingController();
  final _platformCtr = TextEditingController();
  final _catCtr = TextEditingController();
  final _firstPriceCtr = TextEditingController();
  final _totalAccumulatedPriceCtr = TextEditingController();
  final _notesCtr = TextEditingController();
  final _tagsCtr = TextEditingController();

  Category? _selectedCategory;
  String? _selectedPlatform;
  String? _customIconPath;
  String? _imagePath;
  bool _isLoading = false;

  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyDate;
  DateTime? _backupDate;
  DateTime? _scrapDate;

  CycleType? _cycleType;
  bool _isAutoRenew = false;
  DateTime? _nextBillingDate;
  int _reminderDays = 1;
  bool _hasReminder = false;
  bool _discount = false;
  double _totalAccumulatedPrice = 0.0;

  DateTime? _originalNextBillingDate;
  bool _hasPendingRenewal = false;
  double _lastRenewPrice = 0.0;
  DateTime? _preRenewalNextBillingDate;
  double _baseAccumulatedPrice = 0.0;

  late final String _uuid; // Track UUID for file naming

  bool get _isSub =>
      (_selectedCategory?.parentName ??
          CategoryConfig.getMajorCategory(_selectedCategory?.name)) ==
      '虚拟订阅';

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final d = widget.device!;
      _nameCtr.text = d.name;
      _priceCtr.text = d.price.toString();
      _purchaseDate = d.purchaseDate;
      _warrantyDate = d.warrantyEndDate;
      _backupDate = d.backupDate;
      _scrapDate = d.scrapDate;
      _selectedCategory = d.category.value;
      _selectedPlatform = d.platform;
      _customIconPath = d.customIconPath;
      _imagePath = d.imagePath;
      _notesCtr.text = d.notes ?? '';
      _tagsCtr.text = d.tags.join(', ');
      _cycleType = d.cycleType;
      _isAutoRenew = d.isAutoRenew;
      _nextBillingDate = d.nextBillingDate;
      _hasReminder = d.hasReminder;
      _firstPriceCtr.text = d.firstPeriodPrice?.toString() ?? '';
      _discount = d.firstPeriodPrice != null;
      _totalAccumulatedPrice = d.totalAccumulatedPrice;
      _totalAccumulatedPriceCtr.text = d.totalAccumulatedPrice % 1 == 0
          ? d.totalAccumulatedPrice.toInt().toString()
          : d.totalAccumulatedPrice.toString();
      _originalNextBillingDate = d.nextBillingDate;

      // Calculate base price from existing total
      double currentCost = d.firstPeriodPrice ?? d.price;
      _baseAccumulatedPrice = d.totalAccumulatedPrice - currentCost;
      _uuid = d.uuid;
    } else {
      _baseAccumulatedPrice = 0.0;
      _uuid = const Uuid().v4();
    }

    _priceCtr.addListener(_updateTotalStr);
    _firstPriceCtr.addListener(_updateTotalStr);
    _totalAccumulatedPriceCtr.addListener(_updateBase);
  }

  // Helper to allow extension to call setState (which is protected)
  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    _priceCtr.dispose();
    _platformCtr.dispose();
    _catCtr.dispose();
    _firstPriceCtr.dispose();
    _totalAccumulatedPriceCtr.dispose();
    _notesCtr.dispose();
    _tagsCtr.dispose();
    super.dispose();
  }

  Future<void> _pickCustomIcon() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickAndCropImage(
      context: context,
      source: ImageSource.gallery,
      isSquare: true,
    );

    if (file != null) {
      final savedPath = await imageService.saveImageToAppDirectory(
        file,
        _uuid,
        isIcon: true,
      );
      if (savedPath != null) {
        updateState(() => _customIconPath = savedPath);
      }
    }
  }

  Future<void> _pickPhoto() async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickAndCropImage(
      context: context,
      source: ImageSource.gallery,
      isSquare: false,
    );

    if (file != null) {
      final savedPath = await imageService.saveImageToAppDirectory(
        file,
        _uuid,
        isIcon: false,
      );
      if (savedPath != null) {
        updateState(() => _imagePath = savedPath);
      }
    }
  }

  void _removeCustomIcon() {
    setState(() {
      _customIconPath = null;
    });
  }

  void _removePhoto() {
    setState(() {
      _imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.device != null ? '编辑物品' : '添加物品')),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                if (n.direction == ScrollDirection.reverse) {
                  ref.read(bottomNavBarVisibleProvider.notifier).state = false;
                } else if (n.direction == ScrollDirection.forward) {
                  ref.read(bottomNavBarVisibleProvider.notifier).state = true;
                }
                return true;
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    BasicInfoSection(
                      nameController: _nameCtr,
                      priceController: _priceCtr,
                      customPlatformController: _platformCtr,
                      customCategoryController: _catCtr,
                      selectedCategory: _selectedCategory,
                      selectedPlatform: _selectedPlatform,
                      customIconPath: _customIconPath,
                      onPickCustomIcon: _pickCustomIcon,
                      onRemoveCustomIcon: _removeCustomIcon,
                      onCategorySelected: (c) {
                        setState(() {
                          _selectedCategory = c;
                          if (c != null && widget.device == null) {
                            _nameCtr.text = c.name;
                          }
                          if (_isSub) {
                            if (_nextBillingDate == null) {
                              _calculateNextBilling();
                            }
                            _isAutoRenew = false;
                            _hasReminder = false;
                          }
                        });
                      },
                      onPlatformSelected: (p) =>
                          setState(() => _selectedPlatform = p),
                    ),
                    const SizedBox(height: 16),
                    if (_isSub)
                      SubscriptionSection(
                        priceController: _priceCtr,
                        firstPeriodPriceController: _firstPriceCtr,
                        totalAccumulatedPriceController:
                            _totalAccumulatedPriceCtr,
                        purchaseDate: _purchaseDate,
                        nextBillingDate: _nextBillingDate,
                        cycleType: _cycleType,
                        isAutoRenew: _isAutoRenew,
                        hasReminder: _hasReminder,
                        reminderDays: _reminderDays,
                        hasFirstPeriodDiscount: _discount,
                        device: widget.device,
                        onCycleTypeChanged: (v) => setState(() {
                          _cycleType = v;
                          _calculateNextBilling();
                        }),
                        onAutoRenewChanged: (v) => setState(() {
                          _isAutoRenew = v;
                          if (!v) _discount = false;
                        }),
                        onReminderChanged: (v) =>
                            setState(() => _hasReminder = v),
                        onReminderDaysChanged: (v) =>
                            setState(() => _reminderDays = v),
                        onDiscountChanged: (v) => updateState(() {
                          _discount = v;
                          _updateTotalStr();
                        }),
                        onPickDate: () => _pickDate(),
                        onPickBillingDate: () => _pickDate(isBilling: true),
                        onShowRenewDialog: _showRenewDialog,
                      )
                    else
                      DateSection(
                        purchaseDate: _purchaseDate,
                        warrantyDate: _warrantyDate,
                        backupDate: _backupDate,
                        scrapDate: _scrapDate,
                        onPickDate: (w, b, s, billing) => _pickDate(
                          isWarranty: w,
                          isBackup: b,
                          isScrap: s,
                          isBilling: billing,
                        ),
                        onClearBackupDate: (_) =>
                            setState(() => _backupDate = null),
                        onClearScrapDate: (_) =>
                            setState(() => _scrapDate = null),
                      ),
                    const SizedBox(height: 16),
                    AdditionalInfoSection(
                      notesController: _notesCtr,
                      tagsController: _tagsCtr,
                      imagePath: _imagePath,
                      onPickImage: _pickPhoto,
                      onRemoveImage: _removePhoto,
                    ),
                    const SizedBox(
                      height: 48,
                    ), // Padding at the bottom for scroll
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: AppButton(
                text: '保存',
                onPressed: _saveDevice,
                isLoading: _isLoading,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
