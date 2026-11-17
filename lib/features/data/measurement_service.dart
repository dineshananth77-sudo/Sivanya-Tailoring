import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../core/service/api_service.dart';

class MeasurementService {
  static String get baseUrl => ApiService.baseUrl;

  // Load saved default measurements via FastAPI
  Future<Map<String, dynamic>?> loadMeasurements() async {
    final token = await ApiService.getToken();

    if (token == null) {
      throw Exception('Please login before viewing measurements.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/measurements/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data['measurements'];

      if (raw is Map && raw.isNotEmpty) {
        return Map<String, dynamic>.from(raw);
      }
      return null;
    }

    if (response.statusCode == 401) {
      await ApiService.logout();
      throw Exception('Session expired. Please login again.');
    }

    final data = jsonDecode(response.body);
    throw Exception(data['detail'] ?? 'Could not load measurements.');
  }

  // Save or update default measurements via FastAPI
  Future<Map<String, dynamic>> saveMeasurements(
    Map<String, dynamic> measurements, {
    String? outfitType,
  }) async {
    final token = await ApiService.getToken();

    if (token == null) {
      throw Exception('Please login before saving measurements.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/measurements/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'measurements': measurements,
        'outfit_type': outfitType,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['measurements'] ?? measurements);
    }

    if (response.statusCode == 401) {
      await ApiService.logout();
      throw Exception('Session expired. Please login again.');
    }

    throw Exception(data['detail'] ?? 'Failed to save measurements.');
  }
}
