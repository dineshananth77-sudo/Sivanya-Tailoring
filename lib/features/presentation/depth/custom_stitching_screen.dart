import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../booking_screen.dart';

class CustomStitchingScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialCategory;
  final String? initialPrice;
  final String? initialImageUrl;

  const CustomStitchingScreen({
    super.key,
    this.initialTitle,
    this.initialCategory,
    this.initialPrice,
    this.initialImageUrl,
  });

  @override
  State<CustomStitchingScreen> createState() => _CustomStitchingScreenState();
}

class _CustomStitchingScreenState extends State<CustomStitchingScreen> {
  String selectedOutfit = 'Blouse';

  final TextEditingController designController = TextEditingController();
  final Map<String, TextEditingController> measurementControllers = {};
  final ImagePicker _imagePicker = ImagePicker();

  File? selectedImage;
  bool _isPickingImage = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> outfitCategories = [
    {
      'name': 'Blouse',
      'image': 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=300',
    },
    {
      'name': 'Kurti',
      'image': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300',
    },
    {
      'name': 'Lehenga',
      'image': 'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=300',
    },
    {
      'name': 'Salwar Suit',
      'image': 'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=300',
    },
    {
      'name': 'Dress',
      'image': 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=300',
    },
    {
      'name': 'Saree Blouse',
      'image': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=300',
    },
  ];

  final Map<String, List<String>> outfitMeasurements = {
    'Blouse': ['Bust', 'Waist', 'Shoulder', 'Blouse Length'],
    'Kurti': ['Bust', 'Waist', 'Hip', 'Shoulder', 'Kurti Length'],
    'Lehenga': ['Waist', 'Hip', 'Lehenga Length'],
    'Salwar Suit': ['Bust', 'Waist', 'Hip', 'Suit Length'],
    'Dress': ['Bust', 'Waist', 'Hip', 'Dress Length'],
    'Saree Blouse': ['Bust', 'Waist', 'Shoulder', 'Length'],
    'Other': ['Chest / Bust', 'Waist', 'Hip', 'Length'],
  };

  @override
  void initState() {
    super.initState();
    selectedOutfit = widget.initialCategory ?? 'Blouse';
    _initMeasurementControllers();
  }

  void _initMeasurementControllers() {
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
    measurementControllers.clear();

    final fields = outfitMeasurements[selectedOutfit] ?? outfitMeasurements['Other']!;
    for (final field in fields) {
      measurementControllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    designController.dispose();
    for (final controller in measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => selectedImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _continueToBooking() {
    if (_isSubmitting) return;

    if (designController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your desired design details.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final measurements = <String, String>{};
    for (final entry in measurementControllers.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        measurements[entry.key] = entry.value.text.trim();
      }
    }

    setState(() => _isSubmitting = true);

    final designTitle = widget.initialTitle?.trim().isNotEmpty == true
        ? widget.initialTitle!
        : 'Custom $selectedOutfit';

    final designPrice = widget.initialPrice?.trim().isNotEmpty == true
        ? widget.initialPrice!
        : 'From ₹499 (Estimated)';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          designTitle: designTitle,
          designPrice: designPrice,
          designCategory: selectedOutfit,
          initialGarmentType: selectedOutfit,
          initialMeasurements: measurements,
          initialDescription: designController.text.trim(),
          referenceImage: selectedImage,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isSubmitting = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = outfitMeasurements[selectedOutfit] ?? outfitMeasurements['Other']!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text(
          'CUSTOM STITCHING',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Outfit Selection Header
            _buildCard(
              title: '1. Select Outfit to Stitch',
              child: SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: outfitCategories.length,
                  itemBuilder: (context, index) {
                    final item = outfitCategories[index];
                    final isSelected = selectedOutfit == item['name'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedOutfit = item['name']!;
                          _initMeasurementControllers();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 76,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.softLavender : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: Image.network(item['image']!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['name']!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Reference Image Upload
            _buildCard(
              title: '2. Upload Inspiration / Reference Photo',
              child: Column(
                children: [
                  if (selectedImage != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => selectedImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('From Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Design Description
            _buildCard(
              title: '3. Describe Your Custom Details',
              child: TextField(
                controller: designController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: AppColors.text),
                decoration: const InputDecoration(
                  hintText: 'e.g. Deep back neck with dori, elbow sleeves, pure cotton lining...',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 4. Quick Measurements
            _buildCard(
              title: '4. Measurements (Inches) - Optional',
              child: Column(
                children: [
                  const Text(
                    'You can also confirm measurements during your free WhatsApp consultation.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ...fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              field,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: measurementControllers[field],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. 36',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _continueToBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PROCEED TO BOOKING',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.8),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1.5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
