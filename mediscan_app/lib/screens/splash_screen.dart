import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadVersion();
    _navigate();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version}');
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // ── Background radial glow ───────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8 + _pulseController.value * 0.2,
                    colors: [
                      AppTheme.primary.withOpacity(0.15),
                      AppTheme.bgDark,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Grid pattern overlay ─────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),

          // ── Center content ───────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container
           // Logo container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      curve: Curves.elasticOut,
                      duration: 900.ms,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // App name
                Text(
                  'MediScan AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.0,
                  ),
                )
                    .animate(delay: 400.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut, duration: 600.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 8),

                Text(
                  'Smart Medical Report Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate(delay: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut, duration: 600.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: 64),

                // Loading indicator
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    backgroundColor: AppTheme.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // ── Bottom tagline ───────────────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Powered by Codify',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _version,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.textMuted.withOpacity(0.6),
                  ),
                ),
              ],
            )
                .animate(delay: 1000.ms)
                .fadeIn(duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
