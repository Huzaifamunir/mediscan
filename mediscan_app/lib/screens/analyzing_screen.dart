import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/openai_service.dart';
import '../services/ad_service.dart';
import '../models/analysis_result.dart';

class AnalyzingScreen extends StatefulWidget {
  final File file;
  final bool isPdf;
  final OpenAIService service;
  final Function(AnalysisResult) onComplete;
  final VoidCallback? onNotMedicalReport;

  const AnalyzingScreen({
    super.key,
    required this.file,
    required this.isPdf,
    required this.service,
    required this.onComplete,
    this.onNotMedicalReport,
  });

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;

  int _stepIndex = 0;
  String? _error;

  final _steps = [
    'Validating document...',
    'Reading document...',
    'Identifying report type...',
    'Analyzing findings...',
    'Evaluating parameters...',
    'Generating insights...',
    'Preparing report...',
  ];

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Preload app open ad so it's ready when user returns
    AdService().loadAppOpenAd();

    _startStepCycle();
    _analyze();
  }

  void _startStepCycle() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return false;
      setState(() {
        _stepIndex = (_stepIndex + 1) % _steps.length;
      });
      return true;
    });
  }

  Future<void> _analyze() async {
    try {
      AnalysisResult result;
      if (widget.isPdf) {
        // PDFs are assumed to be medical documents — skip image check
        result = await widget.service.analyzeTextReport(
          'PDF medical report - please analyze based on available information',
          pdfPath: widget.file.path,
        );
      } else {
        // Validate that the image is a medical report before full analysis
        final isMedical =
            await widget.service.checkIsMedicalReport(widget.file);
        if (!mounted) return;
        if (!isMedical) {
          Navigator.pop(context);
          widget.onNotMedicalReport?.call();
          return;
        }
        result = await widget.service.analyzeImageReport(widget.file);
      }
      if (mounted) {
        widget.onComplete(result);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final message = e.message;
        final type = e.type;
        setState(() {
          if (status != null) {
            _error = 'Request failed with status $status\nResponse: $data';
          } else {
            _error = 'Network error ($type): $message';
          }
        });
      } else {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.6 + _pulseController.value * 0.2,
                    colors: [
                      AppTheme.primary.withOpacity(0.08 + _pulseController.value * 0.04),
                      AppTheme.bgDark,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _error != null ? _buildError() : _buildAnalyzing(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),

        // Animated AI brain
        AnimatedBuilder(
          animation: _rotateController,
          builder: (_, child) => Transform.rotate(
            angle: _rotateController.value * 2 * 3.14159,
            child: child,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppTheme.primary,
                  AppTheme.accent,
                  AppTheme.primary.withOpacity(0.3),
                  AppTheme.primary,
                ],
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgDark,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: AppTheme.primary,
                size: 52,
              ),
            ),
          ),
        ),

        const SizedBox(height: 48),

        Text(
          'Analyzing Report',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _steps[_stepIndex],
            key: ValueKey(_stepIndex),
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _steps.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _stepIndex ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _stepIndex
                    ? AppTheme.primary
                    : AppTheme.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        const SizedBox(height: 64),

        // Preview of selected file
        if (!widget.isPdf)
          Container(
            width: 180,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(widget.file, fit: BoxFit.cover),
            ),
          ).animate(delay: 200.ms).scale(begin: const Offset(0.8, 0.8), duration: 500.ms).fadeIn(),

        const Spacer(),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(
                'Your data is securely processed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.danger.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: AppTheme.danger, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Analysis Failed',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _error ?? 'An unexpected error occurred.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text('Go Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
        ),
      ],
    );
  }
}
