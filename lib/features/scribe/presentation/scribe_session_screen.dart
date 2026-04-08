import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/doctor_theme.dart';
import '../../../core/ui/feedback/app_snack_bar.dart';
import '../../appointments/domain/appointment.dart';
import '../data/models/transcript_message.dart';
import '../data/scribe_pcm_recorder.dart';
import 'scribe_session_controller.dart';
import 'widgets/live_audio_waveform.dart';
import 'widgets/insight_card.dart';
import 'widgets/recording_indicator.dart';

/// In-consultation scribe: mic → relay WebSocket, live transcript + insights.
///
/// State lives in [ScribeSessionController]; UI listens once via [ListenableBuilder]
/// so socket/audio updates are not interleaved with separate [ValueListenableBuilder]s
/// (which contributed to iOS `semantics.parentDataDirty` failures).
class ScribeSessionScreen extends ConsumerStatefulWidget {
  const ScribeSessionScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  ConsumerState<ScribeSessionScreen> createState() =>
      _ScribeSessionScreenState();
}

class _ScribeSessionScreenState extends ConsumerState<ScribeSessionScreen> {
  late final ScrollController _scroll;
  late final LiveWaveformController _waveform;
  late final ScribeSessionController _session;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _waveform = LiveWaveformController();
    _session = ScribeSessionController(
      ref: ref,
      appointment: widget.appointment,
      scrollController: _scroll,
      waveform: _waveform,
      showMessage: (message, {required isError}) {
        if (!mounted) return;
        AppSnackBar.show(context, message, isError: isError);
      },
      onNavigateToReview: (args) {
        if (!mounted) return;
        context.pushReplacement('/scribe/review', extra: args);
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_session.start());
    });
  }

  @override
  void dispose() {
    _session.dispose();
    _waveform.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _confirmEndSession() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End scribe session?'),
        content: const Text(
          'Audio will stop and a consultation summary draft will be requested.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End & request summary'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _session.endSession();
  }

  Future<void> _confirmLeave() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text(
          'The scribe will disconnect. Unsaved summary progress may be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget _transcriptLine(TranscriptMessage m) {
    final isDoctor = m.speaker.toLowerCase().contains('doctor');
    final label = isDoctor ? 'Doctor' : 'Patient';
    final color =
        isDoctor ? DoctorTheme.accentCyan : DoctorTheme.accentLavender;
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: DoctorTheme.secondaryText,
          fontSize: 14,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: m.text.isNotEmpty ? m.text : m.original),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: DoctorTheme.textPrimary,
          fontWeight: FontWeight.w800,
        );

    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.appointment.displayPatientName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _session.ending ? null : _confirmLeave,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListenableBuilder(
            listenable: _session,
            builder: (context, _) {
              if (_session.connecting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (_session.connectError != null) {
                return Center(
                  child: Text(
                    _session.connectError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: DoctorTheme.secondaryText,
                    ),
                  ),
                );
              }

              final insights = _session.insightsSorted;
              final lines = _session.transcripts;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RepaintBoundary(
                          child: RecordingIndicator(
                            elapsed: _session.elapsed,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: (!_session.sessionReady || _session.ending)
                            ? null
                            : _confirmEndSession,
                        style: FilledButton.styleFrom(
                          backgroundColor: DoctorTheme.accentCyan,
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        child: _session.ending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text('End session'),
                      ),
                      if (ScribePcmRecorder.supportedPlatform) ...[
                        const SizedBox(width: 8),
                        if (_session.recording)
                          const Chip(
                            avatar: Icon(
                              Icons.mic_rounded,
                              size: 16,
                              color: DoctorTheme.accentCyan,
                            ),
                            label: Text('Mic live'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: (_session.startingMic ||
                                    !_session.sessionReady)
                                ? null
                                : () {
                                    unawaited(_session.startMicrophone());
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            icon: _session.startingMic
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.mic_none_rounded),
                            label: Text(
                              !_session.sessionReady
                                  ? 'Starting...'
                                  : _session.micPermissionDenied
                                  ? 'Grant mic'
                                  : 'Start mic',
                            ),
                          ),
                      ],
                    ],
                  ),
                  if (_session.micError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: DoctorTheme.accentAmber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _session.micError!,
                            style: const TextStyle(
                              color: DoctorTheme.accentAmber,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (_session.micPermissionDenied)
                          TextButton(
                            onPressed: () async {
                              await openAppSettings();
                            },
                            child: const Text('Settings'),
                          ),
                      ],
                    ),
                  ],
                  if (!ScribePcmRecorder.supportedPlatform) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Audio capture is not available on this platform; connect from iOS/Android to stream PCM.',
                      style: TextStyle(
                        color: DoctorTheme.accentAmber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: DoctorTheme.glassSurface.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DoctorTheme.glassStroke),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CustomScrollView(
                          controller: _scroll,
                          physics: const ClampingScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              sliver: SliverToBoxAdapter(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 18,
                                      color: DoctorTheme.accentCyan,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Live insights',
                                      style: titleStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 10)),
                            if (insights.isEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 16,
                                    left: 4,
                                    right: 4,
                                  ),
                                  child: Text(
                                    'Insights from the AI will appear here as you speak.',
                                    style: TextStyle(
                                      color: DoctorTheme.textTertiary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 8,
                                      left: 4,
                                      right: 4,
                                    ),
                                    child: InsightCard(insight: insights[i]),
                                  ),
                                  childCount: insights.length,
                                ),
                              ),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 16, 12, 8),
                              sliver: SliverToBoxAdapter(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.subtitles_outlined,
                                      size: 18,
                                      color: DoctorTheme.accentLavender,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Live transcript',
                                      style: titleStyle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 10)),
                            if (lines.isEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 24,
                                    left: 4,
                                    right: 4,
                                  ),
                                  child: Text(
                                    'Transcript will stream here…',
                                    style: TextStyle(
                                      color: DoctorTheme.textTertiary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(4, 0, 4, 16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _transcriptLine(lines[i]),
                                    ),
                                    childCount: lines.length,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LiveAudioWaveform(
                    controller: _waveform,
                    active: _session.recording,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
