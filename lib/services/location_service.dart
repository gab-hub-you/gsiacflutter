import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LocationService {
  static const String baseUrl = 'https://psgc.gitlab.io/api';
  static const String pangasinanCode = '015500000';

  Future<List<Map<String, String>>> getMunicipalities() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/provinces/$pangasinanCode/municipalities.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((m) => {
          'name': m['name'] as String,
          'code': m['code'] as String,
        }).toList()..sort((a, b) => a['name']!.compareTo(b['name']!));
      }
    } catch (e) {
      debugPrint('Error fetching municipalities: $e');
    }
    return [];
  }

  Future<List<String>> getBarangays(String municipalityCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/municipalities/$municipalityCode/barangays.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((b) => b['name'] as String).toList()..sort();
      }
    } catch (e) {
      debugPrint('Error fetching barangays: $e');
    }
    return [];
  }
}
