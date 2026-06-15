import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../models/analysis_result.dart';
import '../widgets/upload_option_card.dart';
import '../widgets/gradient_button.dart';
import 'analysis_screen.dart';
import 'analyzing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedFile;
  String? _selectedFileName;
  bool _isPdf = false;

  BannerAd? _bannerAd;
  bool _bannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerAdReady = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() {
      _selectedFile = File(picked.path);
      _selectedFileName = picked.name;
      _isPdf = false;
    });
  }

  Future<void> _captureFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() {
      _selectedFile = File(picked.path);
      _selectedFileName = picked.name;
      _isPdf = false;
    });
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _selectedFile = File(result.files.single.path!);
      _selectedFileName = result.files.single.name;
      _isPdf = true;
    });
  }

  Future<void> _analyze() async {
    if (_selectedFile == null) {
      _showError('Please select a file to analyze.');
      return;
    }

    // Show ad first, then start analysis after it is dismissed
    AdService().showAppOpenAd(onDismissed: _startAnalysis);
  }

  void _startAnalysis() {
    if (!mounted) return;
    final storage = StorageService();
    final service = OpenAIService();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzingScreen(
          file: _selectedFile!,
          isPdf: _isPdf,
          service: service,
          onComplete: (result) async {
            await storage.saveResult(result);
            if (!mounted) return;
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AnalysisScreen(result: result)),
            );
          },
          onNotMedicalReport: () {
            _showError('Please upload a medical report');
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      bottomNavigationBar: _bannerAdReady && _bannerAd != null
          ? Container(
              color: AppTheme.bgDark,
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroHeader(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ── Upload options ─────────────────────────────────────────────
                Text(
                  'Choose Upload Method',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ).animate().slideX(begin: -0.1, end: 0, duration: 400.ms).fadeIn(),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: UploadOptionCard(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        description: 'Upload from photos',
                        gradient: AppTheme.heroGradient,
                        onTap: _pickFromGallery,
                      ).animate(delay: 100.ms).slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: UploadOptionCard(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        description: 'Capture report photo',
                        gradient: AppTheme.successGradient,
                        onTap: _captureFromCamera,
                      ).animate(delay: 200.ms).slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                UploadOptionCard(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF Document',
                  description: 'Upload a PDF medical report for analysis',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF453A), Color(0xFFFF8C00)],
                  ),
                  onTap: _pickPDF,
                  isWide: true,
                ).animate(delay: 300.ms).slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),

                const SizedBox(height: 28),

                // ── Selected file preview ──────────────────────────────────────
                if (_selectedFile != null) ...[
                  _buildFilePreview(),
                  const SizedBox(height: 20),
                ],

                // ── Analyze button ─────────────────────────────────────────────
                GradientButton(
                  label: 'Analyze Report',
                  icon: Icons.auto_awesome_rounded,
                  gradient: AppTheme.heroGradient,
                  onPressed: _selectedFile != null ? _analyze : null,
                ).animate(delay: 400.ms).slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),

                const SizedBox(height: 28),

                // ── What we can analyze ────────────────────────────────────────
                _buildSupportedReports(),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.bgDark, AppTheme.bgDark],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MediScan AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Upload your\nmedical report',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'AI analysis in seconds',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (!_isPdf)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedFile!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.danger,
                size: 32,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFileName ?? 'Selected file',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Ready to analyze',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _selectedFile = null;
              _selectedFileName = null;
            }),
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.textMuted, size: 20),
          ),
        ],
      ),
    ).animate().scale(begin: const Offset(0.95, 0.95), duration: 300.ms).fadeIn();
  }

  Widget _buildSupportedReports() {
    final types = [
      ('🩸', 'Blood Tests'),
      ('🫁', 'X-Rays'),
      ('🧠', 'MRI Scans'),
      ('❤️', 'ECG / EKG'),
      ('🔬', 'Pathology'),
      ('💊', 'Prescriptions'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supported Reports',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types
              .map(
                (t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.$1, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        t.$2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
