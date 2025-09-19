import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';

class StorePaymentView extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  
  const StorePaymentView({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  ConsumerState<StorePaymentView> createState() => _StorePaymentViewState();
}

class _StorePaymentViewState extends ConsumerState<StorePaymentView> {
  String _amount = '0';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    print('StorePaymentView: 初期化完了 - userId: ${widget.userId}, userName: ${widget.userName}');
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_amount == '0') {
        _amount = number;
      } else {
        _amount += number;
      }
    });
  }

  void _onClearPressed() {
    setState(() {
      _amount = '0';
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _onPayPressed() {
    final amount = int.tryParse(_amount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('有効な金額を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showPaymentConfirmation(amount);
  }

  void _showPaymentConfirmation(int amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支払い確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 64, color: Color(0xFFFF6B35)),
            const SizedBox(height: 16),
            Text('${widget.userName}さん'),
            const SizedBox(height: 8),
            Text('${amount.toString()}円を支払いますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Text(
                '支払い後、お客様にポイントを付与します',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processPayment(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('支払い処理'),
          ),
        ],
      ),
    );
  }

  void _processPayment(int amount) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 現在の店舗ユーザーを取得
      final authState = ref.read(authStateProvider);
      final storeUser = authState.value;
      if (storeUser == null) {
        throw Exception('店舗の認証情報が取得できませんでした');
      }

      // 支払い処理を実行
      final paymentNotifier = ref.read(paymentProvider.notifier);
      final result = await paymentNotifier.processPayment(
        userId: widget.userId,
        storeId: storeUser.uid,
        amount: amount,
        paymentMethod: 'cash',
        description: '現金支払い',
      );

      if (result.isSuccess) {
        // 成功時の処理
        if (mounted) {
          _showSuccessDialog(amount, result);
        }
      } else {
        // エラー時の処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? '支払い処理に失敗しました'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('支払い処理エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('支払い処理に失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  void _showSuccessDialog(int amount, PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支払い完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text('${widget.userName}さん'),
            const SizedBox(height: 8),
            Text(
              '${amount.toString()}円の支払いが完了しました！',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '付与ポイント: ${result.pointsAwarded}pt',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'お客様のポイントが正常に更新されました\n取引ID: ${result.transactionId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // ホーム画面に戻る
              Navigator.of(context).pop();
            },
            child: const Text('完了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 再度スキャン
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: const Text('もう一度スキャン'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('支払い金額入力'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // お客様情報セクション
          _buildCustomerInfo(),
          
          // 金額表示セクション
          _buildAmountDisplay(),
          
          // 電卓セクション
          Expanded(
            child: _buildCalculator(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // お客様アイコン
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                widget.userName.isNotEmpty 
                    ? widget.userName.substring(0, 1).toUpperCase()
                    : '客',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // お客様情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName.isNotEmpty ? widget.userName : 'お客様',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ユーザーID: ${widget.userId}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '支払い待ち',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          const Text(
            '支払い金額',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_amount}円',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '付与予定ポイント: ${(int.tryParse(_amount) ?? 0) ~/ 100}pt',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 数字ボタン行1
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('1'),
                _buildNumberButton('2'),
                _buildNumberButton('3'),
              ],
            ),
          ),
          // 数字ボタン行2
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('4'),
                _buildNumberButton('5'),
                _buildNumberButton('6'),
              ],
            ),
          ),
          // 数字ボタン行3
          Expanded(
            child: Row(
              children: [
                _buildNumberButton('7'),
                _buildNumberButton('8'),
                _buildNumberButton('9'),
              ],
            ),
          ),
          // 数字ボタン行4
          Expanded(
            child: Row(
              children: [
                _buildActionButton('C', _onClearPressed, Colors.red),
                _buildNumberButton('0'),
                _buildActionButton('⌫', _onBackspacePressed, Colors.orange),
              ],
            ),
          ),
          // 支払いボタン
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _onPayPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '支払い処理',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => _onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
