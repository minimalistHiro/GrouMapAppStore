/// メニューオプショングループのデフォルトテンプレート定義
///
/// 店舗がオプション管理画面で「追加」すると、Firestoreにコピーされる。
/// コピー後は店舗側で名前・選択肢・料金を自由に編集可能。
class DefaultMenuOptionGroups {
  DefaultMenuOptionGroups._();

  static const List<Map<String, dynamic>> templates = [
    {
      'templateId': 'size',
      'name': 'サイズ',
      'options': [
        {'name': '普通', 'priceModifier': 0},
        {'name': '大盛り', 'priceModifier': 100},
      ],
    },
  ];
}
