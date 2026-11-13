import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/product_models.dart';
import 'package:flutter_application_1/product_screen.dart';

void main() {
  test('Parses the exact API fields, including a UUID and decimal price', () {
    final product = Product.fromJson({
      'id': '69b98b64-6c54-40e1-952c-1214e3e327ce',
      'name': 'API product',
      'price': 559.59,
      'des': 'API description',
      'imgURL': 'https://example.com/image.png',
    });
    expect(product.id, '69b98b64-6c54-40e1-952c-1214e3e327ce');
    expect(product.description, 'API description');
    expect(product.image, 'https://example.com/image.png');
    expect(product.formattedPrice, '559,59đ');
    expect(Product.fromJson({'price': 4000000}).formattedPrice, '4.000.000đ');
  });

  testWidgets('Displays fetched name, price and description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductScreen(
          loadProducts: () async => [
            const Product(
              id: '1',
              name: 'API product',
              price: 4000000,
              image: '',
              description: 'API description',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('API product'), findsOneWidget);
    expect(find.text('Giá: 4.000.000đ'), findsOneWidget);
    expect(find.text('API description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Allows retry after a failed request', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ProductScreen(
          loadProducts: () async {
            if (calls++ == 0) throw Exception('offline');
            return [];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Không có sản phẩm nào.'), findsOneWidget);
    expect(calls, 2);
  });
}
