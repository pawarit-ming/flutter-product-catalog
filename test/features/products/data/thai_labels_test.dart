import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/features/products/data/product_category.dart';
import 'package:product_catalog/features/products/data/thai_labels.dart';

void main() {
  group('category names', () {
    test('known slugs get a Thai name', () {
      expect(thaiCategoryName('beauty', fallback: 'Beauty'), 'ความงาม');
      expect(
        const ProductCategory(slug: 'skin-care', name: 'Skin Care').label,
        'ดูแลผิว',
      );
    });

    test('unknown slugs keep the fallback', () {
      expect(thaiCategoryName('robots', fallback: 'Robots'), 'Robots');
    });
  });

  group('shipping', () {
    test('ranges, single amounts and overnight', () {
      expect(
        thaiShipping('Ships in 3-5 business days'),
        'จัดส่งภายใน 3–5 วันทำการ',
      );
      expect(thaiShipping('Ships in 1 week'), 'จัดส่งภายใน 1 สัปดาห์');
      expect(thaiShipping('Ships in 2 weeks'), 'จัดส่งภายใน 2 สัปดาห์');
      expect(thaiShipping('Ships in 1 month'), 'จัดส่งภายใน 1 เดือน');
      expect(thaiShipping('Ships overnight'), 'จัดส่งด่วนภายใน 1 วัน');
    });

    test('unrecognised text is unchanged', () {
      expect(thaiShipping('Ships by drone'), 'Ships by drone');
    });
  });

  group('warranty', () {
    test('amounts and special cases', () {
      expect(thaiWarranty('1 year warranty'), 'รับประกัน 1 ปี');
      expect(thaiWarranty('6 months warranty'), 'รับประกัน 6 เดือน');
      expect(thaiWarranty('1 week warranty'), 'รับประกัน 1 สัปดาห์');
      expect(thaiWarranty('No warranty'), 'ไม่มีการรับประกัน');
      expect(thaiWarranty('Lifetime warranty'), 'รับประกันตลอดอายุการใช้งาน');
    });

    test('unrecognised text is unchanged', () {
      expect(thaiWarranty('Ask the seller'), 'Ask the seller');
    });
  });

  group('return policy', () {
    test('amounts and no returns', () {
      expect(
        thaiReturnPolicy('30 days return policy'),
        'คืนสินค้าได้ภายใน 30 วัน',
      );
      expect(thaiReturnPolicy('No return policy'), 'ไม่รับคืนสินค้า');
    });

    test('unrecognised text is unchanged', () {
      expect(thaiReturnPolicy('Store credit only'), 'Store credit only');
    });
  });
}
