
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';


import '../data/measurement_service.dart';
import '../data/order_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/service/api_service.dart';
import '../../core/widgets/sivanya_loader.dart';

class BookingScreen extends StatefulWidget {
  final String designTitle;
  final String designPrice;
  final String designCategory;

  final String? initialGarmentType;
  final Map<String, String>? initialMeasurements;
  final String? initialDescription;
  final File? referenceImage;

  const BookingScreen({
    super.key,
    required this.designTitle,
    required this.designPrice,
    this.designCategory = '',
    this.initialGarmentType,
    this.initialMeasurements,
    this.initialDescription,
    this.referenceImage,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color ivory = Color(0xFFF5F1E9);
  static const Color plum = Color(0xFF492B46);
  static const Color charcoal = Color(0xFF22201F);
  static const Color rose = Color(0xFFB98591);
  static const Color muted = Color(0xFF77716D);
  static const Color borderColor = Color(0xFFD8CFC5);

  final _formKey = GlobalKey<FormState>();

  final MeasurementService _measurementService =
      MeasurementService();

  final OrderService _orderService = OrderService();

  final chestController = TextEditingController();
  final waistController = TextEditingController();
  final hipController = TextEditingController();
  final shoulderController = TextEditingController();
  final lengthController = TextEditingController();
  final notesController = TextEditingController();

  String garmentType = 'Blouse';
  String fabricPreference = 'I will provide the fabric';

  bool _saveAsDefault = true;
  bool _isLoading = true;
  bool _isSubmitting = false;

  static const String whatsappNumber = AppConstants.whatsappBusinessNumber;

  final List<String> fabricOptions = [
    'I will provide the fabric',
    'I need fabric from the tailor',
    'I need fabric recommendations',
  ];

  @override
  void initState() {
    super.initState();

    garmentType = widget.initialGarmentType ?? 'Blouse';

    final measurements = widget.initialMeasurements ?? {};

    chestController.text =
        measurements['Bust'] ?? measurements['Chest'] ?? '';

    waistController.text = measurements['Waist'] ?? '';
    hipController.text = measurements['Hip'] ?? '';
    shoulderController.text = measurements['Shoulder'] ?? '';

    lengthController.text =
        measurements['Blouse Length'] ??
        measurements['Kurti Length'] ??
        measurements['Dress Length'] ??
        measurements['Suit Length'] ??
        measurements['Lehenga Length'] ??
        measurements['Petticoat Length'] ??
        measurements['Length'] ??
        '';

    notesController.text = widget.initialDescription ?? '';

    _loadSavedMeasurements();
  }

  @override
  void dispose() {
    chestController.dispose();
    waistController.dispose();
    hipController.dispose();
    shoulderController.dispose();
    lengthController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedMeasurements() async {
    try {
      final measurements =
          await _measurementService.loadMeasurements();

      if (!mounted) return;

      if (measurements != null) {
        if (chestController.text.isEmpty) {
          chestController.text =
              measurements['chest']?.toString() ?? '';
        }

        if (waistController.text.isEmpty) {
          waistController.text =
              measurements['waist']?.toString() ?? '';
        }

        if (hipController.text.isEmpty) {
          hipController.text =
              measurements['hip']?.toString() ?? '';
        }

        if (shoulderController.text.isEmpty) {
          shoulderController.text =
              measurements['shoulder']?.toString() ?? '';
        }

        if (lengthController.text.isEmpty) {
          lengthController.text =
              measurements['length']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Measurement loading error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMeasurements() {
    final Map<String, dynamic> measurements =
        Map<String, dynamic>.from(
      widget.initialMeasurements ?? {},
    );

    measurements.addAll({
      'chest': chestController.text.trim(),
      'waist': waistController.text.trim(),
      'hip': hipController.text.trim(),
      'shoulder': shoulderController.text.trim(),
      'length': lengthController.text.trim(),
    });

    return measurements;
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        throw Exception(
          'Unsupported image format. Please use JPG, PNG or WEBP.',
        );
    }
  }

  Future<String?> _uploadReferenceImage() async {
    final image = widget.referenceImage;

    if (image == null) return null;

    final token = await ApiService.getToken();

    if (token == null) {
      throw Exception('Please login before uploading an image.');
    }

    if (!await image.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final extension = image.path.split('.').last.toLowerCase();
    _getContentType(extension); // Validate format

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/upload/reference-image'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        image.path,
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = data['image_url'] as String?;
        debugPrint('IMAGE UPLOAD SUCCESS: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('IMAGE UPLOAD FAILED: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('IMAGE UPLOAD FAILED: $e');
      debugPrint('STACK TRACE: $stackTrace');
      return null;
    }
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (!ApiService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login before placing an order.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final measurements = _getMeasurements();

      if (_saveAsDefault) {
        await _measurementService.saveMeasurements(
          measurements,
        );
      }

      final referenceImageUrl =
          await _uploadReferenceImage();

      final orderId = await _orderService.createOrder(
        designTitle: widget.designTitle,
        designCategory: widget.designCategory,
        designPrice: widget.designPrice,
        garmentType: garmentType,
        measurements: measurements,
        fabricPreference: fabricPreference,
        specialInstructions: notesController.text.trim(),
        referenceImagePath: referenceImageUrl,
      );

      if (!mounted) return;

      final measurementDetails = measurements.entries
          .map(
            (entry) => '${entry.key}: ${entry.value} inches',
          )
          .join('\n');

      final imageMessage = referenceImageUrl ?? 'No reference image provided';

      final message = '''
Hello! I have submitted a tailoring request.

Order ID: $orderId

Design: ${widget.designTitle}
Category: ${widget.designCategory}
Price: ${widget.designPrice}
Garment: $garmentType
Fabric: $fabricPreference

CUSTOM MEASUREMENTS:
$measurementDetails

ADDITIONAL REQUIREMENTS:
${notesController.text.trim().isEmpty ? 'None' : notesController.text.trim()}

REFERENCE IMAGE:
$imageMessage

Please contact me regarding this order.
''';

      final whatsappUrl = Uri.https(
        'wa.me',
        '/$whatsappNumber',
        {'text': message},
      );

      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: plum,
          content: Text(
            launched
                ? 'Order saved! Continue on WhatsApp.'
                : 'Order saved! Your Order ID is $orderId.',
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('ORDER SUBMISSION FAILED: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: plum,
            content: Text('Could not submit order: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ivory,

      appBar: AppBar(
        backgroundColor: ivory,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'ORDER CONSULTATION',
          style: TextStyle(
            color: plum,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: SivanyaLoader(
                size: 64,
                message: 'Preparing your tailoring consultation...',
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALMOST YOURS',
                      style: TextStyle(
                        color: rose,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Let\'s make it perfect.',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: charcoal,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Review your design, confirm your measurements '
                      'and share your tailoring preferences.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _sectionHeading('01', 'YOUR ORDER'),

                    const SizedBox(height: 14),

                    _buildOrderSummary(),

                    if (widget.referenceImage != null) ...[
                      const SizedBox(height: 28),

                      _sectionHeading(
                        '02',
                        'YOUR REFERENCE IMAGE',
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: charcoal,
                          ),
                          color: const Color(0xFFECE4DD),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Image.file(
                              widget.referenceImage!,
                              width: double.infinity,
                              height: 210,
                              fit: BoxFit.cover,
                            ),

                            const SizedBox(height: 9),

                            const Text(
                              'YOUR DESIGN INSPIRATION',
                              style: TextStyle(
                                color: muted,
                                fontSize: 9,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    _sectionHeading(
                      '03',
                      'GARMENT DETAILS',
                    ),

                    const SizedBox(height: 14),

                    _label('Garment type'),

                    DropdownButtonFormField<String>(
                      initialValue: garmentType,
                      decoration: _inputDecoration(
                        'Select garment',
                      ),
                      items: [
                        'Blouse',
                        'Kurti',
                        'Dress',
                        'Saree Blouse',
                        'Salwar Suit',
                        'Lehenga',
                        'Saree',
                        'Other',
                      ].map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            garmentType = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    _sectionHeading(
                      '04',
                      'YOUR MEASUREMENTS',
                    ),

                    const SizedBox(height: 9),

                    const Text(
                      'Measurements are in inches. Your previously '
                      'entered custom measurements are preserved.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 17),

                    _measurementField(
                      'Chest / Bust',
                      chestController,
                    ),

                    _measurementField(
                      'Waist',
                      waistController,
                    ),

                    _measurementField(
                      'Hip',
                      hipController,
                    ),

                    _measurementField(
                      'Shoulder',
                      shoulderController,
                    ),

                    _measurementField(
                      'Garment Length',
                      lengthController,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: borderColor,
                        ),
                      ),
                      child: CheckboxListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        activeColor: plum,
                        value: _saveAsDefault,
                        onChanged: (value) {
                          setState(() {
                            _saveAsDefault = value ?? false;
                          });
                        },
                        title: const Text(
                          'Save as my default measurements',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: charcoal,
                          ),
                        ),
                        controlAffinity:
                            ListTileControlAffinity.leading,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _sectionHeading(
                      '05',
                      'FABRIC PREFERENCE',
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: fabricPreference,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        'Choose fabric preference',
                      ),
                      items: fabricOptions.map((item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            fabricPreference = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    _sectionHeading(
                      '06',
                      'ADDITIONAL REQUIREMENTS',
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: notesController,
                      maxLines: 5,
                      style: const TextStyle(
                        color: charcoal,
                        fontSize: 13,
                      ),
                      decoration: _inputDecoration(
                        'Describe fitting preferences, design details or anything else we should know...',
                      ),
                    ),

                    const SizedBox(height: 25),

                    _buildWhatsAppNote(),

                    const SizedBox(height: 30),

                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: rose,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 57,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: plum,
                            foregroundColor: ivory,
                            elevation: 0,
                            shape:
                                const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(
                                color: charcoal,
                                width: 1,
                              ),
                            ),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: ivory,
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'CONFIRM YOUR ORDER',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    SizedBox(width: 11),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 27),

                    const Center(
                      child: Text(
                        'STITCHED WITH CARE. MADE FOR YOU.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECE4DD),
        border: Border.all(
          color: charcoal,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: plum,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECTED DESIGN',
            style: TextStyle(
              color: muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.7,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.designTitle,
            style: const TextStyle(
              color: charcoal,
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            widget.designCategory.toUpperCase(),
            style: const TextStyle(
              color: muted,
              fontSize: 10,
              letterSpacing: 1.3,
            ),
          ),

          const SizedBox(height: 17),

          const Divider(color: borderColor),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DESIGN PRICE',
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),

              Flexible(
                child: Text(
                  widget.designPrice,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: plum,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: plum,
                size: 16,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Garment: $garmentType',
                  style: const TextStyle(
                    color: charcoal,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppNote() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFECE4DD),
        border: Border.all(
          color: charcoal,
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.chat_outlined,
            color: plum,
            size: 22,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A personal consultation',
                  style: TextStyle(
                    color: charcoal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Your order will be saved in the app. '
                  'After submission, you can continue the '
                  'conversation with our tailor on WhatsApp.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String number, String title) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            color: rose,
            fontFamily: 'serif',
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: charcoal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        title,
        style: const TextStyle(
          color: charcoal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _measurementField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
        ),
        style: const TextStyle(
          color: charcoal,
          fontSize: 13,
        ),
        decoration: _inputDecoration('$label (inches)'),
        validator: (value) {
          if (value != null && value.trim().isNotEmpty) {
            final measurement = double.tryParse(
              value.trim(),
            );

            if (measurement == null || measurement <= 0) {
              return 'Enter a valid measurement';
            }
          }

          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: muted,
        fontSize: 12,
      ),
      filled: true,
      fillColor: const Color(0xFFECE4DD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: plum,
          width: 1.5,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: rose,
        ),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: rose,
          width: 1.5,
        ),
      ),
    );
  }
}
