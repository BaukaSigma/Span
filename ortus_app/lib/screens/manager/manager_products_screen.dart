import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import 'product_form_screen.dart';

class ManagerProductsScreen extends StatefulWidget {
  const ManagerProductsScreen({super.key});

  @override
  State<ManagerProductsScreen> createState() => _ManagerProductsScreenState();
}

class _ManagerProductsScreenState extends State<ManagerProductsScreen> {
  String _selectedCategory = '';
  late Future<List<ProductModel>> _productsFuture;
  late final List<Map<String, String>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = [
      const {'key': '', 'label': 'Все'},
      ...AppData.productCategories,
    ];
    _load();
  }

  void _load() {
    setState(() {
      _productsFuture = ProductService().getProducts(
        category: _selectedCategory.isEmpty ? null : _selectedCategory,
      );
    });
  }

  String _categoryLabel(String key) {
    final match = AppData.productCategories
        .firstWhere((element) => element['key'] == key, orElse: () => {});
    return match['label'] ?? 'Другое';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductFormScreen(),
                ),
              );
              if (created == true) _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 72,
                          color: AppColors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text('Товаров пока нет'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ProductCard(
                        product: products[index],
                        categoryLabel: _categoryLabel,
                        onUpdated: _load,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _categories.map((cat) {
          final key = cat['key'] ?? '';
          final label = cat['label'] ?? '';
          final isSelected = key == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = key);
                _load();
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w600,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final String Function(String) categoryLabel;
  final VoidCallback onUpdated;

  const _ProductCard({
    required this.product,
    required this.categoryLabel,
    required this.onUpdated,
  });

  int get totalStock =>
      product.sizes.fold(0, (total, size) => total + size.stock);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildImage(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    categoryLabel(product.category),
                    style: TextStyle(color: AppColors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Остаток: $totalStock',
                    style: TextStyle(color: AppColors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(0)} ₸',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductFormScreen(product: product),
                      ),
                    );
                    if (updated == true) onUpdated();
                    break;
                  case 'delete':
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Удалить товар?'),
                        content: const Text('Действие нельзя отменить.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Отмена'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final success =
                          await ProductService().deleteProduct(product.id);
                      if (success) {
                        onUpdated();
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Не удалось удалить товар'),
                          ),
                        );
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Редактировать'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final image = product.images.isNotEmpty ? product.images.first : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 72,
        width: 72,
        color: AppColors.surface,
        child: image.isNotEmpty
            ? Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: AppColors.grey),
              )
            : const Icon(Icons.image, color: AppColors.grey),
      ),
    );
  }
}
