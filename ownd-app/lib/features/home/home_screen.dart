import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../shared/config/category_config.dart';
import '../../data/services/preferences_service.dart';
import '../add_device/add_device_screen.dart';
import '../navigation/navigation_provider.dart';
import 'widgets/multi_select_filter_delegate.dart';
import 'widgets/home_sliver_app_bar.dart';
import 'widgets/home_device_list.dart';

final deviceListProvider = StreamProvider((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.watchAllDevices();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;

  // Sort state
  String _sortField = 'date'; // date, price, expiry
  bool _isAscending = false;

  Set<String> _selectedCategories = {};
  String? _selectedPlatformFilter;
  final Set<String> _selectedTags = {};

  // State
  bool _showExpiringList = true;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesServiceProvider);
    _isGridView = prefs.isGridView;
    _showExpiringList = prefs.showExpiringList;
    // We might need to migrate old string prefs or just default.
    // For now defaulting to date desc.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Device> _processDevices(List<Device> devices) {
    var result = List<Device>.from(devices);

    // Filter by Name
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result
          .where((d) => d.name.toLowerCase().contains(query))
          .toList();
    }

    // Filter by Category
    if (_selectedCategories.isNotEmpty) {
      result = result.where((d) {
        final category = d.category.value;
        final major =
            category?.parentName ??
            CategoryConfig.getMajorCategory(category?.name);
        return _selectedCategories.contains(major);
      }).toList();
    }

    // Filter by Platform
    if (_selectedPlatformFilter != null) {
      result = result
          .where((d) => d.platform == _selectedPlatformFilter)
          .toList();
    }

    // Filter by Tags
    if (_selectedTags.isNotEmpty) {
      result = result.where((d) {
        return _selectedTags.every((tag) => d.tags.contains(tag));
      }).toList();
    }

    // Sort
    int sortMultiplier = _isAscending ? 1 : -1;

    result.sort((a, b) {
      switch (_sortField) {
        case 'price':
          return (a.price.compareTo(b.price)) * sortMultiplier;
        case 'expiry':
          final aDate = _getExpiryDate(a);
          final bDate = _getExpiryDate(b);
          // Handle nulls: put nulls at the end regardless of order?
          // Or follow standard sort? Let's put nulls last.
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return (aDate.compareTo(bDate)) * sortMultiplier;
        case 'date':
        default:
          return (a.purchaseDate.compareTo(b.purchaseDate)) * sortMultiplier;
      }
    });

    return result;
  }

  DateTime? _getExpiryDate(Device d) {
    final category = d.category.value;
    final major =
        category?.parentName ?? CategoryConfig.getMajorCategory(category?.name);
    if (major == '虚拟订阅') {
      return d.nextBillingDate;
    }
    return d.scrapDate ?? d.warrantyEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(deviceListProvider);
    final categoryTreeAsync = ref.watch(categoryTreeProvider);
    final majorCategories =
        categoryTreeAsync.valueOrNull
            ?.map((category) => category.name)
            .toList() ??
        const <String>[];

    return Scaffold(
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                ref.read(bottomNavBarVisibleProvider.notifier).state = false;
              } else if (notification.direction == ScrollDirection.forward) {
                ref.read(bottomNavBarVisibleProvider.notifier).state = true;
              }
              return true;
            },
            child: CustomScrollView(
              slivers: [
                HomeSliverAppBar(
                  searchController: _searchController,
                  isGridView: _isGridView,
                  showExpiringList: _showExpiringList,
                  sortField: _sortField,
                  isAscending: _isAscending,
                  selectedPlatformFilter: _selectedPlatformFilter,
                  onGridViewChanged: (val) {
                    setState(() => _isGridView = val);
                    ref.read(preferencesServiceProvider).setGridView(val);
                  },
                  onShowExpiringChanged: (val) {
                    setState(() => _showExpiringList = val);
                    ref
                        .read(preferencesServiceProvider)
                        .setShowExpiringList(val);
                  },
                  onSortFieldChanged: (val) => setState(() => _sortField = val),
                  onSortOrderChanged: (val) =>
                      setState(() => _isAscending = val),
                  onPlatformFilterChanged: (val) =>
                      setState(() => _selectedPlatformFilter = val),
                  onSearchChanged: () => setState(() {}),
                  onAddDevice: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddDeviceScreen(),
                      ),
                    );
                  },
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: MultiSelectFilterDelegate(
                    selectedCategories: _selectedCategories,
                    categories: majorCategories,
                    onSelectionChanged: (categories) {
                      setState(() => _selectedCategories = categories);
                    },
                  ),
                ),
                if (devicesAsync.valueOrNull != null &&
                    devicesAsync.valueOrNull!.any((d) => d.tags.isNotEmpty))
                  SliverToBoxAdapter(
                    child: Container(
                      height: 48,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      alignment: Alignment.centerLeft,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final tag
                              in (devicesAsync.valueOrNull!
                                  .expand((d) => d.tags)
                                  .toSet()
                                  .toList()
                                ..sort()))
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 8,
                                top: 8,
                                bottom: 8,
                              ),
                              child: FilterChip(
                                label: Text('#$tag'),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedTags.contains(tag)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                selected: _selectedTags.contains(tag),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                devicesAsync.when(
                  data: (devices) {
                    final processed = _processDevices(devices);
                    return HomeDeviceList(
                      processedDevices: processed,
                      allDevices: devices,
                      showExpiringList: _showExpiringList,
                      isGridView: _isGridView,
                      categoryName:
                          _selectedCategories.isNotEmpty &&
                              _selectedCategories.length == 1
                          ? _selectedCategories.first
                          : null,
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => SliverFillRemaining(
                    child: Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
