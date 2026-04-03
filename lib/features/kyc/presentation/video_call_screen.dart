import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/adaptive/adaptive_app_bar.dart';
import '../../../core/ui/adaptive/adaptive_widgets.dart';

/// Video verification is not yet integrated with a live SDK (see product backlog).
/// Doctors complete document upload; admin / clinic coordinates any live verification.
class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AdaptiveAppBar.forScreen(context, title: 'Video verification'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.videocam_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Verification call',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Live video verification is not enabled in this build. '
                'Submit your documents from the previous step; our team will review them '
                'and contact you if a call is required.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.45,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              AdaptivePrimaryButton(
                onPressed: () => context.go('/kyc'),
                child: const Text('Back to verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
