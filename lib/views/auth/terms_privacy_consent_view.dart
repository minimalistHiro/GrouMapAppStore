import 'package:flutter/material.dart';
import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';
import '../settings/privacy_policy_view.dart';
import '../settings/terms_of_service_view.dart';
import 'store_info_view.dart';

class TermsPrivacyConsentView extends StatefulWidget {
  const TermsPrivacyConsentView({super.key});

  @override
  State<TermsPrivacyConsentView> createState() =>
      _TermsPrivacyConsentViewState();
}

class _TermsPrivacyConsentViewState extends State<TermsPrivacyConsentView> {
  bool _isTermsAgreed = false;
  bool _isPrivacyAgreed = false;

  bool get _canProceed => _isTermsAgreed && _isPrivacyAgreed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F2),
      appBar: const CommonHeader(title: '利用規約・プライバシーポリシー'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildIntroBlock(),
                      const SizedBox(height: 12),
                      _LegalLinkCard(
                        title: '利用規約',
                        isAgreed: _isTermsAgreed,
                        onTap: _openTerms,
                      ),
                      const SizedBox(height: 10),
                      _LegalLinkCard(
                        title: 'プライバシーポリシー',
                        isAgreed: _isPrivacyAgreed,
                        onTap: _openPrivacyPolicy,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '各文書を最下部までスクロールし、「同意する」を押すと同意済みに切り替わります',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF616161),
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: CustomButton(
            text: '同意して次へ',
            onPressed: _canProceed ? _goToStoreInfo : null,
            height: 52,
            backgroundColor: const Color(0xFFFF6B35),
            textColor: Colors.white,
            borderRadius: 999,
          ),
        ),
      ),
    );
  }

  Widget _buildIntroBlock() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'アカウント作成前に2つの文書をご確認ください',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '各カードの「確認する」ボタンから最新の内容を確認できます。',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTerms() async {
    final agreed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceView(showConsentButton: true),
      ),
    );
    if (!mounted || agreed != true) return;
    setState(() {
      _isTermsAgreed = true;
    });
  }

  Future<void> _openPrivacyPolicy() async {
    final agreed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyView(showConsentButton: true),
      ),
    );
    if (!mounted || agreed != true) return;
    setState(() {
      _isPrivacyAgreed = true;
    });
  }

  void _goToStoreInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoreInfoView(),
      ),
    );
  }
}

class _LegalLinkCard extends StatelessWidget {
  const _LegalLinkCard({
    required this.title,
    required this.isAgreed,
    required this.onTap,
  });

  final String title;
  final bool isAgreed;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2E2E),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 260,
            child: CustomButton(
              text: '確認する（必須）',
              onPressed: isAgreed
                  ? null
                  : () {
                      onTap();
                    },
              height: 56,
              backgroundColor:
                  isAgreed ? const Color(0xFFE0E0E0) : const Color(0xFF2196F3),
              textColor:
                  isAgreed ? const Color(0xFF9E9E9E) : Colors.white,
              borderColor:
                  isAgreed ? const Color(0xFFD0D0D0) : const Color(0xFF2196F3),
              borderRadius: 999,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _AgreementStatus(isAgreed: isAgreed),
        ],
      ),
    );
  }
}

class _AgreementStatus extends StatelessWidget {
  const _AgreementStatus({required this.isAgreed});

  final bool isAgreed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isAgreed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 24,
          color: isAgreed ? const Color(0xFF17BFD7) : const Color(0xFFBDBDBD),
        ),
        const SizedBox(width: 8),
        Text(
          isAgreed ? '同意済み' : '未同意',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isAgreed ? const Color(0xFF303030) : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
