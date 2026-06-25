import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/error_messages.dart';
import '../../shared/services/image_service.dart';

import '../../data/models/category.dart';
import '../../data/models/device.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/platform_repository.dart';
import '../../features/navigation/navigation_provider.dart';
import '../../shared/utils/category_tree_utils.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/services/subscription_service.dart';
import '../home/home_devices_provider.dart';

import 'widgets/basic_info_section.dart';
import 'widgets/date_section.dart';
import 'widgets/subscription_section.dart';

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
  final _renewalPriceCtr = TextEditingController();
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
  CycleCalculationMode _cycleCalculationMode = CycleCalculationMode.calendar;
  int? _cycleDays;
  bool _isAutoRenew = false;
  DateTime? _nextBillingDate;
  bool _hasReminder = false;

  late final String _uuid; // Track UUID for file naming

  bool get _isSub => CategoryTreeUtils.isVirtualSubscription(_selectedCategory);

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final d = widget.device!;
      final currentSubscription = _currentSubscriptionHistory();
      _nameCtr.text = d.name;
      _priceCtr.text = (currentSubscription?.price ?? d.price).toString();
      _purchaseDate = currentSubscription?.startDate ?? d.purchaseDate;
      _warrantyDate = d.warrantyEndDate;
      _backupDate = d.backupDate;
      _scrapDate = d.scrapDate;
      _selectedCategory = d.category.value;
      _selectedPlatform = d.platform;
      _customIconPath = d.customIconPath;
      _imagePath = d.imagePath;
      _notesCtr.text = d.notes ?? '';
      _tagsCtr.text = d.tags.join(', ');
      _cycleType = currentSubscription?.cycleType ?? d.cycleType;
      _cycleCalculationMode =
          currentSubscription?.cycleCalculationMode ?? d.cycleCalculationMode;
      _cycleDays = currentSubscription?.cycleDays ?? d.cycleDays;
      _isAutoRenew = d.isAutoRenew;
      _nextBillingDate = currentSubscription?.endDate ?? d.nextBillingDate;
      _hasReminder = d.hasReminder;
      _renewalPriceCtr.text =
          d.renewalPrice?.toString() ??
          (d.isAutoRenew ? d.price.toString() : '');
      _uuid = d.uuid;
    } else {
      _uuid = const Uuid().v4();
    }
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
    _renewalPriceCtr.dispose();
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
                          if (_isSub) {
                            _cycleType ??= CycleType.monthly;
                            if (_nextBillingDate == null) {
                              _calculateNextBilling();
                            }
                            _isAutoRenew = false;
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
                        renewalPriceController: _renewalPriceCtr,
                        isEditing: widget.device != null,
                        currentPrice: _currentSubscriptionPrice(),
                        totalPrice: _subscriptionTotalPreview(),
                        purchaseDate: _purchaseDate,
                        nextBillingDate: _nextBillingDate,
                        cycleType: _cycleType,
                        cycleCalculationMode: _cycleCalculationMode,
                        cycleDays: _cycleDays,
                        isAutoRenew: _isAutoRenew,
                        hasReminder: _hasReminder,
                        onCycleTypeChanged: (v) => setState(() {
                          _cycleType = v;
                          _normalizeCycleCalculation();
                          _calculateNextBilling(force: true);
                        }),
                        onCycleCalculationChanged: (mode, days) => setState(() {
                          _cycleCalculationMode = mode;
                          _cycleDays = days;
                          _calculateNextBilling(force: true);
                        }),
                        onAutoRenewChanged: (v) {
                          setState(() {
                            _isAutoRenew = v;
                            if (v && _renewalPriceCtr.text.trim().isEmpty) {
                              _renewalPriceCtr.text = _priceCtr.text;
                            }
                          });
                          _calculateNextBilling(force: true);
                        },
                        onReminderChanged: (v) => setState(() {
                          _hasReminder = v;
                        }),
                        onPickDate: () => _pickDate(),
                        onPickBillingDate: () => _pickDate(isBilling: true),
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
                      showNotes: !_isSub,
                      onPickImage: _pickPhoto,
                      onRemoveImage: _removePhoto,
                    ),
                    const _KeyboardBottomSpacer(baseHeight: 48),
                  ],
                ),
              ),
            ),
          ),
          _KeyboardAwareSaveBar(isLoading: _isLoading, onPressed: _saveDevice),
        ],
      ),
    );
  }
}

class _KeyboardAwareSaveBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _KeyboardAwareSaveBar({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: AppButton(
            text: '保存',
            onPressed: onPressed,
            isLoading: isLoading,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _KeyboardBottomSpacer extends StatelessWidget {
  final double baseHeight;

  const _KeyboardBottomSpacer({required this.baseHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: baseHeight + MediaQuery.viewInsetsOf(context).bottom,
    );
  }
}
