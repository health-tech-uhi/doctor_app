import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../../appointments/domain/appointment.dart';
import '../data/models/insight_message.dart';
import '../data/models/transcript_message.dart';
import '../data/scribe_pcm_recorder.dart';
import '../data/scribe_websocket_service.dart';
import 'summary_review_screen.dart';
import 'widgets/live_audio_waveform.dart';

/// Owns WebSocket, optional PCM recorder, timers, and transcript/insight buffers.
///
/// All [notifyListeners] calls are **deferred** to the next frame so updates that
/// arrive from sockets or native audio during layout/semantics do not trigger
/// `!semantics.parentDataDirty` assertions on iOS.
class ScribeSessionController extends ChangeNotifier {
  ScribeSessionController({
    required WidgetRef ref,
    required this.appointment,
    required this.scrollController,
    required this.waveform,
    required this.showMessage,
    required this.onNavigateToReview,
  }) : _ref = ref;

  final WidgetRef _ref;
  final Appointment appointment;
  final ScrollController scrollController;
  final LiveWaveformController waveform;

  /// Snackbar / toast — must check [BuildContext.mounted] in the closure.
  final void Function(String message, {required bool isError}) showMessage;

  final void Function(ScribeSummaryReviewArgs args) onNavigateToReview;

  ScribeWebSocketService? _ws;
  ScribePcmRecorder? _recorder;

  final List<StreamSubscription<dynamic>> _subs = [];

  bool _connecting = true;
  bool _sessionReady = false;
  String? _connectError;
  bool _micPermissionDenied = false;
  bool _startingMic = false;
  bool _recording = false;
  String? _micError;
  bool _ending = false;
  String? _sessionId;
  Timer? _sessionStartTimeout;

  Timer? _elapsedTimer;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  final List<TranscriptMessage> _transcripts = [];
  final List<InsightMessage> _insights = [];

  bool _notifyScheduled = false;

  static const int _maxTranscripts = 400;

  bool get connecting => _connecting;
  bool get sessionReady => _sessionReady;
  String? get connectError => _connectError;
  bool get micPermissionDenied => _micPermissionDenied;
  bool get startingMic => _startingMic;
  bool get recording => _recording;
  String? get micError => _micError;
  bool get ending => _ending;
  String? get sessionId => _sessionId;
  Duration get elapsed => _elapsed;

  List<TranscriptMessage> get transcripts =>
      List<TranscriptMessage>.unmodifiable(_transcripts);

  List<InsightMessage> get insightsSorted {
    final sorted = [..._insights]
      ..sort((a, b) {
        int rank(String s) {
          if (s == 'critical') return 0;
          if (s == 'warning') return 1;
          return 2;
        }

        return rank(a.severity).compareTo(rank(b.severity));
      });
    return sorted;
  }

  void _scheduleNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final needsDeferral = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (!needsDeferral) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  void _setElapsed(Duration d) {
    _elapsed = d;
    _scheduleNotify();
  }

