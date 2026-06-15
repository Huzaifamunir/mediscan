// ─── finding_card.dart ────────────────────────────────────────────────────────
// lib/widgets/finding_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';

class FindingCard extends StatelessWidget {
  final Finding finding;

  const FindingCard({super.key, required this.finding});

  Color _statusColor(FindingStatus status) {
    switch (status) {
      case FindingStatus.normal:
        return AppTheme.accent;
      case FindingStatus.low:
        return AppTheme.info;
      case FindingStatus.high:
        return AppTheme.accentWarm;
      case FindingStatus.critical:
        return AppTheme.danger;
      case FindingStatus.unknown:
        return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(FindingStatus status) {
    switch (status) {
      case FindingStatus.normal:
        return Icons.check_circle_rounded;
      case FindingStatus.low:
        return Icons.arrow_downward_rounded;
      case FindingStatus.high:
        return Icons.arrow_upward_rounded;
      case FindingStatus.critical:
        return Icons.warning_rounded;
      case FindingStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(finding.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  finding.parameter,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(finding.status), color: color, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      finding.status.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(
                label: 'Value',
                value: finding.value,
                color: color,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Normal',
                value: finding.normalRange,
                color: AppTheme.textMuted,
              ),
            ],
          ),
          if (finding.interpretation != null &&
              finding.interpretation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              finding.interpretation!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
