/// Data models for OASTH bus tracker

/// Bus arrival data from OASTH API
class BusArrival {
  final String lineId;      // bline_id
  final String lineDescr;   // bline_descr
  final String routeCode;   // route_code
  final String vehicleCode; // veh_code
  final String rawTime;     // btime2

  BusArrival({
    required this.lineId,
    required this.lineDescr,
    required this.routeCode,
    required this.vehicleCode,
    required this.rawTime,
  });

  /// Parse estimated minutes from rawTime string
  int get estimatedMinutes => int.tryParse(rawTime) ?? 0;

  /// Display name - prefer lineId if available
  String get displayLine => lineId.isNotEmpty ? lineId : routeCode;

  factory BusArrival.fromJson(Map<String, dynamic> json) {
    return BusArrival(
      lineId: json['bline_id']?.toString() ?? '',
      lineDescr: json['bline_descr']?.toString() ?? '',
      routeCode: json['route_code']?.toString() ?? '',
      vehicleCode: json['veh_code']?.toString() ?? '',
      rawTime: json['btime2']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bline_id': lineId,
      'bline_descr': lineDescr,
      'route_code': routeCode,
      'veh_code': vehicleCode,
      'btime2': rawTime,
    };
  }
}

/// Session credentials for API access
class SessionData {
  final String phpSessionId;
  final String token;
  final DateTime createdAt;

  SessionData({
    required this.phpSessionId,
    required this.token,
    required this.createdAt,
  });

  /// Check if session is still valid (less than 1 hour old)
  bool get isValid {
    return DateTime.now().difference(createdAt).inMinutes < 60;
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      phpSessionId: json['phpSessionId'] ?? '',
      token: json['token'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phpSessionId': phpSessionId,
      'token': token,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Widget configuration
class WidgetConfig {
  final String stopCode;
  final String stopName;
  final String lineFilter;  // Comma-separated line IDs to show (empty = show all)

  WidgetConfig({
    required this.stopCode,
    this.stopName = '',
    this.lineFilter = '',
  });

  /// Parse line filter into a set of allowed lines.
  /// Returns null if no filter (show all lines).
  Set<String>? getAllowedLines() {
    if (lineFilter.trim().isEmpty) return null;
    return lineFilter
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  factory WidgetConfig.fromJson(Map<String, dynamic> json) {
    return WidgetConfig(
      stopCode: json['stopCode'] ?? '',
      stopName: json['stopName'] ?? '',
      lineFilter: json['lineFilter'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stopCode': stopCode,
      'stopName': stopName,
      'lineFilter': lineFilter,
    };
  }
}

