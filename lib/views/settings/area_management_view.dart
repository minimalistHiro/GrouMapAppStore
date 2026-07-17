import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/area_model.dart';
import '../../providers/area_admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'area_edit_view.dart';

class AreaManagementView extends ConsumerWidget {
  const AreaManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasAdminProvider);
    final isOwnerAsync = ref.watch(userIsOwnerProvider);
    final isOwner = isOwnerAsync.maybeWhen(data: (v) => v, orElse: () => false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('エリア管理'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'エリアを追加',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AreaEditView(),
                  ),
                );
              },
            ),
        ],
      ),
      body: areasAsync.when(
        data: (areas) {
          if (areas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'エリアがまだありません',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('エリアを追加'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AreaEditView(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: areas.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final area = areas[index];
              return _AreaListTile(
                area: area,
                isOwner: isOwner,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AreaEditView(area: area),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
      ),
    );
  }
}

class _AreaListTile extends StatelessWidget {
  const _AreaListTile({
    required this.area,
    required this.isOwner,
    required this.onTap,
  });

  final AreaModel area;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: area.displayColor.withOpacity(0.2),
        child: Icon(
          Icons.location_on,
          color: area.displayColor,
        ),
      ),
      title: Text(
        area.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('半径 ${area.radiusMeters.toInt()}m'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActiveChip(isActive: area.isActive),
          if (isOwner) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ],
      ),
      onTap: isOwner ? onTap : null,
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green[300]! : Colors.grey[400]!,
        ),
      ),
      child: Text(
        isActive ? '表示中' : '非表示',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green[700] : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
