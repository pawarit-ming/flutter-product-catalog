/// Thai wording for the fixed vocabulary the API returns in English:
/// category names and the shipping, warranty and return phrases. Product
/// content (titles, descriptions, brands, reviews) stays as the API sends it.
///
/// Anything not recognised is returned unchanged, so a new phrase from the
/// API shows in English rather than disappearing.
library;

const _categories = {
  'beauty': 'ความงาม',
  'fragrances': 'น้ำหอม',
  'furniture': 'เฟอร์นิเจอร์',
  'groceries': 'ของชำ',
  'home-decoration': 'ของแต่งบ้าน',
  'kitchen-accessories': 'อุปกรณ์ครัว',
  'laptops': 'แล็ปท็อป',
  'mens-shirts': 'เสื้อเชิ้ตผู้ชาย',
  'mens-shoes': 'รองเท้าผู้ชาย',
  'mens-watches': 'นาฬิกาผู้ชาย',
  'mobile-accessories': 'อุปกรณ์เสริมมือถือ',
  'motorcycle': 'มอเตอร์ไซค์',
  'skin-care': 'ดูแลผิว',
  'smartphones': 'สมาร์ตโฟน',
  'sports-accessories': 'อุปกรณ์กีฬา',
  'sunglasses': 'แว่นกันแดด',
  'tablets': 'แท็บเล็ต',
  'tops': 'เสื้อผู้หญิง',
  'vehicle': 'ยานพาหนะ',
  'womens-bags': 'กระเป๋าผู้หญิง',
  'womens-dresses': 'ชุดเดรส',
  'womens-jewellery': 'เครื่องประดับผู้หญิง',
  'womens-shoes': 'รองเท้าผู้หญิง',
  'womens-watches': 'นาฬิกาผู้หญิง',
};

/// Thai name for a category [slug], or [fallback] when it is not known.
String thaiCategoryName(String slug, {required String fallback}) =>
    _categories[slug] ?? fallback;

const _units = {
  'day': 'วัน',
  'business day': 'วันทำการ',
  'week': 'สัปดาห์',
  'month': 'เดือน',
  'year': 'ปี',
};

/// "3 weeks" style amounts: a number (or range) and a unit in [_units].
final _amount = RegExp(
  r'^(\d+(?:\s*-\s*\d+)?)\s+(business day|day|week|month|year)s?$',
  caseSensitive: false,
);

/// "3-5 business days" -> "3–5 วันทำการ"; null when not an amount.
String? _thaiAmount(String text) {
  final match = _amount.firstMatch(text.trim());
  if (match == null) return null;
  final number = match.group(1)!.replaceAll(RegExp(r'\s*-\s*'), '–');
  return '$number ${_units[match.group(2)!.toLowerCase()]}';
}

/// "Ships in 3-5 business days" -> "จัดส่งภายใน 3–5 วันทำการ".
String thaiShipping(String text) {
  final lower = text.trim().toLowerCase();
  if (lower == 'ships overnight') return 'จัดส่งด่วนภายใน 1 วัน';
  if (lower.startsWith('ships in ')) {
    final amount = _thaiAmount(text.trim().substring('ships in '.length));
    if (amount != null) return 'จัดส่งภายใน $amount';
  }
  return text;
}

/// "1 year warranty" -> "รับประกัน 1 ปี".
String thaiWarranty(String text) {
  final lower = text.trim().toLowerCase();
  if (lower == 'no warranty') return 'ไม่มีการรับประกัน';
  if (lower == 'lifetime warranty') return 'รับประกันตลอดอายุการใช้งาน';
  if (lower.endsWith(' warranty')) {
    final amount = _thaiAmount(
      text.trim().substring(0, text.trim().length - ' warranty'.length),
    );
    if (amount != null) return 'รับประกัน $amount';
  }
  return text;
}

/// "30 days return policy" -> "คืนสินค้าได้ภายใน 30 วัน".
String thaiReturnPolicy(String text) {
  final lower = text.trim().toLowerCase();
  if (lower == 'no return policy') return 'ไม่รับคืนสินค้า';
  if (lower.endsWith(' return policy')) {
    final amount = _thaiAmount(
      text.trim().substring(0, text.trim().length - ' return policy'.length),
    );
    if (amount != null) return 'คืนสินค้าได้ภายใน $amount';
  }
  return text;
}
