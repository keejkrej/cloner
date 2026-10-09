import 'dart:convert';
import 'package:http/http.dart' as http;
import 'connector.dart';
import '../workflows/models/workflow_step.dart';

class HttpConnector extends Connector {
  final http.Client? client;

  HttpConnector({this.client});

  @override
  String get serviceId => 'http';

  @override
  String get displayName => 'Webhooks / HTTP by Zapier';

  @override
  String get iconName => 'http';

  @override
  Future<Map<String, dynamic>> evaluateTrigger(WorkflowStep triggerStep) async {
    final sample = triggerStep.config['sample_payload'];
    if (sample is Map) {
      return Map<String, dynamic>.from(sample);
    }
    return {
      'event': 'webhook_received',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {'status': 'active', 'source': 'inbound_hook'},
    };
  }

  @override
  Future<Map<String, dynamic>> executeAction(
    WorkflowStep step,
    Map<String, dynamic> resolvedConfig,
    Map<String, dynamic> executionContext,
  ) async {
    final httpClient = client ?? http.Client();
    final urlStr = resolvedConfig['url'] as String? ?? 'https://httpbin.org/get';
    final method = (resolvedConfig['method'] as String? ?? 'GET').toUpperCase();
    final uri = Uri.parse(urlStr);

    final rawHeaders = resolvedConfig['headers'];
    final headers = <String, String>{
      'User-Agent': 'ZapierAI-Agent/1.0',
    };
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) => headers[k.toString()] = v.toString());
    }

    final body = resolvedConfig['body'];
    String? requestBody;
    if (body != null) {
      if (body is String) {
        requestBody = body;
        if (!headers.containsKey('Content-Type') && (body.startsWith('{') || body.startsWith('['))) {
          headers['Content-Type'] = 'application/json';
        }
      } else {
        requestBody = jsonEncode(body);
        headers['Content-Type'] = 'application/json';
      }
    }

    try {
      http.Response response;
      switch (method) {
        case 'POST':
          response = await httpClient.post(uri, headers: headers, body: requestBody).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await httpClient.put(uri, headers: headers, body: requestBody).timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await httpClient.delete(uri, headers: headers, body: requestBody).timeout(const Duration(seconds: 15));
          break;
        case 'GET':
        default:
          response = await httpClient.get(uri, headers: headers).timeout(const Duration(seconds: 15));
          break;
      }

      dynamic parsedJson;
      try {
        parsedJson = jsonDecode(response.body);
      } catch (_) {
        parsedJson = null;
      }

      return {
        'status_code': response.statusCode,
        'body': response.body,
        'json': parsedJson,
        'headers': response.headers,
        'is_success': response.statusCode >= 200 && response.statusCode < 300,
      };
    } catch (e) {
      // In case of network offline / timeout, return error structure
      return {
        'status_code': 500,
        'body': 'HTTP Request Error: $e',
        'is_success': false,
        'error': e.toString(),
      };
    }
  }
}
