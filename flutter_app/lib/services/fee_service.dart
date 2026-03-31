import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fee.dart';
import 'package:flutter/foundation.dart';

class FeeService {
  static const baseUrl = "http://10.0.2.2:3000";

  static Future<List<Fee>> getFees() async {
    final response = await http.get(Uri.parse("$baseUrl/api/fees"));

    if (kDebugMode) {
      debugPrint("GET /api/fees => ${response.statusCode}");
      debugPrint("BODY => ${response.body}");
    }

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Fee.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load fees: ${response.body}");
    }
  }

  static Future<void> payFee(String id) async {
    final response = await http.post(Uri.parse("$baseUrl/api/pay/$id"));

    if (kDebugMode) {
      debugPrint("POST /api/pay/$id => ${response.statusCode}");
      debugPrint("BODY => ${response.body}");
    }
    if (response.statusCode != 200) {
      throw Exception("Payment failed: ${response.body}");
    }
  }
}
