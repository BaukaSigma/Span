import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  String _category = AppData.productCategories.first['key'] ?? 'tshirt';
  final List<_SizeEntry> _sizes = [];
  final List<File> _images = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController =
        TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(0) : '',
    );

    if (product != null) {
      final hasCategory = AppData.productCategories
          .any((element) => element['key'] == product.category);
      _category = hasCategory ? product.category : 'other';
      if (product.sizes.isNotEmpty) {
        for (final size in product.sizes) {
          _sizes.add(_SizeEntry(label: size.label, stock: size.stock));
        }
      }
    }

    if (_sizes.isEmpty) {
      _sizes.add(_SizeEntry());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (final entry in _sizes) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать товар' : 'Новый товар'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMainCard(),
            const SizedBox(height: 16),
            _buildSizesCard(),
            const SizedBox(height: 16),
            _buildImagesCard(),
            if (isEditing) ...[
              const SizedBox(height: 16),
              _buildDeleteButton(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEditing ? 'Сохранить изменения' : 'Создать товар',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Основные данные',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название товара'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Введите название' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Категория'),
            items: AppData.productCategories
                .map(
                  (category) => DropdownMenuItem(
                    value: category['key'],
                    child: Text(category['label'] ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Цена (₸)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Введите цену';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Описание',
              hintText: 'Напишите пару строк о товаре',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Размеры и остатки',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _sizes.add(_SizeEntry())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Добавить'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._sizes.asMap().entries.map((entry) {
            final index = entry.key;
            final size = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: size.labelController,
                      decoration: const InputDecoration(labelText: 'Размер'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: size.stockController,
                      decoration: const InputDecoration(labelText: 'Остаток'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _sizes.length == 1
                        ? null
                        : () {
                            setState(() {
                              _sizes.removeAt(index).dispose();
                            });
                          },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    final existingImages = widget.product?.images ?? [];
    final selectedImages = _images;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фото товара',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            selectedImages.isNotEmpty
                ? 'Выбрано фото: ${selectedImages.length}'
                : existingImages.isNotEmpty
                    ? 'Текущее фото: ${existingImages.length}'
                    : 'Фото не добавлены',
            style: TextStyle(color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...selectedImages.map(
                (file) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    file,
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (selectedImages.isEmpty)
                ...existingImages.map(
                  (url) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 70,
                        width: 70,
                        color: AppColors.surface,
                        child: const Icon(Icons.broken_image,
                            color: AppColors.grey),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.product != null) ...[
            const SizedBox(height: 12),
            Text(
              'Если выберете новые фото, старые заменятся.',
              style: TextStyle(color: AppColors.grey),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Выбрать фото'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline),
        label: const Text('Удалить товар'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _delete,
      ),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(files.map((file) => File(file.path)));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sizes = _sizes
        .where((entry) => entry.labelController.text.trim().isNotEmpty)
        .map(
          (entry) => ProductSize(
            label: entry.labelController.text.trim(),
            stock: int.tryParse(entry.stockController.text.trim()) ?? 0,
          ),
        )
        .toList();

    if (sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один размер')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    setState(() => _isSaving = true);
    final service = ProductService();
    final product = widget.product;

    ProductModel? result;
    if (product == null) {
      result = await service.createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        price: price,
        sizes: sizes,
        images: _images,
      );
    } else {
      result = await service.updateProduct(
        id: product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        price: price,
        sizes: sizes,
        images: _images.isEmpty ? null : _images,
      );
    }
    setState(() => _isSaving = false);

    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить товар')),
      );
    }
  }

  Future<void> _delete() async {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || widget.product == null) return;

    final success = await ProductService().deleteProduct(widget.product!.id);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить товар')),
      );
    }
  }
}

class _SizeEntry {
  final TextEditingController labelController;
  final TextEditingController stockController;

  _SizeEntry({String? label, int? stock})
      : labelController = TextEditingController(text: label ?? ''),
        stockController =
            TextEditingController(text: stock != null ? '$stock' : '');

  void dispose() {
    labelController.dispose();
    stockController.dispose();
  }
}
