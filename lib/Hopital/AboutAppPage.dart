import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({Key? key}) : super(key: key);

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final Uri _walletDzUri = Uri.parse('');//https://walletdz-d12e0.web.app/

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              'À Propos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            expandedHeight: 150,
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 800;
                        return Column(
                          children: [
                            _buildHeroSection(colorScheme, isDark),
                            const SizedBox(height: 32),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                        colorScheme, isDark, isWide),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildFeaturesSection(
                                        colorScheme, isDark),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildInfoCard(colorScheme, isDark, isWide),
                                  const SizedBox(height: 24),
                                  _buildFeaturesSection(colorScheme, isDark),
                                ],
                              ),
                            const SizedBox(height: 24),
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildDeveloperSection(
                                        colorScheme, isDark),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildQrSection(colorScheme, isDark),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildDeveloperSection(colorScheme, isDark),
                                  const SizedBox(height: 24),
                                  _buildQrSection(colorScheme, isDark),
                                ],
                              ),
                            const SizedBox(height: 24),
                            _buildContactSection(colorScheme, isDark, isWide),
                            const SizedBox(height: 48),
                            _buildFooter(colorScheme),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_rounded,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Medical Staff Planning',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Blockchain-Powered • Decentralized • Secure',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, bool isDark, bool isWide) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                colorScheme, 'Informations', Icons.info_outline_rounded),
            const SizedBox(height: 24),
            _buildDetailRow(colorScheme, 'Version', '1.0.8+14', Icons.vignette),
            _buildDetailRow(
                colorScheme, 'Build Date', 'Mai 2026', Icons.calendar_month),
            _buildDetailRow(
                colorScheme, 'Platform', 'Cross-Platform', Icons.devices),
            const SizedBox(height: 16),
            Text(
              'Une solution de pointe pour la gestion des ressources humaines dans le secteur hospitalier, intégrant des technologies de registre distribué pour une intégrité maximale des données.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(ColorScheme colorScheme, bool isDark) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                colorScheme, 'Fonctionnalités', Icons.auto_awesome_rounded),
            const SizedBox(height: 24),
            _buildFeatureItem(colorScheme, 'Planning Automatique',
                'Algorithmes d\'optimisation de gardes.', Icons.schedule),
            _buildFeatureItem(colorScheme, 'Stockage Décentralisé',
                'Sécurité accrue via IPFS/Blockchain.', Icons.security),
            _buildFeatureItem(colorScheme, 'Exports Professionnels',
                'Génération PDF haute fidélité.', Icons.picture_as_pdf),
            _buildFeatureItem(colorScheme, 'Analytique Avancée',
                'Tableaux de bord interactifs.', Icons.insights),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperSection(ColorScheme colorScheme, bool isDark) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSectionHeader(
                colorScheme, 'Développement', Icons.code_rounded),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(
                  'RG',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ramzi Guedouar',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Full-Stack DevOps Engineer',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Passionné par le Web3 et les architectures résilientes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorSection(ColorScheme colorScheme, bool isDark) {
    return Card(
      elevation: 0,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSectionHeader(
                colorScheme, 'Sponsoring', Icons.volunteer_activism_rounded),
            const SizedBox(height: 16),
            Text(
              'Soutenez le développement de ce projet innovant. Nous recherchons des partenaires pour propulser cette solution vers de nouveaux sommets.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onTertiaryContainer,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(10),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/qrcode/qr.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'QR Sponsoring Wimpay',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _launchUrl('mailto:ramzi.guedouar@gmail.com?subject=Sponsoring%20Medical%20Staff%20Planning'),
              icon: const Icon(Icons.handshake_rounded),
              label: const Text('Devenir Sponsor'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(ColorScheme colorScheme, bool isDark) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSectionHeader(
                colorScheme, 'Paiement Sécurisé', Icons.payments_rounded),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/qrcode/qr.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scannez pour payer via Wimpay CPA',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Solution de paiement mobile sécurisée',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _launchUrl(_walletDzUri.toString()),
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
              label: const Text('Ouvrir Wimpay'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(ColorScheme colorScheme, bool isDark, bool isWide) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSectionHeader(
                colorScheme, 'Contactez-nous', Icons.alternate_email_rounded),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildContactChip(
                  colorScheme,
                  'Téléphone',
                  '+213 696 410 953',
                  Icons.phone_rounded,
                  () => _launchUrl('tel:+213696410953'),
                ),
                _buildContactChip(
                  colorScheme,
                  'Email',
                  'ramzi.guedouar@gmail.com',
                  Icons.mail_rounded,
                  () => _launchUrl('mailto:ramzi.guedouar@gmail.com'),
                ),
                _buildContactChip(
                  colorScheme,
                  'Localisation',
                  'Oran, Algérie',
                  Icons.location_on_rounded,
                  () => _launchUrl('https://maps.app.goo.gl/PpmeqfinpKZcErDk8'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      ColorScheme colorScheme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.secondary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      ColorScheme colorScheme, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip(ColorScheme colorScheme, String label, String value,
      IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 24),
        Text(
          '© 2026 FORSLOG LTD. Tous droits réservés.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Propulsé par ',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'RMZ dev',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
