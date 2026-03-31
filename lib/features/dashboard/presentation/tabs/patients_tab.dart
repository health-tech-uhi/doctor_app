import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/feedback/app_status_panel.dart';
import '../../../clinical/domain/care_relationship.dart';
import '../../../clinical/providers/relationships_providers.dart';
import '../../logic/schedule_filters.dart';

/// Patients tab — from GET /api/records/relationships (care relationships).
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(async),
        _buildSearchBar(),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Your patients',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: Colors.tealAccent,
            onRefresh: () async {
              ref.invalidate(relationshipsListProvider);
              await ref.read(relationshipsListProvider.future);
            },
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: AppStatusPanel(
                      compact: true,
                      icon: Icons.cloud_off_rounded,
                      title: 'Couldn\'t load patients',
                      message: 'Pull to refresh or try again later.',
                    ),
                  ),
                ],
              ),
              data: (all) {
                final filtered = _filter(all);
                if (filtered.isEmpty) {
                  return _buildEmpty(all.isEmpty);
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildPatientCard(filtered[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AsyncValue<List<CareRelationship>> async) {
    final count = async.maybeWhen(data: (l) => l.length, orElse: () => null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patients',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${count ?? '—'} in your panel',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search by patient name',
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 22),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.tealAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(CareRelationship r) {
    final last = r.lastConsultationDate;
    final lastLabel = last != null && last.isNotEmpty
        ? 'Last visit: $last'
        : 'Care relationship';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blueGrey.withValues(alpha: 0.25),
            child: Text(
              initialsFromName(r.displayPatientName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.displayPatientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.relationshipStatus?.trim().isNotEmpty == true
                      ? r.relationshipStatus!.trim()
                      : lastLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.chevron_right, color: Colors.white24),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM y').format(r.updatedAt),
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool noRelationshipsAtAll) {
    if (noRelationshipsAtAll) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppStatusPanel(
              compact: true,
              icon: Icons.people_outline,
              title: 'No patients yet',
              message:
                  'When you have active care relationships in the platform, they will appear here.',
            ),
          ),
        ],
      );
    }
    return Center(
      child: AppStatusPanel(
        compact: true,
        icon: Icons.search_off_rounded,
        iconSize: 44,
        title: 'No matching patients',
        message:
            'No results for "$_query". Try another search or clear to see everyone.',
      ),
    );
  }
}
