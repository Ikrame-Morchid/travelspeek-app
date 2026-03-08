import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  String _status = '⏳ En attente...';
  String _response = '';
  bool _isLoading = false;
  Color _statusColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    // Tester automatiquement au démarrage
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Test de connexion...';
      _statusColor = Colors.orange;
      _response = '';
    });

    try {
      print('🔍 Testing URL: ${ApiConstants.baseUrl}');
      
      // Test 1: Health check
      final healthUrl = '${ApiConstants.baseUrl}/health';
      print('🔍 Health check: $healthUrl');
      
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 Status code: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _status = '✅ Connexion réussie !';
          _statusColor = Colors.green;
          _response = 'Health: ${data['status']}\n\n'
              'URL Backend: ${ApiConstants.baseUrl}\n'
              'Response: ${response.body}';
          _isLoading = false;
        });

        // Test 2: Get monuments
        _testMonuments();
      } else {
        setState(() {
          _status = '❌ Erreur ${response.statusCode}';
          _statusColor = Colors.red;
          _response = 'Response: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _status = '❌ Erreur de connexion';
        _statusColor = Colors.red;
        _response = 'Erreur: $e\n\n'
            'URL tentée: ${ApiConstants.baseUrl}\n\n'
            'Vérifiez que:\n'
            '1. Le backend est lancé\n'
            '2. ngrok est actif\n'
            '3. L\'URL dans api_constants.dart est correcte';
        _isLoading = false;
      });
    }
  }

  Future<void> _testMonuments() async {
    try {
      final monumentsUrl = '${ApiConstants.baseUrl}/monuments';
      print('🔍 Testing monuments: $monumentsUrl');
      
      final response = await http.get(
        Uri.parse(monumentsUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List monuments = jsonDecode(response.body);
        
        setState(() {
          _response += '\n\n✅ Monuments récupérés: ${monuments.length}\n';
          if (monuments.isNotEmpty) {
            _response += '\nPremier monument:\n${monuments[0]}';
          }
        });
      }
    } catch (e) {
      print('❌ Error fetching monuments: $e');
      setState(() {
        _response += '\n\n⚠️ Monuments non récupérés: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Backend'),
        backgroundColor: _statusColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _statusColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        _statusColor == Colors.green
                            ? Icons.check_circle
                            : _statusColor == Colors.red
                                ? Icons.error
                                : Icons.hourglass_empty,
                        size: 48,
                        color: _statusColor,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _statusColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Backend URL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌐 Backend URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ApiConstants.baseUrl,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Response
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📡 Réponse du serveur:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _response.isEmpty ? 'Aucune réponse...' : _response,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Retry Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: const Icon(Icons.refresh),
              label: const Text('🔄 Tester à nouveau'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}