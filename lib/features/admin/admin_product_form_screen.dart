import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme/app_colors.dart';
import '../../core/service/api_client.dart';

class AdminProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _isActive = true;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _descController = TextEditingController(text: p?['description'] ?? '');
    _priceController = TextEditingController(text: p != null ? p['price'].toString() : '');
    _stockController = TextEditingController(
        text: (p != null && p['stock_quantity'] != null) ? p['stock_quantity'].toString() : '');
    _selectedCategoryId = p?['category_id']?.toString();
    _isAvailable = p?['is_available'] ?? true;
    _isActive = p?['is_active'] ?? true;

    _loadCategoriesAndDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndDetails() async {
    setState(() => _isLoading = true);
    try {
      final catsRes = await ApiClient.get('/admin/categories');
      _categories = List<Map<String, dynamic>>.from(catsRes as List);

      if (_selectedCategoryId == null && _categories.isNotEmpty) {
        _selectedCategoryId = _categories.first['id'].toString();
      }

      if (_isEditing) {
        final prodId = widget.product!['id'];
        final detail = await ApiClient.get('/products/$prodId');
        if (detail['images'] is List) {
          _images = List<Map<String, dynamic>>.from(detail['images'] as List);
        }
      }
    } catch (e) {
      debugPrint('Error loading categories/details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'category_id': _selectedCategoryId,
      'is_available': _isAvailable,
      'is_active': _isActive,
      if (_stockController.text.trim().isNotEmpty)
        'stock_quantity': int.tryParse(_stockController.text.trim()),
    };

    try {
      if (_isEditing) {
        final prodId = widget.product!['id'];
        await ApiClient.put('/admin/products/$prodId', body: payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        final created = await ApiClient.post('/admin/products', body: payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created! You can now add images.'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminProductFormScreen(product: created as Map<String, dynamic>),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (!_isEditing) return;
    if (_images.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 8 images allowed per product.')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final prodId = widget.product!['id'];
      final uploaded = await ApiClient.uploadFile(
        '/admin/products/$prodId/images',
        file: File(picked.path),
        fileField: 'file',
      );

      if (mounted) {
        setState(() {
          _images.add(Map<String, dynamic>.from(uploaded as Map));
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded to Cloudinary!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _setPrimaryImage(String imageId) async {
    final prodId = widget.product!['id'];
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.patch('/admin/products/$prodId/images/$imageId/primary');
      if (!mounted) return;
      setState(() {
        for (var img in _images) {
          img['is_primary'] = (img['id'].toString() == imageId);
        }
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Primary image updated!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final prodId = widget.product!['id'];
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.delete('/admin/products/$prodId/images/$imageId');
      if (!mounted) return;
      setState(() {
        _images.removeWhere((img) => img['id'].toString() == imageId);
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Image removed.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Details Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Details',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat['id'].toString(),
                                  child: Text(cat['name']),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCategoryId = val),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Price (₹) *',
                                      prefixText: '₹ ',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      final p = double.tryParse(v);
                                      if (p == null || p <= 0) return 'Must be > 0';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _stockController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Stock Qty',
                                      hintText: 'e.g. 15',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _descController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),

                            SwitchListTile(
                              title: const Text('Available for Purchase', style: TextStyle(fontWeight: FontWeight.w600)),
                              value: _isAvailable,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => setState(() => _isAvailable = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: const Text('Active in Catalog', style: TextStyle(fontWeight: FontWeight.w600)),
                              value: _isActive,
                              activeThumbColor: AppColors.primary,
                              onChanged: (val) => setState(() => _isActive = val),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cloudinary Images Card (Available when editing)
                    if (_isEditing) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cloudinary Images',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                                      ),
                                      Text(
                                        '${_images.length}/8 uploaded',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                                    icon: _isUploadingImage
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.add_a_photo_rounded, size: 16),
                                    label: const Text('UPLOAD'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (_images.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      'No images uploaded yet. Upload JPEG, PNG or WebP images.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ),
                                )
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) {
                                    final img = _images[index];
                                    final isPrimary = img['is_primary'] == true;
                                    final url = img['cloudinary_url'] ?? '';

                                    return Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPrimary ? AppColors.primary : AppColors.border,
                                              width: isPrimary ? 2 : 1,
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(url),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        // Primary Badge
                                        if (isPrimary)
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'PRIMARY',
                                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                              ),
                                            ),
                                          ),
                                        // Action buttons overlay
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          right: 6,
                                          child: Row(
                                            children: [
                                              if (!isPrimary)
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () => _setPrimaryImage(img['id'].toString()),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black87,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Text(
                                                        'Set Primary',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 6),
                                              InkWell(
                                                onTap: () => _deleteImage(img['id'].toString()),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade800,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Icon(Icons.delete_rounded, color: Colors.white, size: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          _isEditing ? 'UPDATE PRODUCT' : 'CREATE PRODUCT',
                          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
