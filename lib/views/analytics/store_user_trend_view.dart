import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import 'trend_base_view.dart';

class StoreUserTrendView extends ConsumerStatefulWidget {
  final String? storeId;
  const StoreUserTrendView({super.key, this.storeId});

  @override
  ConsumerState<StoreUserTrendView> createState() => _StoreUserTrendViewState();
}

class _StoreUserTrendViewState extends ConsumerState<StoreUserTrendView> {
  String? _selectedGender;
  String? _selectedAgeGroup;
  bool _isFilterExpanded = false;

  bool get _hasActiveFilter => _selectedGender != null || _selectedAgeGroup != null;

  int get _activeFilterCount =>
      (_selectedGender != null ? 1 : 0) + (_selectedAgeGroup != null ? 1 : 0);

  void _onFilterChanged() {
    ref.read(storeUserTrendNotifierProvider.notifier).refetchWithFilters(
      genderFilter: _selectedGender,
      ageGroupFilter: _selectedAgeGroup,
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedGender = null;
      _selectedAgeGroup = null;
    });
    _onFilterChanged();
  }

  @override
  Widget build(BuildContext context) {
    return TrendBaseView(
      overrideStoreId: widget.storeId,
      title: '店舗利用者推移',
      chartTitle: '利用者推移グラフ',
      emptyDetail: '利用者データがありません',
      valueKey: 'userCount',
      trendProvider: storeUserTrendNotifierProvider,
      onFetch: (ref, storeId, period) {
        return ref.read(storeUserTrendNotifierProvider.notifier).fetchTrendData(
          storeId,
          period,
          genderFilter: _selectedGender,
          ageGroupFilter: _selectedAgeGroup,
        );
      },
      onFetchWithDate: (ref, storeId, period, anchorDate) {
        return ref.read(storeUserTrendNotifierProvider.notifier).fetchTrendData(
          storeId,
          period,
          anchorDate: anchorDate,
          genderFilter: _selectedGender,
          ageGroupFilter: _selectedAgeGroup,
        );
      },
      minAvailableDateResolver: (ref) =>
          ref.read(storeUserTrendNotifierProvider.notifier).minAvailableDate,
      periodOptions: const [
        TrendPeriodOption('日', 'day'),
        TrendPeriodOption('月', 'month'),
        TrendPeriodOption('年', 'year'),
      ],
      initialPeriod: 'day',
      statsConfig: const TrendStatsConfig(
        totalLabel: '総利用者数',
        maxLabel: '最大利用者数',
        minLabel: '最小利用者数',
        avgLabel: '平均利用者数',
        totalIcon: Icons.people,
        maxIcon: Icons.trending_up,
        minIcon: Icons.trending_down,
        avgIcon: Icons.analytics,
        totalColor: Color(0xFFFF6B35),
        maxColor: Color(0xFFFF6B35),
        minColor: Color(0xFFFF6B35),
        avgColor: Color(0xFFFF6B35),
      ),
      filterWidget: _buildFilterSection(),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // フィルターヘッダー（タップで展開/折りたたみ）
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: _hasActiveFilter
                        ? const Color(0xFFFF6B35)
                        : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'フィルター',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _hasActiveFilter
                          ? const Color(0xFFFF6B35)
                          : Colors.grey[800],
                    ),
                  ),
                  if (_hasActiveFilter) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _isFilterExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // フィルター内容（展開時のみ表示）
          if (_isFilterExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGenderFilter(),
                  const SizedBox(height: 16),
                  _buildAgeGroupFilter(),
                  if (_hasActiveFilter) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('フィルターをリセット'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    const genderOptions = [
      _FilterOption('全て', null),
      _FilterOption('男性', '男性'),
      _FilterOption('女性', '女性'),
      _FilterOption('その他', 'その他'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性別',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genderOptions.map((option) {
            final isSelected = _selectedGender == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedGender = selected ? option.value : null;
                });
                _onFilterChanged();
              },
              selectedColor: const Color(0xFFFF6B35).withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeGroupFilter() {
    const ageOptions = [
      _FilterOption('全て', null),
      _FilterOption('~19歳', '~19'),
      _FilterOption('20代', '20s'),
      _FilterOption('30代', '30s'),
      _FilterOption('40代', '40s'),
      _FilterOption('50代', '50s'),
      _FilterOption('60歳~', '60+'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '年代',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ageOptions.map((option) {
            final isSelected = _selectedAgeGroup == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedAgeGroup = selected ? option.value : null;
                });
                _onFilterChanged();
              },
              selectedColor: const Color(0xFFFF6B35).withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.grey[300]!,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FilterOption {
  const _FilterOption(this.label, this.value);
  final String label;
  final String? value;
}
