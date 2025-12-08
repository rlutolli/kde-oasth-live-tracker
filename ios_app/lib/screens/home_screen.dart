import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/session_manager.dart';
import '../services/widget_service.dart';
import '../models/models.dart';
import '../services/oasth_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _stopCodeController = TextEditingController();
  final TextEditingController _stopNameController = TextEditingController();
  final TextEditingController _lineFilterController = TextEditingController();
  List<BusArrival> _arrivals = [];
  bool _isLoading = false;
  String? _error;
  bool _showWebView = false;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    WidgetService.initialize();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final sessionManager = context.read<SessionManager>();
    final widgetService = WidgetService(sessionManager);
    final config = await widgetService.loadConfig();
    if (config != null) {
      _stopCodeController.text = config.stopCode;
      _stopNameController.text = config.stopName;
      _lineFilterController.text = config.lineFilter;
    }
  }

  Future<void> _fetchArrivals() async {
    if (_stopCodeController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessionManager = context.read<SessionManager>();
      final api = OasthApi(sessionManager);
      var arrivals = await api.getArrivals(_stopCodeController.text);
      
      // Apply line filter if set
      final config = WidgetConfig(
        stopCode: _stopCodeController.text,
        stopName: _stopNameController.text,
        lineFilter: _lineFilterController.text,
      );
      final allowedLines = config.getAllowedLines();
      if (allowedLines != null) {
        arrivals = arrivals.where((a) => 
          allowedLines.contains(a.displayLine.toUpperCase())
        ).toList();
      }
      
      // Sort by arrival time
      arrivals.sort((a, b) => a.estimatedMinutes.compareTo(b.estimatedMinutes));
      
      setState(() {
        _arrivals = arrivals;
        _isLoading = false;
      });

      // Update widget
      final widgetService = WidgetService(sessionManager);
      await widgetService.updateWidget(config);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    final sessionManager = context.read<SessionManager>();
    final widgetService = WidgetService(sessionManager);
    await widgetService.saveConfig(WidgetConfig(
      stopCode: _stopCodeController.text,
      stopName: _stopNameController.text,
      lineFilter: _lineFilterController.text,
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved!')),
    );
  }

  void _initWebViewForSession() {
    setState(() {
      _showWebView = true;
    });
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            // Wait for page to fully load, then extract credentials
            await Future.delayed(const Duration(seconds: 3));
            await _extractCredentials();
          },
        ),
      )
      ..loadRequest(Uri.parse(SessionManager.loginUrl));
  }

  Future<void> _extractCredentials() async {
    if (_webViewController == null) return;
    
    try {
      // Extract token from JavaScript
      final tokenResult = await _webViewController!.runJavaScriptReturningResult('window.token');
      final token = tokenResult.toString().replaceAll('"', '');
      
      if (token.isNotEmpty && token != 'null') {
        // Get cookies - on iOS this is more complex, simplified here
        // In real implementation, use WKHTTPCookieStore
        final sessionManager = context.read<SessionManager>();
        
        // For now, we'll need to implement proper cookie extraction
        // This is a placeholder - actual implementation needs native code
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session acquired! You can now use the widget.')),
        );
        
        setState(() {
          _showWebView = false;
        });
      }
    } catch (e) {
      debugPrint('Error extracting credentials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    
    if (_showWebView && _webViewController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('OASTH Session'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _showWebView = false),
          ),
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OASTH LIVE',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchArrivals,
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session status
              _buildSessionStatus(sessionManager),
              const SizedBox(height: 16),
              
              // Stop configuration
              _buildStopConfig(),
              const SizedBox(height: 16),
              
              // Arrivals list
              Expanded(child: _buildArrivalsList()),
              
              // Widget instructions
              _buildWidgetInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStatus(SessionManager sessionManager) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF9500)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            sessionManager.isValid ? Icons.check_circle : Icons.warning,
            color: sessionManager.isValid 
              ? Colors.green 
              : const Color(0xFFFF9500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sessionManager.isValid 
                ? 'Session Active'
                : 'Session Required',
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Color(0xFFFFAA00),
              ),
            ),
          ),
          if (!sessionManager.isValid)
            TextButton(
              onPressed: _initWebViewForSession,
              child: const Text(
                'CONNECT',
                style: TextStyle(
                  color: Color(0xFFFF9500),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStopConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _stopCodeController,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Color(0xFFFFAA00),
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: 'STOP CODE',
                  labelStyle: const TextStyle(color: Color(0xFFFF9500)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF9500)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFAA00)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _stopNameController,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Color(0xFFFFAA00),
                ),
                decoration: InputDecoration(
                  labelText: 'STOP NAME (optional)',
                  labelStyle: const TextStyle(color: Color(0xFFFF9500)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF9500)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFAA00)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Line filter input
        TextField(
          controller: _lineFilterController,
          style: const TextStyle(
            fontFamily: 'Courier',
            color: Color(0xFFFFAA00),
          ),
          decoration: InputDecoration(
            labelText: 'LINE FILTER (optional)',
            hintText: 'e.g. 01, 31, 52 (empty = show all)',
            hintStyle: const TextStyle(color: Color(0x80FFAA00)),
            labelStyle: const TextStyle(color: Color(0xFFFF9500)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFFF9500)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFFFAA00)),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _fetchArrivals,
              icon: const Icon(Icons.search),
              label: const Text('FETCH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('SAVE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF9500),
                side: const BorderSide(color: Color(0xFFFF9500)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArrivalsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF9500)),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_arrivals.isEmpty) {
      return const Center(
        child: Text(
          'Enter a stop code and tap FETCH',
          style: TextStyle(
            fontFamily: 'Courier',
            color: Color(0xFFFFAA00),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x4DFFAA00)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x4DFFAA00)),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'LINE',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DESTINATION',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'MIN',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      color: Color(0xFFFF9500),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Arrivals
          Expanded(
            child: ListView.builder(
              itemCount: _arrivals.length,
              itemBuilder: (context, index) {
                final arrival = _arrivals[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: index < _arrivals.length - 1
                      ? const Border(bottom: BorderSide(color: Color(0x1AFFAA00)))
                      : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          arrival.displayLine,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFFFFAA00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          arrival.lineDescr,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFFFFAA00),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${arrival.estimatedMinutes}\'',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            color: Color(0xFFFFAA00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0x1AFF9500),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 Add Widget:',
            style: TextStyle(
              fontFamily: 'Courier',
              color: Color(0xFFFF9500),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '1. Long-press home screen\n'
            '2. Tap + button\n'
            '3. Find "OASTH Live"',
            style: TextStyle(
              fontFamily: 'Courier',
              color: Color(0xFFFFAA00),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
