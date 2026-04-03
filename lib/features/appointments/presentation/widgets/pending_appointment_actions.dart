import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/user_facing_error.dart';
import '../../../../core/ui/feedback/app_snack_bar.dart';
import '../../data/appointments_repository.dart';
import '../../domain/appointment.dart';
import '../../providers/appointments_providers.dart';

/// Approve / decline controls for appointments still in `requested` status.
class PendingAppointmentActions extends ConsumerStatefulWidget {
  const PendingAppointmentActions({
    super.key,
    required this.appointment,
    this.compact = false,
  });

  final Appointment appointment;
  final bool compact;

  @override
  ConsumerState<PendingAppointmentActions> createState() =>
      _PendingAppointmentActionsState();
}

class _PendingAppointmentActionsState
    extends ConsumerState<PendingAppointmentActions> {
  bool _busy = false;

  Future<void> _applyStatus(String status, {String? rejectionReason}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(appointmentsRepositoryProvider)
          .updateStatus(
            widget.appointment.id,
            status: status,
            rejectionReason: rejectionReason,
          );
      ref.invalidate(appointmentsListProvider);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        status == 'accepted'
            ? 'Appointment approved.'
            : 'Appointment declined.',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, userFacingErrorMessage(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, userFacingErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onApprove() => _applyStatus('accepted');

  Future<void> _onReject() async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Decline appointment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Brief note for the patient',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
    if (!mounted || reason == null) return;
    final trimmed = reason.isEmpty ? null : reason;
    await _applyStatus('rejected', rejectionReason: trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 36.0 : 40.0;
    final fontSize = widget.compact ? 12.0 : 13.0;

    if (_busy) {
      return SizedBox(
        height: height,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final approve = FilledButton(
      onPressed: _onApprove,
      style: FilledButton.styleFrom(
        minimumSize: Size(0, height),
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 16),
        backgroundColor: Colors.tealAccent.withValues(alpha: 0.85),
        foregroundColor: Colors.black87,
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      child: const Text('Approve'),
    );

    final decline = OutlinedButton(
      onPressed: _onReject,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, height),
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 16),
        foregroundColor: Colors.redAccent,
        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      child: const Text('Decline'),
    );

    if (widget.compact) {
      return Row(
        children: [
          Expanded(child: approve),
          const SizedBox(width: 8),
          Expanded(child: decline),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: approve),
        const SizedBox(width: 10),
        Expanded(child: decline),
      ],
    );
  }
}