  Future<void> start() async {
    await disposeServices();
    _transcripts.clear();
    _insights.clear();
    _sessionId = null;
    _sessionReady = false;
    _startedAt = null;
    _elapsed = Duration.zero;
    _startingMic = false;
    _recording = false;
    _micError = null;
    waveform.reset();
    _sessionStartTimeout?.cancel();
    _sessionStartTimeout = null;

    _connecting = true;
    _connectError = null;
    _micPermissionDenied = false;
    _scheduleNotify();

    final token = await _ref.read(secureStorageProvider).getAccessToken();
    if (token == null || token.isEmpty) {
      _connecting = false;
      _connectError = 'Not signed in — cannot open scribe connection.';
      _scheduleNotify();
      return;
    }

    _ws = ScribeWebSocketService(
      baseUrl: _ref.read(scribeWsBaseUrlProvider),
    );
    final ws = _ws!;

    try {
      await ws.connect(
        token: token,
        appointmentId: appointment.id,
        patientId: appointment.patientId,
      );
    } catch (e) {
      await disposeServices();
      _connecting = false;
      _connectError = e.toString();
      _scheduleNotify();
      return;
    }

    _subs.add(
      ws.sessionStarted.listen((e) {
        _sessionId = e.sessionId;
        _sessionReady = true;
        _sessionStartTimeout?.cancel();
        _sessionStartTimeout = null;
        _startedAt ??= DateTime.now();
        _elapsed = Duration.zero;
        _elapsedTimer?.cancel();
        _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_startedAt == null) return;
          _setElapsed(DateTime.now().difference(_startedAt!));
        });
        _scheduleNotify();
        // Begin streaming PCM as soon as the relay is ready (permission dialog may show).
        // Without this, Sarvam stays idle until the user taps "Start mic" and no transcripts appear.
        unawaited(startMicrophone());
      }),
    );

    _subs.add(
      ws.transcripts.listen((t) {
        _transcripts.add(t);
        if (_transcripts.length > _maxTranscripts) {
          _transcripts.removeRange(0, _transcripts.length - _maxTranscripts);
        }
        _scheduleNotify();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = scrollController;
          if (!c.hasClients) return;
          c.jumpTo(c.position.maxScrollExtent);
        });
      }),
    );

    _subs.add(
      ws.insights.listen((i) {
        _insights.insert(0, i);
        _scheduleNotify();
      }),
    );

    _subs.add(
      ws.errors.listen((err) {
        if (err.code == 'WS_CLOSED' || err.code == 'SESSION_CREATE_FAILED') {
          _connectError = err.message;
        }
        showMessage('${err.code}: ${err.message}', isError: true);
        _scheduleNotify();
      }),
    );

    _connecting = false;
    _elapsed = Duration.zero;
    _scheduleNotify();
    _sessionStartTimeout?.cancel();
    _sessionStartTimeout = Timer(const Duration(seconds: 8), () {
      if (_sessionReady || _connectError != null) return;
      _connectError =
          'Scribe session did not initialize. Please check clinical-scribe logs.';
      _scheduleNotify();
    });
  }

  Future<void> startMicrophone() async {
    if (_startingMic || _recording) return;
    if (!_sessionReady) {
      showMessage('Session is still initializing. Please wait a second.', isError: true);
      return;
    }
    final ws = _ws;
    if (ws == null) {
      showMessage('Scribe socket is not connected yet.', isError: true);
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _micPermissionDenied = true;
      _micError = 'Microphone permission is required for the scribe.';
      _scheduleNotify();
      return;
    }
    _micPermissionDenied = false;
    _micError = null;
    _startingMic = true;
    _scheduleNotify();

    await _recorder?.stop();
    _recorder = null;

    final r = ScribePcmRecorder(
      onChunk: ws.sendAudio,
      onLevel: waveform.pushLevel,
    );
    _recorder = r;
    try {
      await r.start();
      _recording = true;
    } catch (e) {
      _recording = false;
      _recorder = null;
      _micError = 'Could not start microphone: $e';
      showMessage('Could not start microphone: $e', isError: true);
    } finally {
      _startingMic = false;
      _scheduleNotify();
    }
  }

  Future<void> retryAfterMicDenied() async {
    _micPermissionDenied = false;
    await startMicrophone();
  }

  Future<void> endSession() async {
    _ending = true;
    _scheduleNotify();

    await _recorder?.stop();
    _recorder = null;
    final ws = _ws;
    if (ws == null) {
      _ending = false;
      _scheduleNotify();
      return;
    }
    ws.endSession();
    ws.requestSummary();

    try {
      final draft = await ws.summaryDrafts.first.timeout(
        const Duration(minutes: 2),
      );
      onNavigateToReview(
        ScribeSummaryReviewArgs(
          draft: draft,
          patientId: appointment.patientId,
          appointmentId: appointment.id,
          sessionId: _sessionId,
        ),
      );
    } on TimeoutException {
      showMessage(
        'Timed out waiting for summary. Check that the AI agent is running.',
        isError: true,
      );
    } catch (e) {
      showMessage(userFacingErrorMessage(e), isError: true);
    } finally {
      _ending = false;
      _scheduleNotify();
    }
  }

  Future<void> disposeServices() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _sessionStartTimeout?.cancel();
    _sessionStartTimeout = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _recorder?.stop();
    _recorder = null;
    await _ws?.dispose();
    _ws = null;
    _sessionId = null;
    _sessionReady = false;
    _startedAt = null;
    _startingMic = false;
    _recording = false;
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _sessionStartTimeout?.cancel();
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    unawaited(_recorder?.stop());
    unawaited(_ws?.dispose());
    _recorder = null;
    _ws = null;
    _startingMic = false;
    _recording = false;
    super.dispose();
  }
}
