import 'package:flutter/material.dart';

import 'product_api.dart';
import 'product_models.dart';

class ProductScreen extends StatefulWidget {
  final Future<List<Product>> Function()? loadProducts;
  const ProductScreen({super.key, this.loadProducts});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  Future<List<Product>> _load() =>
      (widget.loadProducts ?? ProductApi.fetchProducts)();

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _products = future;
    });
    try {
      await future;
    } catch (_) {
      /* FutureBuilder displays the error. */
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Product detail'),
      leading: Navigator.canPop(context)
          ? IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left),
            )
          : null,
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Product>>(
      future: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể tải sản phẩm. Vui lòng kiểm tra kết nối mạng.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        final products = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: products.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text('Không có sản phẩm nào.'),
                      ),
                    ),
                  ]
                : products
                      .map(
                        (product) => Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: _ProductDetails(product: product),
                          ),
                        ),
                      )
                      .toList(),
          ),
        );
      },
    ),
  );
}

class _ProductDetails extends StatelessWidget {
  final Product product;
  const _ProductDetails({required this.product});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: ColoredBox(
              color: const Color(0xFFF3F3F3),
              child: product.image.isEmpty
                  ? const _ImageUnavailable()
                  : Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) =>
                          const _ImageUnavailable(),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          product.name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Giá: ${product.formattedPrice}',
          style: const TextStyle(
            color: Color(0xFFD00000),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            product.description.isEmpty
                ? 'Chưa có mô tả.'
                : product.description,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _ImageUnavailable extends StatelessWidget {
  const _ImageUnavailable();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text('Không tải được ảnh'),
      ],
    ),
  );
}
