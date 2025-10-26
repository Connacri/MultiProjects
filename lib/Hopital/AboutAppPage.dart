import 'package:flutter/material.dart';
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
  late Animation<Offset> _slideAnimation;
  final Uri _walletDzUri = Uri.parse('https://walletdz-d12e0.web.app/');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // App Bar personnalisée
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'À Propos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.cyan.withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.medical_services,
                            size: 80,
                            color: Colors.cyan.shade300,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Contenu
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Section Logiciel
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildSectionTitle(
                                  'Medical Staff Planning\nBlockchain-Powered\nDecentralized Storage & Messaging',
                                  Icons.app_settings_alt_rounded,
                                ),
                                SizedBox(height: 20),
                                _buildInfoRow(
                                  Icons.code,
                                  'Version',
                                  '1.0.2',
                                ),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Date de sortie',
                                  'Octobre 2025',
                                ),
                                SizedBox(height: 15),
                                Text(
                                  'Solution professionnelle de gestion et planification du personnel médical et paramédical pour les établissements hospitaliers.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Fonctionnalités
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildSectionTitle(
                                  'Fonctionnalités Principales',
                                  Icons.stars_rounded,
                                ),
                                SizedBox(height: 20),
                                _buildFeature(
                                  Icons.schedule,
                                  'Planification automatique',
                                  'Gestion intelligente des gardes et rotations',
                                ),
                                _buildFeature(
                                  Icons.people_alt,
                                  'Gestion du personnel',
                                  'Suivi complet des équipes médicales',
                                ),
                                _buildFeature(
                                  Icons.event_busy,
                                  'Gestion des congés',
                                  'Système avancé de TimeOff',
                                ),
                                _buildFeature(
                                  Icons.picture_as_pdf,
                                  'Export PDF',
                                  'Génération de plannings professionnels',
                                ),
                                _buildFeature(
                                  Icons.analytics,
                                  'Statistiques',
                                  'Tableaux de bord et rapports',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Section Développeur
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildSectionTitle(
                                  'Project Local @Blockchain-Powered\nDecentralized Storage Database',
                                  Icons.person_rounded,
                                ),
                                SizedBox(height: 20),
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.cyan.shade400,
                                        Colors.blue.shade600,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyan.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'RG',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Ramzi Guedouar',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Full-Stack DevOps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.cyan.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Section Entreprise
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildSectionTitle(
                                  'FORSLOG LTD',
                                  Icons.business_rounded,
                                ),
                                SizedBox(height: 20),
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.cyan.withOpacity(0.2),
                                        Colors.blue.withOpacity(0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.cyan.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.apartment_rounded,
                                        size: 50,
                                        color: Colors.cyan.shade300,
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        'Solutions logicielles décentralisées pour une santé connectée et sécurisée',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Section Contact
                          _buildGlassCard(
                            child: Column(
                              children: [
                                _buildSectionTitle(
                                  'Contact',
                                  Icons.contact_mail_rounded,
                                ),
                                SizedBox(height: 20),
                                _buildContactButton(
                                  Icons.phone,
                                  '+213 696 410 953',
                                  'tel:+213696410953',
                                  Colors.green,
                                ),
                                SizedBox(height: 12),
                                _buildContactButton(
                                  Icons.email,
                                  'ramzi.guedouar@gmail.com',
                                  'mailto:ramzi.guedouar@gmail.com',
                                  Colors.red,
                                ),
                                SizedBox(height: 12),
                                _buildContactButton(
                                  Icons.location_on,
                                  'Oran, Algérie',
                                  'https://maps.app.goo.gl/PpmeqfinpKZcErDk8',
                                  Colors.blue,
                                ),
                                SizedBox(height: 12),
                                TextButton(
                                  onPressed: openWalletDZ,
                                  child: const Text('Ouvrir WalletDZ'),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // // Technologies utilisées
                          // _buildGlassCard(
                          //   child: Column(
                          //     children: [
                          //       _buildSectionTitle(
                          //         'Technologies',
                          //         Icons.code_rounded,
                          //       ),
                          //       SizedBox(height: 20),
                          //       Wrap(
                          //         spacing: 10,
                          //         runSpacing: 10,
                          //         alignment: WrapAlignment.center,
                          //         children: [
                          //           _buildTechChip('Flutter', Colors.blue),
                          //           _buildTechChip('Dart', Colors.cyan),
                          //           _buildTechChip('ObjectBox', Colors.green),
                          //           _buildTechChip('PDF', Colors.red),
                          //           _buildTechChip(
                          //               'Material Design', Colors.purple),
                          //         ],
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          //
                          // SizedBox(height: 30),

                          // Footer
                          Text(
                            '© 2025 FORSLOG LTD. Tous droits réservés.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Proudly crafted with in Oran 🇩🇿',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.cyan.shade200,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.cyan.shade300,
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyan.shade300, size: 20),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.cyan.shade300,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(
    IconData icon,
    String text,
    String url,
    Color color,
  ) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> openWalletDZ() async {
    // Essaie d’ouvrir avec le comportement par défaut de la plateforme.
    final ok = await launchUrl(
      _walletDzUri,
      mode: LaunchMode.platformDefault,
      // externe sur desktop/mobile, nouvel onglet sur web
      webOnlyWindowName: '_blank', // ouvre un nouvel onglet sur Flutter Web
    );
    if (!ok) {
      // Fallback explicite : forcer l’ouverture externe (utile sur desktop)
      final okExternal = await launchUrl(
        _walletDzUri,
        mode: LaunchMode.externalApplication,
      );
      if (!okExternal) {
        throw 'Impossible d’ouvrir ${_walletDzUri.toString()}';
      }
    }
  }
}
