import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/device.dart';
import '../../data/models/category.dart';
import '../../data/models/purchase_platform.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/platform_repository.dart';
import '../../core/network/api_client.dart';
import '../../core/network/error_messages.dart';

class HomeSummaryStats {
  final double totalValue;
  final double dailyCost;
  final int itemCount;
  final int scrapOrExpiredCount;
  final int expiringSoonCount;

  const HomeSummaryStats({
    required this.totalValue,
    required this.dailyCost,
    required this.itemCount,
    required this.scrapOrExpiredCount,
    required this.expiringSoonCount,
  });

  factory HomeSummaryStats.fromJson(Map<String, dynamic> json) {
    return HomeSummaryStats(
      totalValue: _asDouble(json['totalOriginalPrice'] ?? json['totalValue']),
      dailyCost: _asDouble(json['dailyAverage'] ?? json['dailyCost']),
      itemCount: _asInt(json['itemCount'] ?? json['totalCount']),
      scrapOrExpiredCount: _asInt(
        json['scrapOrExpiredCount'] ?? json['retiredOrExpiredCount'],
      ),
      expiringSoonCount: _asInt(json['expiringSoonCount']),
    );
  }

  static double _asDouble(Object? value) => value is num ? value.toDouble() : 0;

  static int _asInt(Object? value) => value is num ? value.toInt() : 0;
}

final homeSummaryProvider = FutureProvider.autoDispose<HomeSummaryStats>((
  ref,
) async {
  final data = await ref
      .watch(apiClientProvider)
      .get<Map<String, dynamic>>('/statistics/summary');
  return HomeSummaryStats.fromJson(data);
});

class HomeDevicesState {
  final List<Device> devices;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String search;
  final Set<String> selectedCategories;
  final String? selectedPlatformFilter;
  final Set<String> selectedTags;
  final String? statusFilter;
  final String sortField;
  final bool isAscending;
  final String? error;

  HomeDevicesState({
    required this.devices,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    required this.search,
    required this.selectedCategories,
    this.selectedPlatformFilter,
    required this.selectedTags,
    this.statusFilter,
    required this.sortField,
    required this.isAscending,
    this.error,
  });

  HomeDevicesState.initial()
    : devices = const [],
      isLoading = true,
      isLoadingMore = false,
      hasMore = true,
      page = 1,
      search = '',
      selectedCategories = const {},
      selectedPlatformFilter = null,
      selectedTags = const {},
      statusFilter = null,
      sortField = 'default',
      isAscending = false,
      error = null;

