import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/point_request_provider.dart';
import '../../models/point_request_model.dart';
import '../main_navigation_view.dart';
import '../../widgets/custom_button.dart';

class PointRequestConfirmationView extends ConsumerStatefulWidget {
  final String requestId;
  
  const PointRequestConfirmationView({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  ConsumerState<PointRequestConfirmationView> createState() => _PointRequestConfirmationViewState();
}

class _PointRequestConfirmationViewState extends ConsumerState<PointRequestConfirmationView> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ポイント付与承認'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ref.watch(pointRequestStatusProvider(widget.requestId)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'リクエストが見つかりません',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
        data: (request) {
          if (request == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'リクエストが見つかりません',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('戻る'),
                  ),
                ],
              ),
            );
          }

          // 既に処理済みの場合
          if (request.status != PointRequestStatus.pending.value) {
            return _buildProcessedView(request);
          }

          return _buildConfirmationView(request);
        },
      ),
    );
  }

  Widget _buildConfirmationView(PointRequest request) {
    final totalPoints = request.totalPoints ?? request.pointsToAward;
    final normalPoints = request.normalPoints ?? totalPoints;
    final specialPoints = request.specialPoints ?? 0;
    final isRateReady = request.rateCalculatedAt != null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 店舗情報カード
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                const Icon(
                  Icons.store,
                  size: 48,
                  color: Color(0xFFFF6B35),
                ),
                const SizedBox(height: 12),
                Text(
                  request.storeName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'からポイント付与のリクエストが届きました',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // ポイント情報カード
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                const Icon(
                  Icons.stars,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                Text(
                  '${totalPoints}pt',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '付与予定ポイント',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                if (specialPoints > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '通常${normalPoints}pt / 特別${specialPoints}pt',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '支払い金額: ${request.amount}円',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '付与率: 100円 = 1pt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 説明テキスト
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Text(
              isRateReady
                  ? 'このポイント付与を承認しますか？\n承認するとお客様のアカウントにポイントが付与されます。'
                  : 'ポイント計算中のため、承認まで少しお待ちください。',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const Spacer(),
          
          // ボタン
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _rejectRequest(request.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '拒否',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: '受け入れる',
                  onPressed: _isProcessing || !isRateReady ? null : () => _acceptRequest(request),
                  isLoading: _isProcessing,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProcessedView(PointRequest request) {
    final isAccepted = request.status == PointRequestStatus.accepted.value;
    final icon = isAccepted ? Icons.check_circle : Icons.cancel;
    final color = isAccepted ? Colors.green : Colors.red;
    final title = isAccepted ? 'ポイント付与完了' : 'ポイント付与拒否';
    final totalPoints = request.totalPoints ?? request.pointsToAward;
    final normalPoints = request.normalPoints ?? totalPoints;
    final specialPoints = request.specialPoints ?? 0;
    final message = isAccepted 
        ? '${totalPoints}ptが付与されました！'
        : 'ポイント付与が拒否されました';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (isAccepted && specialPoints > 0) ...[
              const SizedBox(height: 8),
              Text(
                '通常${normalPoints}pt / 特別${specialPoints}pt',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (request.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  '理由: ${request.rejectionReason}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            CustomButton(
              text: '完了',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const MainNavigationView(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(PointRequest request) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final requestNotifier = ref.read(pointRequestProvider.notifier);
      final success = await requestNotifier.acceptPointRequestAsStore(request);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ポイント付与を承認しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('処理に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final requestNotifier = ref.read(pointRequestProvider.notifier);
      final success = await requestNotifier.rejectPointRequest(requestId, reason: 'ユーザーが拒否');
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ポイント付与を拒否しました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('処理に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
