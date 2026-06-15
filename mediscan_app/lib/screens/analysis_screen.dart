import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/analysis_result.dart';
import '../widgets/finding_card.dart';
import '../widgets/risk_badge.dart';

class AnalysisScreen extends StatelessWidget {
  final AnalysisResult result;

  const AnalysisScreen({super.key, required this.result});

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppTheme.accent;
      case RiskLevel.moderate:
        return AppTheme.accentWarm;
      case RiskLevel.high:
        return const Color(0xFFFF6B35);
      case RiskLevel.critical:
        return AppTheme.danger;
    }
  }

  Gradient _riskGradient(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppTheme.successGradient;
      case RiskLevel.moderate:
        return const LinearGradient(
            colors: [Color(0xFFFF9F0A), Color(0xFFFF6B35)]);
      case RiskLevel.high:
        return const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF453A)]);
      case RiskLevel.critical:
        return AppTheme.dangerGradient;
    }
  }

  Future<void> _share() async {
    final text = '''
MediScan AI — Medical Report Analysis
Report: ${result.title}
Date: ${DateFormat('MMM d, yyyy').format(result.analyzedAt)}
Type: ${result.reportType}
Risk Level: ${result.riskLevel.label}

SUMMARY:
${result.summary}

SUMMARY (Urdu):
${result.summaryUrdu ?? '-'}

FINDINGS:
${result.findings.map((f) => '• ${f.parameter}: ${f.value} (${f.status.label})').join('\n')}

RECOMMENDATIONS:
${result.recommendations.map((r) => '• $r').join('\n')}

RECOMMENDATIONS (Urdu):
${(result.recommendationsUrdu ?? []).map((r) => '• $r').join('\n')}

⚠️ This AI analysis is for informational purposes only. Always consult a healthcare professional.
''';
    await Share.share(text, subject: 'Medical Report Analysis — ${result.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppTheme.textPrimary),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _share,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded,
                      size: 18, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Risk level card
                _buildRiskCard(),
                const SizedBox(height: 20),

                // Summary
                _buildSection(
                  title: 'AI Summary',
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppTheme.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.summary,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          height: 1.65,
                        ),
                      ),
                      if (result.summaryUrdu != null &&
                          result.summaryUrdu!.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'خلاصہ (اردو)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result.summaryUrdu!,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Findings
                if (result.findings.isNotEmpty) ...[
                  _buildSection(
                    title: 'Findings (${result.findings.length})',
                    icon: Icons.analytics_rounded,
                    iconColor: AppTheme.info,
                    child: Column(
                      children: result.findings
                          .asMap()
                          .entries
                          .map(
                            (e) => Padding(
                              padding: EdgeInsets.only(
                                  top: e.key > 0 ? 10 : 0),
                              child: FindingCard(finding: e.value)
                                  .animate(delay: (e.key * 80).ms)
                                  .slideX(begin: 0.1, end: 0, duration: 300.ms)
                                  .fadeIn(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Recommendations
                if (result.recommendations.isNotEmpty ||
                    (result.recommendationsUrdu != null &&
                        result.recommendationsUrdu!.isNotEmpty)) ...[
                  _buildSection(
                    title: 'Recommendations',
                    icon: Icons.lightbulb_rounded,
                    iconColor: AppTheme.accentWarm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (result.recommendations.isNotEmpty)
                          Column(
                            children: result.recommendations
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: EdgeInsets.only(
                                        top: e.key > 0 ? 10 : 0),
                                    child:
                                        _buildRecommendation(e.key + 1, e.value)
                                            .animate(
                                      delay: (e.key * 80).ms,
                                    )
                                            .slideX(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 300.ms,
                                    )
                                            .fadeIn(),
                                  ),
                                )
                                .toList(),
                          ),
                        if (result.recommendationsUrdu != null &&
                            result.recommendationsUrdu!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'سفارشات (اردو)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: result.recommendationsUrdu!
                                .asMap()
                                .entries
                                .map(
                                  (e) => Padding(
                                    padding: EdgeInsets.only(
                                        top: e.key > 0 ? 6 : 0),
                                    child: Text(
                                      '• ${e.value}',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Disclaimer
                _buildDisclaimer(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final riskColor = _riskColor(result.riskLevel);
    final gradient = _riskGradient(result.riskLevel);

    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                riskColor.withOpacity(0.15),
                AppTheme.bgDark,
              ],
            ),
          ),
        ),

        // Report image if available
        if (result.imagePath != null)
          Positioned(
            right: -20,
            top: 40,
            child: Opacity(
              opacity: 0.15,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(result.imagePath!),
                  width: 200,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(72, 12, 72, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RiskBadge(level: result.riskLevel, gradient: gradient),
                const SizedBox(height: 8),
                Text(
                  result.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppTheme.textMuted),
                    Text(
                      DateFormat('MMM d, yyyy • h:mm a')
                          .format(result.analyzedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        result.reportType,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard() {
    final color = _riskColor(result.riskLevel);
    final gradient = _riskGradient(result.riskLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                result.riskLevel.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Risk Level',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.riskLevel.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.findings.where((f) => f.status == FindingStatus.normal).length}/${result.findings.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Normal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95), duration: 400.ms).fadeIn();
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRecommendation(int number, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentWarm.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentWarm.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.accentWarm, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This AI analysis is for informational purposes only and should not replace professional medical advice. Please consult a qualified healthcare provider for diagnosis and treatment decisions.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.accentWarm.withOpacity(0.8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
