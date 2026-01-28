import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ranking_provider.dart';
import '../../models/ranking_model.dart';
import '../../widgets/custom_button.dart';

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  RankingType _selectedType = RankingType.totalPoints;
  RankingPeriodType _selectedPeriod = RankingPeriodType.allTime;

  @override
  Widget build(BuildContext context) {
    final query = RankingQuery(
      type: _selectedType,
      period: _selectedPeriod,
      limit: 50,
    );

    final rankingData = ref.watch(rankingDataProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          const Divider(height: 1),
          Expanded(
            child: rankingData.when(
              data: (rankings) => _buildRankingList(rankings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'データの取得に失敗しました',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ネットワーク接続を確認してください',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: '再試行',
                      onPressed: () {
                        ref.read(rankingNotifierProvider.notifier).refresh(query);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ランキングタイプ選択
          Row(
            children: [
              const Text('ランキング:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RankingType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getRankingTypeLabel(type)),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 期間選択
          Row(
            children: [
              const Text('期間:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RankingPeriodType.values.map((period) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getPeriodTypeLabel(period)),
                          selected: _selectedPeriod == period,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<RankingModel> rankings) {
    if (rankings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('ランキングデータがありません'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        return _buildRankingItem(ranking, index);
      },
    );
  }

  Widget _buildRankingItem(RankingModel ranking, int index) {
    final isTopThree = index < 3;
    final rankColor = _getRankColor(index + 1);
    final rankIcon = _getRankIcon(index + 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTopThree ? 4 : 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: rankColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: rankIcon != null
                ? Icon(rankIcon, color: Colors.white, size: 24)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: ranking.photoURL != null && ranking.photoURL!.isNotEmpty
                  ? NetworkImage(ranking.photoURL!)
                  : null,
              child: ranking.photoURL == null || ranking.photoURL!.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ranking.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getRankingDisplayValue(ranking),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetails(ranking),
      ),
    );
  }

  void _showUserDetails(RankingModel ranking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ranking.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ranking.photoURL != null && ranking.photoURL!.isNotEmpty)
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(ranking.photoURL!),
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 40,
                  child: const Icon(Icons.person, size: 40),
                ),
              ),
            const SizedBox(height: 16),
            _buildDetailRow('順位:', '${ranking.rank}位'),
            _buildDetailRow(_getRankingTypeLabel(_selectedType) + ':', _getRankingDisplayValue(ranking)),
            _buildDetailRow('最終更新:', _formatDate(ranking.lastUpdated)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.blue;
    }
  }

  IconData? _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.workspace_premium;
      default:
        return null;
    }
  }

  String _getRankingTypeLabel(RankingType type) {
    switch (type) {
      case RankingType.totalPoints:
        return 'ポイント';
      case RankingType.badgeCount:
        return 'バッジ数';
      case RankingType.level:
        return 'レベル';
      case RankingType.stampCount:
        return 'スタンプ数';
      case RankingType.totalPayment:
        return '総支払額';
    }
  }

  String _getPeriodTypeLabel(RankingPeriodType period) {
    switch (period) {
      case RankingPeriodType.daily:
        return '日間';
      case RankingPeriodType.weekly:
        return '週間';
      case RankingPeriodType.monthly:
        return '月間';
      case RankingPeriodType.allTime:
        return '全期間';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _getRankingDisplayValue(RankingModel ranking) {
    switch (_selectedType) {
      case RankingType.totalPoints:
        return '${ranking.totalPoints} pt';
      case RankingType.badgeCount:
        return '${ranking.badgeCount} バッジ';
      case RankingType.level:
        return 'レベル ${ranking.currentLevel}';
      case RankingType.stampCount:
        return '${ranking.stampCount} スタンプ';
      case RankingType.totalPayment:
        return '¥${ranking.totalPayment.toStringAsFixed(0)}';
    }
  }
}
