import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'session_manager.dart';

/// OASTH API client using session credentials
class OasthApi {
  static const String _baseUrl = 'https://telematics.oasth.gr';
  static const String _apiUrl = '$_baseUrl/api/';
  
  final SessionManager _sessionManager;
  bool _isRetrying = false;
  
  OasthApi(this._sessionManager);
  
  /// Get arrivals for a specific stop
  Future<List<BusArrival>> getArrivals(String stopCode) async {
    try {
      final session = await _sessionManager.getSession();
      
      final response = await http.post(
        Uri.parse('$_apiUrl?act=getStopArrivals&p1=$stopCode'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': session.token,
          'Cookie': 'PHPSESSID=${session.phpSessionId}',
          'Origin': _baseUrl,
          'Referer': '$_baseUrl/',
        },
      );
      
      // Check for unauthorized
      if (response.statusCode == 401 || 
          response.body.toLowerCase().contains('unauthorized') ||
          response.body.toLowerCase().contains('not authorized')) {
        if (!_isRetrying) {
          _isRetrying = true;
          await _sessionManager.refreshSession();
          final result = await getArrivals(stopCode);
          _isRetrying = false;
          return result;
        } else {
          _isRetrying = false;
          return [];
        }
      }
      
      try {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => BusArrival.fromJson(item)).toList();
      } catch (e) {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Get stop info by code
  Future<String?> getStopInfo(String stopCode) async {
    try {
      final session = await _sessionManager.getSession();
      
      final response = await http.post(
        Uri.parse('$_apiUrl?act=getStopArrivals&p1=$stopCode'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': session.token,
          'Cookie': 'PHPSESSID=${session.phpSessionId}',
        },
      );
      
      // Try to extract stop description
      final regex = RegExp(r'"bstop_descr"\s*:\s*"([^"]+)"');
      final match = regex.firstMatch(response.body);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }
}
