import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/services/preferences_service.dart';
import '../add_device/add_device_screen.dart';
import '../navigation/navigation_provider.dart';
import 'widgets/multi_select_filter_delegate.dart';
import 'widgets/home_sliver_app_bar.dart';
import 'widgets/home_device_list.dart';
import 'home_devices_provider.dart';
import '../../shared/widgets/app_toast.dart';

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
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  bool _isGridView = false;

  // Sort state
  String _sortField = 'default'; // default, date, price, expiry
  bool _isAscending = false;

  Set<String> _selectedCategories = {};
  String? _selectedPlatformFilter;
  final Set<String> _selectedTags = {};

  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(preferencesServiceProvider);
    _isGridView = prefs.isGridView;
    _statusFilter = prefs.expiringSoonOnly ? 'expiring-soon' : null;
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeDevicesNotifierProvider.notifier).loadNextPage();
    }
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref
            .read(homeDevicesNotifierProvider.notifier)
            .updateSearch(_searchController.text.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeDevicesState = ref.watch(homeDevicesNotifierProvider);
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
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(homeDevicesNotifierProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  HomeSliverAppBar(
                    searchController: _searchController,
                    isGridView: _isGridView,
                    statusFilter: _statusFilter,
                    sortField: _sortField,
                    isAscending: _isAscending,
                    selectedPlatformFilter: _selectedPlatformFilter,
                    onGridViewChanged: (val) {
                      setState(() => _isGridView = val);
                      ref.read(preferencesServiceProvider).setGridView(val);
                    },
                    onStatusFilterChanged: (val) {
                      setState(() => _statusFilter = val);
                      ref
                          .read(preferencesServiceProvider)
                          .setExpiringSoonOnly(val == 'expiring-soon');
                      ref
                          .read(homeDevicesNotifierProvider.notifier)
                          .updateStatusFilter(val);
                    },
                    onSortFieldChanged: (val) {
                      setState(() => _sortField = val);
                      ref
                          .read(homeDevicesNotifierProvider.notifier)
                          .updateSortField(val);
                    },
                    onSortOrderChanged: (val) {
                      setState(() => _isAscending = val);
                      ref
                          .read(homeDevicesNotifierProvider.notifier)
                          .updateSortOrder(val);
                    },
                    onPlatformFilterChanged: (val) {
                      setState(() => _selectedPlatformFilter = val);
                      ref
                          .read(homeDevicesNotifierProvider.notifier)
                          .updatePlatformFilter(val);
                    },
                    onSearchChanged: () {},
                    onAddDevice: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddDeviceScreen(),
                        ),
                      );
                      await ref
                          .read(homeDevicesNotifierProvider.notifier)
                          .refresh();
                    },
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: MultiSelectFilterDelegate(
                      selectedCategories: _selectedCategories,
                      categories: majorCategories,
                      onSelectionChanged: (categories) {
                        setState(() => _selectedCategories = categories);
                        ref
                            .read(homeDevicesNotifierProvider.notifier)
                            .updateCategories(categories);
                      },
                    ),
                  ),
                  if (homeDevicesState.devices.any((d) => d.tags.isNotEmpty))
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
                                in (homeDevicesState.devices
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
                                    ref
                                        .read(
                                          homeDevicesNotifierProvider.notifier,
                                        )
                                        .toggleTag(tag);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (homeDevicesState.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (homeDevicesState.error != null)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '加载失败: ${homeDevicesState.error}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    HomeDeviceList(
                      processedDevices: homeDevicesState.devices,
                      isGridView: _isGridView,
                      emptyMessage: _emptyMessage(homeDevicesState),
                      onDeleteComplete: (success, error) {
                        debugPrint(
                          '[HomeScreen] onDeleteComplete: success=$success, error=$error',
                        );
                        AppToast.show(
                          context,
                          success ? '删除成功' : '删除失败: ${error ?? '请稍后重试'}',
                          isError: !success,
                        );
                        unawaited(
                          ref
                              .read(homeDevicesNotifierProvider.notifier)
                              .silentRefresh(),
                        );
                      },
                    ),
                    if (homeDevicesState.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessage(HomeDevicesState state) {
    if (state.search.isNotEmpty) return '没有搜到相关物品';
    final hasFilter =
        state.selectedCategories.isNotEmpty ||
        state.selectedPlatformFilter != null ||
        state.selectedTags.isNotEmpty ||
        state.statusFilter != null;
    return hasFilter ? '当前过滤条件没有物品' : '还没有添加物品';
  }
}
