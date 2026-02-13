import 'package:flutter/material.dart';

class PaymentMethodCategory {
  final String key;
  final String displayName;
  final IconData icon;
  final List<PaymentMethodItem> items;

  const PaymentMethodCategory({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.items,
  });
}

class PaymentMethodItem {
  final String key;
  final String displayName;

  const PaymentMethodItem({
    required this.key,
    required this.displayName,
  });
}

const List<PaymentMethodCategory> paymentMethodCategories = [
  PaymentMethodCategory(
    key: 'cash',
    displayName: '現金',
    icon: Icons.payments_outlined,
    items: [
      PaymentMethodItem(key: 'cash', displayName: '現金'),
    ],
  ),
  PaymentMethodCategory(
    key: 'card',
    displayName: 'クレジット/デビット/プリペイド',
    icon: Icons.credit_card,
    items: [
      PaymentMethodItem(key: 'visa', displayName: 'Visa'),
      PaymentMethodItem(key: 'mastercard', displayName: 'Mastercard'),
      PaymentMethodItem(key: 'jcb', displayName: 'JCB'),
      PaymentMethodItem(key: 'amex', displayName: 'American Express'),
      PaymentMethodItem(key: 'diners', displayName: 'Diners Club'),
      PaymentMethodItem(key: 'discover', displayName: 'Discover'),
      PaymentMethodItem(key: 'unionpay_card', displayName: 'UnionPay（銀聯）カード'),
      PaymentMethodItem(key: 'debit', displayName: 'デビットカード'),
      PaymentMethodItem(key: 'prepaid', displayName: 'プリペイドカード'),
      PaymentMethodItem(key: 'contactless', displayName: 'タッチ決済（NFC）'),
      PaymentMethodItem(key: 'apple_pay_touch', displayName: 'Apple Pay（タッチ決済）'),
      PaymentMethodItem(key: 'google_pay_touch', displayName: 'Google Pay（タッチ決済）'),
    ],
  ),
  PaymentMethodCategory(
    key: 'emoney',
    displayName: '電子マネー',
    icon: Icons.contactless,
    items: [
      PaymentMethodItem(key: 'transit_ic', displayName: '交通系IC（Suica/PASMO等）'),
      PaymentMethodItem(key: 'id', displayName: 'iD'),
      PaymentMethodItem(key: 'quicpay', displayName: 'QUICPay'),
      PaymentMethodItem(key: 'rakuten_edy', displayName: '楽天Edy'),
      PaymentMethodItem(key: 'nanaco', displayName: 'nanaco'),
      PaymentMethodItem(key: 'waon', displayName: 'WAON'),
    ],
  ),
  PaymentMethodCategory(
    key: 'qr',
    displayName: 'QR/バーコード決済',
    icon: Icons.qr_code,
    items: [
      PaymentMethodItem(key: 'paypay', displayName: 'PayPay'),
      PaymentMethodItem(key: 'd_barai', displayName: 'd払い'),
      PaymentMethodItem(key: 'rakuten_pay', displayName: '楽天ペイ'),
      PaymentMethodItem(key: 'au_pay', displayName: 'au PAY'),
      PaymentMethodItem(key: 'merpay', displayName: 'メルペイ'),
      PaymentMethodItem(key: 'wechat_pay', displayName: 'WeChat Pay'),
      PaymentMethodItem(key: 'alipay_plus', displayName: 'Alipay+'),
      PaymentMethodItem(key: 'unionpay_qr', displayName: 'UnionPay（銀聯）QR'),
      PaymentMethodItem(key: 'coin_plus', displayName: 'COIN+'),
      PaymentMethodItem(key: 'j_coin_pay', displayName: 'J-Coin Pay'),
      PaymentMethodItem(key: 'smart_code', displayName: 'Smart Code'),
      PaymentMethodItem(key: 'bank_pay', displayName: 'Bank Pay/銀行Pay'),
      PaymentMethodItem(key: 'yucho_pay', displayName: 'ゆうちょPay'),
    ],
  ),
];
