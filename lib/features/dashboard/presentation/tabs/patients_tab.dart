import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/doctor_theme.dart';
import '../../../../core/ui/glass/aurora_background.dart';
import '../../../../core/ui/glass/glass_card.dart';
import '../../../../core/ui/glass/glass_icon_button.dart';
import '../../../clinical/domain/care_relationship.dart';
import '../../../clinical/providers/relationships_providers.dart';
import '../../logic/schedule_filters.dart';

class PatientsTab extends ConsumerStatefulWidget {
  const PatientsTab({super.key});

  @override
  ConsumerState<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends ConsumerState<PatientsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CareRelationship> _filter(List<CareRelationship> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((r) {
      final name = r.displayPatientName.toLowerCase();
      final status = (r.relationshipStatus ?? '').toLowerCase();
      return name.contains(q) || status.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(relationshipsListProvider);

    return Scaffold(
      backgroundColor: DoctorTheme.scaffoldBackground,
      body: AuroraBackground(
        child: Column(
          children: [
            _buildHeader(async),
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                color: DoctorTheme.accentCyan,
                backgroundColor: DoctorTheme.surfaceElevated,
                onRefresh: () async {
                  ref.invalidate(relationshipsListProvider);
                  await ref.read(relationshipsListProvider.future);
                },
                child: async.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) =>
                      const Center(child: Text('Connect to load patients')),
                  data: (all) {
                    final filtered = _filter(all);
                    if (filtered.isEmpty) return _buildEmpty(all.isEmpty);

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildPatientCard(filtered[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<CareRelationship>> async) {
    final count = async.maybeWhen(data: (l) => l.length, orElse: () => 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patients',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count active patients in your panel',
                  style: const TextStyle(
                    color: DoctorTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GlassIconButton(icon: Icons.person_add_rounded, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: DoctorTheme.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DoctorTheme.glassStroke),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: DoctorTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search patients by name or status...',
          hintStyle: const TextStyle(
            color: DoctorTheme.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DoctorTheme.accentCyan,
            size: 20,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DoctorTheme.textTertiary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPatientCard(CareRelationship r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () {},
        child: Row(
          children: [
            _buildAvatarPill(r.displayPatientName),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.displayPatientName,
                    style: const TextStyle(
                      color: DoctorTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: DoctorTheme.accentCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.relationshipStatus ?? 'Active Patient',
                        style: const TextStyle(
                          color: DoctorTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DoctorTheme.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPill(String name) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: DoctorTheme.profileGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DoctorTheme.accentCyan.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: DoctorTheme.accentCyan.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initialsFromName(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmpty(bool noRelationshipsAtAll) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: DoctorTheme.textTertiary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  noRelationshipsAtAll
                      ? 'No patients found'
                      : 'No patients match your search',
                  style: const TextStyle(
                    color: DoctorTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (noRelationshipsAtAll) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: DoctorTheme.accentCyan,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('Add New Patient'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
