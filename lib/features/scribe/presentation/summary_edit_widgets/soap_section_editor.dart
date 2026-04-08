import 'package:flutter/material.dart';

import '../../../../core/theme/doctor_theme.dart';

/// SOAP narrative blocks: chief complaint, HPI, assessment, plan.
class SoapSectionEditor extends StatelessWidget {
  const SoapSectionEditor({
    super.key,
    required this.chiefComplaint,
    required this.historyPresent,
    required this.assessment,
    required this.plan,
  });

  final TextEditingController chiefComplaint;
  final TextEditingController historyPresent;
  final TextEditingController assessment;
  final TextEditingController plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOAP — subjective & plan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: DoctorTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Edit narrative sections shown on the patient record.',
          style: TextStyle(color: DoctorTheme.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        _SoapField(
          label: 'Chief complaint',
          controller: chiefComplaint,
          maxLines: 3,
        ),
        _SoapField(
          label: 'History of present illness',
          controller: historyPresent,
          maxLines: 5,
        ),
        _SoapField(
          label: 'Assessment',
          controller: assessment,
          maxLines: 4,
        ),
        _SoapField(
          label: 'Plan',
          controller: plan,
          maxLines: 4,
        ),
      ],
    );
  }
}

class _SoapField extends StatelessWidget {
  const _SoapField({
    required this.label,
    required this.controller,
    this.maxLines = 3,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DoctorTheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              color: DoctorTheme.textPrimary,
              fontSize: 15,
              height: 1.35,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: DoctorTheme.glassSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DoctorTheme.glassStroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: DoctorTheme.glassStroke),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