  HomeDevicesState copyWith({
    List<Device>? devices,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? search,
    Set<String>? selectedCategories,
    String? selectedPlatformFilter,
    bool nullPlatform = false,
    Set<String>? selectedTags,
    String? statusFilter,
    bool nullStatusFilter = false,
    String? sortField,
    bool? isAscending,
    String? error,
    bool clearError = false,
  }) {
    return HomeDevicesState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedPlatformFilter: nullPlatform
          ? null
          : (selectedPlatformFilter ?? this.selectedPlatformFilter),
      selectedTags: selectedTags ?? this.selectedTags,
      statusFilter: nullStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      sortField: sortField ?? this.sortField,
      isAscending: isAscending ?? this.isAscending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HomeDevicesNotifier extends StateNotifier<HomeDevicesState> {
  final Ref _ref;
  final DeviceRepository _deviceRepository;

  HomeDevicesNotifier(this._ref, this._deviceRepository)
    : super(HomeDevicesState.initial()) {
    _loadFirstPage();
  }

  static const int _limit = 10;

  Future<void> _loadFirstPage() async {
    state = state.copyWith(
      isLoading: true,
      page: 1,
      hasMore: true,
      error: null,
      clearError: true,
    );
    try {
      final fetched = await _fetchDevices(page: 1);
      state = state.copyWith(
        devices: fetched,
        isLoading: false,
        hasMore: fetched.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: userErrorMessage(e));
    }
  }

  Future<List<Device>> _fetchDevices({
    required int page,
    int? customLimit,
  }) async {
    // 1. Map category names to UUIDs
    final categoryTree = _ref.read(categoryTreeProvider).valueOrNull ?? [];
    final selectedCategoryUuids = <String>[];
    for (final name in state.selectedCategories) {
      final category = categoryTree.firstWhere(
        (c) => c.name == name,
        orElse: () => Category()
          ..name = ''
          ..iconPath = '',
      );
      if (category.uuid != null) {
        selectedCategoryUuids.add(category.uuid!);
      }
    }
    final categoryIdParam = selectedCategoryUuids.isNotEmpty
        ? selectedCategoryUuids.join(',')
        : null;

    // 2. Map platform name to UUID
    final platforms = _ref.read(platformsProvider).valueOrNull ?? [];
    String? platformIdParam;
    if (state.selectedPlatformFilter != null) {
      final platform = platforms.firstWhere(
        (p) => p.name == state.selectedPlatformFilter,
        orElse: () => const PurchasePlatform(
          id: 0,
          uuid: '',
          name: '',
          iconPath: '',
          colorHex: '',
          isDefault: false,
        ),
      );
      if (platform.uuid.isNotEmpty) {
        platformIdParam = platform.uuid;
      }
    }

    // 3. Map tags
    final tagsParam = state.selectedTags.isNotEmpty
        ? state.selectedTags.join(',')
        : null;

    // 4. Map sorting parameters
    final hasManualSort = state.sortField != 'default';
    final sortBy = hasManualSort ? state.sortField : null;
    final sortOrder = hasManualSort
        ? (state.isAscending ? 'asc' : 'desc')
        : null;

    return await _deviceRepository.getPaginatedDevices(
      page: page,
      limit: customLimit ?? _limit,
      search: state.search,
      categoryId: categoryIdParam,
      platformId: platformIdParam,
      tag: tagsParam,
      status: state.statusFilter,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    try {
      final fetched = await _fetchDevices(page: nextPage);
      state = state.copyWith(
        devices: [...state.devices, ...fetched],
        isLoadingMore: false,
        page: nextPage,
        hasMore: fetched.length >= _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: userErrorMessage(e));
    }
  }

  Future<void> refresh() async {
    _ref.invalidate(homeSummaryProvider);
    await _loadFirstPage();
  }

  /// Re-fetch current pages from API without toggling loading state (no flicker)
  Future<void> silentRefresh() async {
    _ref.invalidate(homeSummaryProvider);
    try {
      final currentPages = state.page;
      final totalLimit = _limit * currentPages;
      debugPrint(
        '[Provider] silentRefresh: fetching page 1 with limit $totalLimit',
      );
      final fetched = await _fetchDevices(page: 1, customLimit: totalLimit);
      debugPrint('[Provider] silentRefresh: got ${fetched.length} devices');
      state = state.copyWith(
        devices: fetched,
        hasMore: fetched.length >= totalLimit,
        clearError: true,
      );
      debugPrint('[Provider] silentRefresh: state updated');
    } catch (e) {
      debugPrint('[Provider] silentRefresh FAILED: $e');
    }
  }

  void removeDeviceLocally(int id) {
    state = state.copyWith(
      devices: state.devices.where((d) => d.id != id).toList(),
    );
  }

  void checkAndLoadMore() {
    if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
      loadNextPage();
    }
  }

  void updateSearch(String query) {
    if (state.search == query) return;
    state = state.copyWith(search: query);
    _loadFirstPage();
  }

  void updateCategories(Set<String> categories) {
    state = state.copyWith(selectedCategories: categories);
    _loadFirstPage();
  }

  void updatePlatformFilter(String? platformName) {
    if (state.selectedPlatformFilter == platformName) return;
    if (platformName == null) {
      state = state.copyWith(nullPlatform: true);
    } else {
      state = state.copyWith(selectedPlatformFilter: platformName);
    }
    _loadFirstPage();
  }

  void toggleTag(String tag) {
    final updated = Set<String>.from(state.selectedTags);
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    state = state.copyWith(selectedTags: updated);
    _loadFirstPage();
  }

  void updateStatusFilter(String? value) {
    if (state.statusFilter == value) return;
    state = value == null
        ? state.copyWith(nullStatusFilter: true)
        : state.copyWith(statusFilter: value);
    _loadFirstPage();
  }

  void updateSortField(String sortField) {
    if (state.sortField == sortField) return;
    state = state.copyWith(sortField: sortField);
    _loadFirstPage();
  }

  void updateSortOrder(bool isAscending) {
    if (state.isAscending == isAscending) return;
    state = state.copyWith(isAscending: isAscending);
    _loadFirstPage();
  }
}

final homeDevicesNotifierProvider =
    StateNotifierProvider<HomeDevicesNotifier, HomeDevicesState>((ref) {
      final repository = ref.watch(deviceRepositoryProvider);
      return HomeDevicesNotifier(ref, repository);
    });
