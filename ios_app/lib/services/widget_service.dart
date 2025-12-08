import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'oasth_api.dart';
import 'session_manager.dart';
import 'stop_repository.dart';

/// Service for updating iOS home screen widget
class WidgetService {
  static const String _appGroupId = 'group.com.oasth.widget';
  static const String _widgetName = 'BusWidget';
  static const String _minimalWidgetName = 'MinimalBusWidget';
  
  final OasthApi _api;
  final StopRepository _stopRepo = StopRepository.instance;
  
  WidgetService(SessionManager sessionManager) : _api = OasthApi(sessionManager);
  
  /// Initialize home widget
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }
  
  /// Update widget with arrivals for a stop (with line filtering)
  Future<void> updateWidget(WidgetConfig config) async {
    try {
      // Resolve Street ID to API ID
      final apiId = await _stopRepo.getApiId(config.stopCode);
      
      // Get stop name if not provided
      String stopName = config.stopName;
      if (stopName.isEmpty) {
        stopName = await _stopRepo.getStopName(config.stopCode) ?? 'Stop ${config.stopCode}';
      }
      
      // Fetch arrivals
      var arrivals = await _api.getArrivals(apiId);
      
      // Apply line filter if set
      final allowedLines = config.getAllowedLines();
      if (allowedLines != null) {
        arrivals = arrivals.where((a) => 
          allowedLines.contains(a.displayLine.toUpperCase())
        ).toList();
        print('WidgetService: Filtered to ${arrivals.length} arrivals for lines: $allowedLines');
      }
      
      // Sort by arrival time
      arrivals.sort((a, b) => a.estimatedMinutes.compareTo(b.estimatedMinutes));
      
      // Convert to JSON for widget
      final arrivalsJson = jsonEncode(
        arrivals.take(5).map((a) => a.toJson()).toList()
      );
      
      // Save data for widget
      await HomeWidget.saveWidgetData<String>('stopCode', config.stopCode);
      await HomeWidget.saveWidgetData<String>('stopName', stopName);
      await HomeWidget.saveWidgetData<String>('lineFilter', config.lineFilter);
      await HomeWidget.saveWidgetData<String>('arrivals', arrivalsJson);
      await HomeWidget.saveWidgetData<String>('lastUpdate', DateTime.now().toIso8601String());
      await HomeWidget.saveWidgetData<String>('error', '');  // Clear any previous error
      
      // Trigger widget refresh for both widgets
      await HomeWidget.updateWidget(
        iOSName: _widgetName,
        androidName: 'BusWidgetProvider',
      );
      await HomeWidget.updateWidget(
        iOSName: _minimalWidgetName,
        androidName: 'MinimalWidgetProvider',
      );
    } catch (e) {
      // Save error state
      await HomeWidget.saveWidgetData<String>('error', e.toString());
      await HomeWidget.updateWidget(
        iOSName: _widgetName,
        androidName: 'BusWidgetProvider',
      );
      await HomeWidget.updateWidget(
        iOSName: _minimalWidgetName,
        androidName: 'MinimalWidgetProvider',
      );
    }
  }
  
  /// Save widget configuration
  Future<void> saveConfig(WidgetConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_config', jsonEncode(config.toJson()));
    
    // Also save to widget data
    await HomeWidget.saveWidgetData<String>('stopCode', config.stopCode);
    await HomeWidget.saveWidgetData<String>('stopName', config.stopName);
    await HomeWidget.saveWidgetData<String>('lineFilter', config.lineFilter);
  }
  
  /// Load widget configuration
  Future<WidgetConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('widget_config');
    
    if (configJson != null) {
      return WidgetConfig.fromJson(jsonDecode(configJson));
    }
    return null;
  }
}

