import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _apiKeyController = TextEditingController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _obscureKey = true;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.document_scanner_rounded,
      gradient: AppTheme.heroGradient,
      title: 'Scan Any\nMedical Report',
      subtitle:
          'Upload blood tests, X-rays, MRIs, ECGs, and more. MediScan reads and understands them all.',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      gradient: AppTheme.successGradient,
      title: 'AI-Powered\nAnalysis',
      subtitle:
          'GPT-4o Vision analyzes your reports with expert-level precision and explains findings in plain language.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF5E5CE6), Color(0xFF9B59B6)],
      ),
      title: 'Private &\nSecure',
      subtitle:
          'Your reports are never stored on our servers. Analysis is done directly via OpenAI\'s encrypted API.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty || !key.startsWith('sk-')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid OpenAI API key (starts with sk-)',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await StorageService().saveApiKey(key);
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Page View ───────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length + 1, // +1 for API key screen
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  if (i < _pages.length) {
                    return _buildOnboardingPage(_pages[i]);
                  }
                  return _buildApiKeyPage();
                },
              ),
            ),

            // ── Dots + Button ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length + 1,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppTheme.primary
                              : AppTheme.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  if (_currentPage < _pages.length)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: page.gradient,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(page.icon, size: 60, color: Colors.white),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.elasticOut,
                duration: 700.ms,
              )
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 48),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ).animate(delay: 200.ms).slideY(begin: 0.3, end: 0, duration: 500.ms).fadeIn(),

          const SizedBox(height: 20),

          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ).animate(delay: 350.ms).slideY(begin: 0.3, end: 0, duration: 500.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildApiKeyPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.key_rounded, color: Colors.white, size: 28),
          ).animate().scale(begin: const Offset(0.8, 0.8), duration: 500.ms).fadeIn(),

          const SizedBox(height: 24),

          Text(
            'Connect\nOpenAI',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ).animate(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),

          const SizedBox(height: 12),

          Text(
            'Enter your OpenAI API key to enable AI-powered medical report analysis.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ).animate(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),

          const SizedBox(height: 36),

          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'OpenAI API Key',
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  color: AppTheme.textMuted,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ).animate(delay: 300.ms).slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),

          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Get your API key at platform.openai.com. GPT-4o with vision access required.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Start Analyzing',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ).animate(delay: 500.ms).slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
  });
}
