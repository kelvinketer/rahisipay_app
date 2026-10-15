import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  // 1. Primary API (Localhost for Development)
  static const String primaryApi = 'https://rahisipay-api.onrender.com/api/v1';
  
  // 2. Backup API (Railway) - Left as a placeholder
  static const String backupApi = 'https://rahisipay-backend-production.up.railway.app/api/v1'; 

  /// Fetches data with automatic multi-cloud failover
  static Future<dynamic> get(String endpoint) async {
    try {
      // Step 1: Try the Local API with a 3-second timeout
      final response = await http
          .get(Uri.parse('$primaryApi$endpoint'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        print('✅ Connected to Primary API (Local)');
        return json.decode(response.body);
      } else {
        throw Exception('Primary API returned ${response.statusCode}');
      }
      
    } catch (e) {
      print('⚠️ Local API down or timed out. Rerouting to Railway backup...');
      
      try {
        // Step 2: Fallback to the Railway API
        final fallbackResponse = await http
            .get(Uri.parse('$backupApi$endpoint'))
            .timeout(const Duration(seconds: 5));

        if (fallbackResponse.statusCode == 200) {
          print('✅ Connected to Backup API (Railway)');
          return json.decode(fallbackResponse.body);
        } else {
          throw Exception('Backup API returned ${fallbackResponse.statusCode}');
        }
        
      } catch (fallbackError) {
        // Step 3: Handle total outage gracefully
        print('❌ Both APIs are down: $fallbackError');
        throw Exception('Systems are currently offline. Please try again in a moment.');
      }
    }
  }

  /// POST method with the same fallback logic
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$primaryApi$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Primary POST failed');
      }
    } catch (e) {
      print('⚠️ Rerouting POST request to Railway backup...');
      try {
        final fallbackResponse = await http
            .post(
              Uri.parse('$backupApi$endpoint'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
            .timeout(const Duration(seconds: 6));

        if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
          return json.decode(fallbackResponse.body);
        } else {
          throw Exception('Backup POST failed');
        }
      } catch (fallbackError) {
        throw Exception('Unable to submit data right now. Please check your connection.');
      }
    }
  }
}