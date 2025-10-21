import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../objectBox/Entity.dart';
import 'StaffProvider.dart';

class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // fond sombre en dégradé comme sur la maquette
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1216), Color(0xFF0A0E12)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: GridView.count(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 0.65,
                children: const [
                  CardBtn(
                    title: 'Collarless Faux\nSuede Jacket',
                    nombrePersonne: null,
                    imageUrl:
                        'https://images.unsplash.com/photo-1544006659-f0b21884ce1d?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x6636E3FF), Color(0x6613D6B4)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.centerLeft,
                  ),
                  CardBtn(
                    title: 'Mens Washed\nOversized Hoodie',
                    nombrePersonne: 256,
                    imageUrl:
                        'https://images.unsplash.com/photo-1516280030429-27679b3dc9cf?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x66B4FFDE), Color(0x66FFE38F)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.centerRight,
                  ),
                  CardBtn(
                    title: 'Mens Washed\nOversized Hoodie',
                    nombrePersonne: 128,
                    imageUrl:
                        'https://images.unsplash.com/photo-1542060748-10c28b62716b?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x66B7C6FF), Color(0x339AA6B2)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.topCenter,
                    grayscaleImage: true,
                  ),
                  CardBtn(
                    title: 'Mens Washed\nOversized Hoodie',
                    nombrePersonne: null,
                    imageUrl:
                        'https://images.unsplash.com/photo-1520975922373-a83ca6c0557a?q=80&w=1200&auto=format&fit=crop',
                    overlayColors: [Color(0x66FF9D3C), Color(0x33F3D2C1)],
                    buttonLabel: 'Buy Now',
                    imageAlignment: Alignment.center,
                    warmGlow: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardBtn extends StatelessWidget {
  final String title;
  final int? nombrePersonne;
  final String imageUrl;
  final List<Color> overlayColors;
  final String buttonLabel;
  final Alignment imageAlignment;
  final bool grayscaleImage;
  final bool warmGlow;
  final VoidCallback? onPressed;

  const CardBtn({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.overlayColors,
    required this.buttonLabel,
    this.nombrePersonne = 0,
    this.imageAlignment = Alignment.center,
    this.grayscaleImage = false,
    this.warmGlow = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;

        // 🔹 Ratio hauteur/largeur pour conserver le même look visuel
        final double aspectRatio = isMobile ? 1.1 : 0.75;

        // 🔹 Ajustement des tailles
        final double fontSizeTitle = isMobile ? 14 : 18;
        final double personFontSize = isMobile ? 22 : 34;
        final double padding = isMobile ? 10 : 18;
        final double blur = isMobile ? 8 : 16;
        final BorderRadius radius = BorderRadius.circular(isMobile ? 20 : 28);

        return AspectRatio(
          aspectRatio: aspectRatio, // ✅ Maintient la proportion visuelle
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: radius),
            margin: const EdgeInsets.all(8),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 40,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 🔹 Image
                      ColorFiltered(
                        colorFilter: grayscaleImage
                            ? const ColorFilter.matrix(<double>[
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0.2126,
                                0.7152,
                                0.0722,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ])
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.dst),
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(imageUrl),
                              fit: BoxFit.cover,
                              alignment: imageAlignment,
                            ),
                          ),
                        ),
                      ),

                      // 🔹 Glow chaud optionnel
                      if (warmGlow)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topCenter,
                              radius: 1.2,
                              colors: [Color(0xFFFFB066), Colors.transparent],
                              stops: [0.0, 0.9],
                            ),
                          ),
                        ),

                      // 🔹 Dégradé d’overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: overlayColors,
                          ),
                        ),
                      ),

                      // 🔹 Assombrissement pour contraste
                      Container(color: const Color(0x14000000)),

                      // 🔹 Contenu texte + bouton
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding:
                              EdgeInsets.fromLTRB(padding, 0, padding, padding),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(isMobile ? 16 : 22),
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                              child: Container(
                                padding: EdgeInsets.fromLTRB(
                                    padding, padding, padding, padding / 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(isMobile ? 16 : 22),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontSizeTitle,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.black38,
                                              blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: isMobile ? 10 : 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _GlassButton(
                                            label: buttonLabel,
                                            isMobile: isMobile),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 🔹 Nombre de personnes
                      if (nombrePersonne != null && nombrePersonne != 0)
                        Positioned(
                          top: isMobile ? 8 : 18,
                          left: isMobile ? 8 : 18,
                          child: Text(
                            '${nombrePersonne!} ${nombrePersonne! <= 1 ? 'Person' : 'Persons'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: personFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 12)
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
      },
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final bool isMobile;

  const _GlassButton({
    required this.label,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 8,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              color: Colors.white.withOpacity(0.22),
              border: Border.all(color: Colors.white.withOpacity(0.30)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StaffBranchText extends StatefulWidget {
  final Staff staff;
  final BranchProvider provider;

  const StaffBranchText({
    Key? key,
    required this.staff,
    required this.provider,
  }) : super(key: key);

  @override
  State<StaffBranchText> createState() => _StaffBranchTextState();
}

class _StaffBranchTextState extends State<StaffBranchText> {
  Future<void> _showBranchDialog() async {
    final provider = widget.provider;
    final TextEditingController newBranchController = TextEditingController();
    Branch? selectedBranch;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Sélectionner ou créer une branche'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Dropdown de sélection existante
                DropdownButtonFormField<Branch>(
                  decoration: const InputDecoration(
                    labelText: 'Branche existante',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedBranch,
                  items: provider.branches.map((branch) {
                    return DropdownMenuItem(
                      value: branch,
                      child: Text(branch.branchNom),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedBranch = value),
                ),
                const SizedBox(height: 16),
                const Text('OU'),
                const SizedBox(height: 16),
                // 🔹 Champ pour créer une nouvelle branche
                TextField(
                  controller: newBranchController,
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle branche',
                    hintText: 'Ex: Médecins, Infirmiers...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // ✅ Si nouvelle branche
                  final newName = newBranchController.text.trim();
                  if (newName.isNotEmpty) {
                    await provider.addBranch(newName);
                    selectedBranch = provider.branches.last;
                  }

                  // ✅ Si une branche est sélectionnée (nouvelle ou existante)
                  if (selectedBranch != null) {
                    await provider.assignBranchToStaff(
                        widget.staff, selectedBranch!);
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Valider'),
              ),
            ],
          ),
        );
      },
    );

    newBranchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchName = widget.staff.branch.target?.branchNom;

    if (branchName != null) {
      return Text(
        'Service : ${branchName.toUpperCase()}',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
        textAlign: TextAlign.center,
      );
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
        children: [
          const TextSpan(text: 'Service : '),
          TextSpan(
            text: 'non identifié',
            style: const TextStyle(
              color: Colors.red,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = _showBranchDialog,
          ),
        ],
      ),
    );
  }
}

/// Widget réutilisable pour badge sur icône
class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? badgeColor;

  const BadgeIcon({
    Key? key,
    required this.icon,
    required this.count,
    this.onPressed,
    this.tooltip,
    this.badgeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
