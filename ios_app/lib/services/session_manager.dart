import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/models.dart';

/// Manages OASTH session via WebView for initial auth
class SessionManager extends ChangeNotifier {
  static const String _prefsKeySession = 'oasth_session';
  static const String _oasthUrl = 'https://telematics.oasth.gr/en/';
  
  SessionData? _session;
  bool _isLoading = false;
  String? _error;
  
  SessionData? get session => _session;
  bool get isLoading => _isLoading;
  bool get isValid => _session?.isValid ?? false;
  String? get error => _error;
  
  SessionManager() {
    _loadCachedSession();
  }
  
  /// Load cached session from SharedPreferences
  Future<void> _loadCachedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_prefsKeySession);
      
      if (sessionJson != null) {
        _session = SessionData.fromJson(jsonDecode(sessionJson));
        if (!_session!.isValid) {
          _session = null;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached session: $e');
    }
  }
  
  /// Save session to SharedPreferences
  Future<void> _saveSession(SessionData session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeySession, jsonEncode(session.toJson()));
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }
  
  /// Get valid session, refreshing if needed
  Future<SessionData> getSession() async {
    if (_session != null && _session!.isValid) {
      return _session!;
    }
    
    final newSession = await refreshSession();
    if (newSession == null) {
      throw Exception('Failed to get session');
    }
    return newSession;
  }
  
  /// Refresh session using WebView
  /// Note: This should be called from a context where WebView can be displayed
  Future<SessionData?> refreshSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // On iOS, we need to use WebViewController differently
      // This is a simplified version - the actual implementation 
      // will extract cookies and token from WebView
      
      // For now, return null to indicate manual refresh needed
      // The HomeScreen will show a WebView for session acquisition
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Set session from WebView extraction
  Future<void> setSession(String phpSessionId, String token) async {
    _session = SessionData(
      phpSessionId: phpSessionId,
      token: token,
      createdAt: DateTime.now(),
    );
    await _saveSession(_session!);
    _error = null;
    notifyListeners();
  }
  
  /// Clear session
  Future<void> clearSession() async {
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeySession);
    notifyListeners();
  }
  
  /// Static URL for WebView
  static String get loginUrl => _oasthUrl;
}
