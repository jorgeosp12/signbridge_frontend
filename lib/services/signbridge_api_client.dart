import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class TopKPrediction {
  final String label;
  final double confidence;

  const TopKPrediction({
    required this.label,
    required this.confidence,
  });

  factory TopKPrediction.fromJson(Map<String, dynamic> json) {
    return TopKPrediction(
      label: json['label'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
    );
  }
}

class SignPrediction {
  final String label;
  final double confidence;
  final List<TopKPrediction> topK;
  final int startFrame;
  final int endFrame;

  const SignPrediction({
    required this.label,
    required this.confidence,
    required this.topK,
    required this.startFrame,
    required this.endFrame,
  });

  factory SignPrediction.fromJson(Map<String, dynamic> json) {
    final rawTopK = json['top_k'] as List<dynamic>? ?? const <dynamic>[];
    return SignPrediction(
      label: json['label'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      topK: rawTopK
          .whereType<Map>()
          .map((entry) =>
              TopKPrediction.fromJson(Map<String, dynamic>.from(entry)))
          .toList(),
      startFrame: json['start_frame'] as int? ?? 0,
      endFrame: json['end_frame'] as int? ?? 0,
    );
  }
}

class HealthStatus {
  final String status;
  final bool modelLoaded;
  final String device;
  final int numClasses;
  final int maxSeqLength;

  const HealthStatus({
    required this.status,
    required this.modelLoaded,
    required this.device,
    required this.numClasses,
    required this.maxSeqLength,
  });

  bool get isReady => status.toLowerCase() == 'ok' && modelLoaded;

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      status: json['status'] as String? ?? 'unknown',
      modelLoaded: json['model_loaded'] as bool? ?? false,
      device: json['device'] as String? ?? 'unknown',
      numClasses: json['num_classes'] as int? ?? 0,
      maxSeqLength: json['max_seq_length'] as int? ?? 0,
    );
  }
}

class SignBridgeApiClient {
  final String baseUrl;
  final String apiKey;
  final int maxRetries;
  final http.Client _httpClient;

  SignBridgeApiClient({
    required this.baseUrl,
    required this.apiKey,
    this.maxRetries = 3,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  void close() {
    _httpClient.close();
  }

  Future<HealthStatus> healthCheck({
    int maxAttempts = 3,
    Duration requestTimeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/health');
    if (maxAttempts < 1) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts', 'Must be >= 1');
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await _httpClient.get(
          uri,
          headers: const <String, String>{'Content-Type': 'application/json'},
        ).timeout(requestTimeout);

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return HealthStatus.fromJson(decoded);
        }

        final isRetryable = response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504;
        if (isRetryable && attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        throw ApiException(
          statusCode: response.statusCode,
          message: _extractErrorMessage(response.body),
        );
      } on TimeoutException {
        if (attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        rethrow;
      }
    }

    throw TimeoutException('Health check did not complete in time.');
  }

  Future<SignPrediction> predictSign(List<List<double>> keypoints) async {
    if (keypoints.isEmpty) {
      throw const ApiException(
        statusCode: 422,
        message: 'No frames were captured for this sign.',
      );
    }

    final uri =
        Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/predict/sign');
    final payload = jsonEncode(<String, dynamic>{'keypoints': keypoints});

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      final response = await _httpClient
          .post(
            uri,
            headers: <String, String>{
              'Content-Type': 'application/json',
              'X-API-Key': apiKey,
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final prediction = decoded['prediction'] as Map<String, dynamic>?;
        if (prediction == null) {
          throw const ApiException(
            statusCode: 500,
            message: 'Unexpected server response: missing prediction data.',
          );
        }
        return SignPrediction.fromJson(prediction);
      }

      final isRetryable =
          response.statusCode == 429 || response.statusCode == 503;
      if (isRetryable && attempt < maxRetries) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 1;
        await Future<void>.delayed(Duration(seconds: retryAfter));
        continue;
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response.body),
      );
    }

    throw const ApiException(
      statusCode: 503,
      message: 'Server busy after multiple retries. Please try again.',
    );
  }

  String _extractErrorMessage(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
      final detail = decoded['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } catch (_) {
      // Ignore parse failures and fallback to generic message.
    }
    return 'Request failed. Please try again.';
  }
}
