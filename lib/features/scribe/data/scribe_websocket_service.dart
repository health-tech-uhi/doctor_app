import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'models/insight_message.dart';
import 'models/summary_draft.dart';
import 'models/transcript_message.dart';

/// Manages the doctor_app ↔ clinical-scribe WebSocket (PCM binary + JSON control).
class ScribeWebSocketService {
  ScribeWebSocketService({required String baseUrl}) : _baseUrl = baseUrl.trim();

  final String _baseUrl;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  int _pcmChunksSent = 0;

  final _transcripts = StreamController<TranscriptMessage>.broadcast();
  final _insights = StreamController<InsightMessage>.broadcast();
  final _summaryDrafts = StreamController<SummaryDraftModel>.broadcast();
  final _errors = StreamController<ScribeWsError>.broadcast();
  final _sessionStarted = StreamController<SessionStartedInfo>.broadcast();
  final _sessionEnded = StreamController<SessionEndedInfo>.broadcast();

  Stream<TranscriptMessage> get transcripts => _transcripts.stream;
  Stream<InsightMessage> get insights => _insights.stream;
  Stream<SummaryDraftModel> get summaryDrafts => _summaryDrafts.stream;
  Stream<ScribeWsError> get errors => _errors.stream;
  Stream<SessionStartedInfo> get sessionStarted => _sessionStarted.stream;
  Stream<SessionEndedInfo> get sessionEnded => _sessionEnded.stream;

  bool get isConnected => _channel != null;

  Uri _buildUri({
    required String token,
    required String appointmentId,
    required String patientId,
  }) {
    final base = _baseUrl.endsWith('/ws') ? _baseUrl : '$_baseUrl/ws';
    return Uri.parse(base).replace(
      queryParameters: {
        'token': token,
        'appointment_id': appointmentId,
        'patient_id': patientId,
      },
    );
  }

  Future<void> connect({
    required String token,
    required String appointmentId,
    required String patientId,
  }) async {
    await disconnect();
    _pcmChunksSent = 0;
    final uri = _buildUri(
      token: token,
      appointmentId: appointmentId,
      patientId: patientId,
    );
    _channel = WebSocketChannel.connect(uri);
    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (Object e, StackTrace st) {
        _errors.add(ScribeWsError(code: 'WS_ERROR', message: e.toString()));
      },
      onDone: () {
        _errors.add(
          const ScribeWsError(
            code: 'WS_CLOSED',
            message: 'Scribe connection closed by server.',
          ),
        );
        _channel = null;
      },
      cancelOnError: false,
    );
  }

  void _onMessage(dynamic message) {
    if (message is Uint8List) {
      return;
    }
    if (message is! String) {
      return;
    }
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return;
      json = decoded;
    } catch (_) {
      return;
    }

    final type = json['type'] as String?;
    switch (type) {
      case 'session_started':
        final sid = json['session_id'] as String? ?? '';
        final sum = json['summary_id'] as String? ?? '';
        final aid = json['appointment_id'] as String? ?? '';
        if (sid.isNotEmpty && sum.isNotEmpty) {
          _sessionStarted.add(
            SessionStartedInfo(
              sessionId: sid,
              summaryId: sum,
              appointmentId: aid,
            ),
          );
        }
        break;
      case 'transcript':
        _transcripts.add(TranscriptMessage.fromJson(json));
        break;
      case 'insight':
      case 'allergy_alert':
        _insights.add(InsightMessage.fromJson(json));
        break;
      case 'summary_draft':
        final draft = SummaryDraftModel.fromWsJson(json);
        if (draft.summaryId.isNotEmpty) {
          _summaryDrafts.add(draft);
        }
        break;
      case 'error':
        _errors.add(
          ScribeWsError(
            code: json['code'] as String? ?? 'UNKNOWN',
            message: json['message'] as String? ?? '',
          ),
        );
        break;
      case 'session_ended':
        _sessionEnded.add(
          SessionEndedInfo(
            sessionId: json['session_id'] as String? ?? '',
            durationSecs: (json['duration_secs'] as num?)?.toInt() ?? 0,
          ),
        );
        break;
      default:
        break;
    }
  }

  /// Same PCM buffers that drive the live waveform ([ScribePcmRecorder] calls [onChunk] right after level metering).
  void sendAudio(Uint8List pcmData) {
    _pcmChunksSent++;
    if (kDebugMode &&
        (_pcmChunksSent == 1 || _pcmChunksSent % 200 == 0)) {
      debugPrint(
        'scribe_ws: PCM outbound #$_pcmChunksSent (${pcmData.length} B), '
        'socket=${_channel != null}',
      );
    }
    _channel?.sink.add(pcmData);
  }

  void requestSummary() {
    _channel?.sink.add(jsonEncode({'type': 'request_summary'}));
  }

  void endSession() {
    _channel?.sink.add(jsonEncode({'type': 'end_session'}));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _transcripts.close();
    await _insights.close();
    await _summaryDrafts.close();
    await _errors.close();
    await _sessionStarted.close();
    await _sessionEnded.close();
  }
}

@immutable
class SessionStartedInfo {
  const SessionStartedInfo({
    required this.sessionId,
    required this.summaryId,
    required this.appointmentId,
  });

  final String sessionId;
  final String summaryId;
  final String appointmentId;
}

@immutable
class SessionEndedInfo {
  const SessionEndedInfo({required this.sessionId, required this.durationSecs});

  final String sessionId;
  final int durationSecs;
}

@immutable
class ScribeWsError {
  const ScribeWsError({required this.code, required this.message});

  final String code;
  final String message;
}
