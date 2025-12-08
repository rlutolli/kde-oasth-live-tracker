import 'dart:convert';
import 'package:flutter/services.dart';

/// Repository for resolving Street IDs (visible on signs) to API IDs (for getStopArrivals).
/// Also provides stop names for display.
/// 
/// stops.json structure:
/// {
///   "1403": {
///     "StreetID": "1403",
///     "StopDescr": "ΤΖΑΒΕΛΛΑ",
///     "API_IDs": ["1306"]
///   },
///   ...
/// }
class StopRepository {
  static StopRepository? _instance;
  
  /// Map: Street ID -> API ID
  Map<String, String>? _apiIdMap;
  
  /// Map: Street ID -> Stop Description
  Map<String, String>? _stopNameMap;

  StopRepository._();
  
  static StopRepository get instance {
    _instance ??= StopRepository._();
    return _instance!;
  }

  /// Resolves a Street ID to an API ID for getStopArrivals.
  Future<String> getApiId(String streetId) async {
    await _ensureLoaded();
    
    final apiId = _apiIdMap?[streetId];
    if (apiId != null) {
      print('StopRepository: Mapped StreetID $streetId -> API ID $apiId');
      return apiId;
    }
    
    print('StopRepository: No mapping for $streetId, assuming it\'s already an API ID');
    return streetId;
  }

  /// Gets the stop name/description for a Street ID.
  Future<String?> getStopName(String streetId) async {
    await _ensureLoaded();
    return _stopNameMap?[streetId];
  }

  Future<void> _ensureLoaded() async {
    if (_apiIdMap != null) return;
    
    print('StopRepository: Loading stops.json...');
    final apiMap = <String, String>{};
    final nameMap = <String, String>{};
    
    try {
      final jsonString = await rootBundle.loadString('assets/stops.json');
      final jsonObject = json.decode(jsonString) as Map<String, dynamic>;
      
      for (final streetId in jsonObject.keys) {
        final stopObject = jsonObject[streetId] as Map<String, dynamic>;
        
        // Get the first API_ID from the array
        final apiIds = stopObject['API_IDs'] as List<dynamic>?;
        if (apiIds != null && apiIds.isNotEmpty) {
          apiMap[streetId] = apiIds[0].toString();
        }
        
        // Get stop description
        final stopDescr = stopObject['StopDescr'] as String?;
        if (stopDescr != null && stopDescr.isNotEmpty) {
          nameMap[streetId] = stopDescr;
        }
      }
      
      _apiIdMap = apiMap;
      _stopNameMap = nameMap;
      print('StopRepository: Loaded ${apiMap.length} stops, ${nameMap.length} names');
      
    } catch (e) {
      print('StopRepository: Error loading stops.json: $e');
      _apiIdMap = {};
      _stopNameMap = {};
    }
  }
}
