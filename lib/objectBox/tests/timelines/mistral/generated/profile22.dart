import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../../../Entity.dart';
import '../claude_crud.dart';
import '../provider_hotel.dart';
import '../widgets.dart';

class Profile22 extends StatefulWidget {
  final Room? preselectedRoom;
  final DateTime? preselectedDate;
  final Hotel currentHotel;
  final HotelProvider provider;
  final BuildContext parentContext;
  final VoidCallback onReservationAdded;
  final bool isEditing;
  final Reservation? existingReservation;
  final List<SeasonalPricing> seasonalPricings;

  const Profile22({
    Key? key,
    required this.preselectedRoom,
    required this.preselectedDate,
    required this.currentHotel,
    required this.provider,
    required this.parentContext,
    required this.onReservationAdded,
    required this.isEditing,
    required this.existingReservation,
    required this.seasonalPricings,
  }) : super(key: key);

  @override
  State<Profile22> createState() => _Profile22State();
}

class _Profile22State extends State<Profile22> {
  final _formKey = GlobalKey<FormState>();
  final _guestController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  bool _isPriceManuallyEdited = false;
  SeasonalPricing? _selectedSeasonalPricing;
  Room? _selectedRoom;
  Employee? _selectedEmployee;
  List<Guest> _selectedGuests = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  String _status = "Confirmed";
  bool _isLoading = false;

  // Board Basis and Extra Services
  BoardBasis? _selectedBoardBasis;
  List<ReservationExtraItem> _selectedExtras = [];

  List<SeasonalPricing> _seasonalPricings = [];
  late double _seasonalMultiplier;

// Ajouter après les contrôleurs existants
  final _discountPercentController = TextEditingController();
  final _discountAmountController = TextEditingController();

// Ajouter les variables pour la réduction
  double _discountPercent = 0.0;
  double _discountAmount = 0.0;
  String _discountType = 'percentage'; // 'percentage' ou 'amount'
  String _discountAppliedTo =
      'total'; // 'room', 'board', 'extras', 'total', 'specific'
  List<String> _selectedDiscountItems = [];

  @override
  void initState() {
    super.initState();

    // Valeur par défaut sûre
    _seasonalMultiplier = 1.0;

    // ❌ SUPPRIMER CETTE LIGNE - Elle cause l'erreur
    // final provider = Provider.of<HotelProvider>(context, listen: false);

    // ✅ UTILISER LE PROVIDER PASSÉ EN PARAMÈTRE
    final provider = widget.provider; // Utiliser le provider déjà fourni

    // 1) Affecter la liste des tarifs saisonniers AVANT toute sélection
    _seasonalPricings = widget.seasonalPricings ?? [];

    // 2) Pré-sélectionner : prioriser le choix global du provider si présent
    final activeSeason = provider.selectedSeasonalPricing;

    if (activeSeason != null) {
      _selectedSeasonalPricing = activeSeason;
      _seasonalMultiplier = activeSeason.multiplier;
    } else {
      _preselectSeasonalByToday();
    }

    // Initialisation spécifique EDIT / NEW
    if (widget.isEditing && widget.existingReservation != null) {
      _initializeForEdit();
    }

    // Créer _priceController une seule fois et avec texte initial éventuel
    _priceController = TextEditingController(
      text: widget.isEditing && widget.existingReservation != null
          ? widget.existingReservation!.pricePerNight.toString()
          : (_selectedRoom != null ? '' : ''),
    );

    _discountPercentController.text = _discountPercent.toString();
    _discountAmountController.text = _discountAmount.toString();
  }

  void _preselectSeasonalByToday() {
    final now = DateTime.now();

    if (_seasonalPricings.isEmpty) {
      _selectedSeasonalPricing = null;
      _seasonalMultiplier = 1.0;
      return;
    }

    final selected = _seasonalPricings.firstWhere(
      (s) => s.isActive && s.isDateInSeason(now),
      orElse: () => _seasonalPricings.first,
    );

    _selectedSeasonalPricing = selected;
    _seasonalMultiplier = selected.multiplier;
  }

  void _initializeForEdit() {
    final reservation = widget.existingReservation!;
// Ajouter après l'initialisation du prix
    _discountPercent = reservation.discountPercent;
    _discountAmount = reservation.discountAmount;
    _discountPercentController.text = _discountPercent.toString();
    _discountAmountController.text = _discountAmount.toString();
    // NOUVEAU : Récupérer le type et l'application
    _discountType = reservation.discountType ?? 'percentage';
    _discountAppliedTo = reservation.discountAppliedTo ?? 'total';
    // Si c'est des éléments spécifiques, décoder la liste
    if (_discountAppliedTo == 'specific' &&
        reservation.selectedDiscountItems!.isNotEmpty) {
      try {
        _selectedDiscountItems =
            List<String>.from(jsonDecode(reservation.selectedDiscountItems!));
      } catch (e) {
        _selectedDiscountItems = [];
      }
    }
    // Initialisation des objets existants
    final roomId = reservation.room.target?.id;
    _selectedRoom = roomId != null
        ? widget.currentHotel.rooms
            .cast<Room?>()
            .firstWhere((room) => room?.id == roomId, orElse: () => null)
        : null;

    final employeeId = reservation.receptionist.target?.id;
    _selectedEmployee = employeeId != null
        ? widget.provider.employees
            .cast<Employee?>()
            .firstWhere((emp) => emp?.id == employeeId, orElse: () => null)
        : null;

    _selectedGuests = reservation.guests.toList();
    _fromDate = reservation.from;
    _toDate = reservation.to;
    _status = reservation.status;
    _priceController.text = reservation.pricePerNight.toString();

    // CORRECTION: Récupération du BoardBasis
    if (reservation.boardBasis.target != null) {
      _selectedBoardBasis = reservation.boardBasis.target;
    }

    // CORRECTION: Récupération des extras avec mapping correct
    if (_selectedExtras.isEmpty) {
      _selectedExtras = reservation.extras
          .map((re) => ReservationExtraItem(
                extraService: re.extraService.target!,
                quantity: re.quantity,
                unitPrice: re.unitPrice,
                scheduledDate: re.scheduledDate,
              ))
          .toList();
    }

    //////////////*************************************************************
    final reservationSeasonal =
        widget.existingReservation!.seasonalPricing.target!.multiplier;

    _seasonalMultiplier = reservationSeasonal;
    _selectedSeasonalPricing =
        widget.existingReservation!.seasonalPricing.target!;

    //////////////*************************************************************
    // Calculer les prix des extras après initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllExtraPrices();
      _selectedSeasonalPricing =
          widget.existingReservation!.seasonalPricing.target!;
    });
  }

  void _updateAllExtraPrices() {
    setState(() {
      for (final extra in _selectedExtras) {
        _updateExtraPrice(extra);
      }
    });
  }

  void _updateExtraPrice(ReservationExtraItem item) {
    if (_fromDate != null && _toDate != null) {
      final nights = _toDate!.difference(_fromDate!).inDays;
      final persons = _selectedGuests.length;
      final roomPrice = double.tryParse(_priceController.text) ?? 0.0;

      item.totalPrice = item.extraService
          .calculatePrice(item.quantity, roomPrice, nights, persons);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gradientStart = Colors.transparent;
    const Color gradientEnd = Color(0xFFFE4164);

    final List<String> thumbs = [
      'assets/photos/a (2).png',
      'assets/photos/a (4).png',
      'assets/photos/a (5).png',
      'assets/photos/a (6).png',
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero, // ✅ occupe tout l’écran
      child: Stack(
        children: [
          // 1) Image plein écran
          SizedBox.expand(
            child: Image.asset(
              'assets/photos/a (11).png',
              fit: BoxFit.cover, // ✅ couvre toute la surface
            ),
          ),

          // 2) Overlay dégradé
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientStart, gradientEnd],
                ),
              ),
            ),
          ),

          // 3) Contenu
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 24),
                      ),
                      // const SizedBox(width: 12),
                      // const Text(
                      //   'Candidates',
                      //   style: TextStyle(
                      //     color: Colors.white,
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                _buildBasicInfoSection(),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final List<Widget> chips = [];
                    double usedWidth = 0;
                    const double spacing = 6;
                    const double chipScale = 0.8;

                    // On réserve la largeur pour le chip "+X"
                    const double plusChipMinWidth = 50;

                    for (int i = 0; i < _selectedGuests.length; i++) {
                      final guest = _selectedGuests[i];

                      // Mesure du texte (largeur du label)
                      final painter = TextPainter(
                        text: TextSpan(
                          text: guest.fullName.capitalize,
                          style: const TextStyle(fontSize: 13),
                        ),
                        maxLines: 1,
                        textDirection: ui.TextDirection.ltr,
                      )..layout();

                      // Largeur estimée du chip (avatar + texte + padding)
                      double chipWidth = painter.width + 50;
                      chipWidth *= chipScale;

                      // Vérifie si on peut placer ce chip + au moins le chip "+X"
                      if (usedWidth + chipWidth + spacing + plusChipMinWidth >
                          constraints.maxWidth) {
                        final remaining = _selectedGuests.length - i;

                        // Ajout du chip "+X"
                        chips.add(
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(
                                      "Clients avec ${_selectedGuests.first.fullName} de ${_selectedRoom?.code ?? "—"}"),
                                  content: SizedBox(
                                    width: double.minPositive,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _selectedGuests.length,
                                      itemBuilder: (context, index) {
                                        final g = _selectedGuests[index];
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Colors.blue.shade100,
                                            child: Text(
                                              g.fullName
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                            ),
                                          ),
                                          title: Text(g.fullName.capitalize),
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClientDetailPage(guest: g),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Transform.scale(
                              scale: 0.8,
                              child: Chip(
                                backgroundColor: Colors.grey.shade300,
                                label: Text(
                                  "+$remaining",
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        );
                        break; // stop → on a placé "+X"
                      } else {
                        // Ajout du chip normal
                        chips.add(
                          Tooltip(
                            message: [
                              guest.fullName,
                              if (guest.phoneNumber.isNotEmpty)
                                guest.phoneNumber,
                              if (guest.idCardNumber.isNotEmpty)
                                guest.idCardNumber,
                            ].join('\n'),
                            child: Container(
                              child: InputChip(
                                avatar: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    guest.fullName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 10),
                                  ),
                                ),
                                label: Text(
                                  guest.fullName.capitalize,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.deepPurpleAccent,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClientDetailPage(guest: guest),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                        usedWidth += chipWidth + spacing;
                      }
                    }

                    return Row(
                      children: chips,
                    );
                  },
                ),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: thumbs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                          image: DecorationImage(
                            image: AssetImage(thumbs[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'NATASHA KORGEEVA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '23 years, Lisbon, Portugal',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'I’m a Digital Marketing Manager working in Lisbon. '
                        'I like to go out for drinks and fun, cinema, travel and beach :)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      color: Colors.transparent,
      child: Padding(
        padding:
            EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations de base',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: ColorScheme.of(context).onPrimary)),

            Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow99(
                      icon: Icons.person_4_outlined,
                      'Réception',
                      _selectedEmployee?.fullName ?? "—",
                      isHeader: true),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.person,
                            size: 17, color: Colors.grey.shade600),
                      ),
                      Text(
                        'Client:',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          color: ColorScheme.of(context).onPrimary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final List<Widget> chips = [];
                            double usedWidth = 0;
                            const double spacing = 6;
                            const double chipScale = 0.8;

                            // On réserve la largeur pour le chip "+X"
                            const double plusChipMinWidth = 50;

                            for (int i = 0; i < _selectedGuests.length; i++) {
                              final guest = _selectedGuests[i];

                              // Mesure du texte (largeur du label)
                              final painter = TextPainter(
                                text: TextSpan(
                                  text: guest.fullName.capitalize,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                maxLines: 1,
                                textDirection: ui.TextDirection.ltr,
                              )..layout();

                              // Largeur estimée du chip (avatar + texte + padding)
                              double chipWidth = painter.width + 50;
                              chipWidth *= chipScale;

                              // Vérifie si on peut placer ce chip + au moins le chip "+X"
                              if (usedWidth +
                                      chipWidth +
                                      spacing +
                                      plusChipMinWidth >
                                  constraints.maxWidth) {
                                final remaining = _selectedGuests.length - i;

                                // Ajout du chip "+X"
                                chips.add(
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(
                                              "Clients avec ${_selectedGuests.first.fullName} de ${_selectedRoom?.code ?? "—"}"),
                                          content: SizedBox(
                                            width: double.minPositive,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: _selectedGuests.length,
                                              itemBuilder: (context, index) {
                                                final g =
                                                    _selectedGuests[index];
                                                return ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blue.shade100,
                                                    child: Text(
                                                      g.fullName
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                    ),
                                                  ),
                                                  title: Text(
                                                      g.fullName.capitalize),
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ClientDetailPage(
                                                                guest: g),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Transform.scale(
                                      scale: 0.8,
                                      child: Chip(
                                        backgroundColor: Colors.grey.shade300,
                                        label: Text(
                                          "+$remaining",
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                break; // stop → on a placé "+X"
                              } else {
                                // Ajout du chip normal
                                chips.add(
                                  Tooltip(
                                    message: [
                                      guest.fullName,
                                      if (guest.phoneNumber.isNotEmpty)
                                        guest.phoneNumber,
                                      if (guest.idCardNumber.isNotEmpty)
                                        guest.idCardNumber,
                                    ].join('\n'),
                                    child: InputChip(
                                      avatar: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.blue.shade100,
                                        child: Text(
                                          guest.fullName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10),
                                        ),
                                      ),
                                      label: Text(
                                        guest.fullName.capitalize,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.deepPurpleAccent,
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ClientDetailPage(guest: guest),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                                usedWidth += chipWidth + spacing;
                              }
                            }

                            return Row(
                              children: chips,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  // _buildDetailRow99(
                  //     icon: Icons.bed,
                  //     'Chambre',
                  //     _selectedRoom!.code ?? '_',
                  //     isHeader: true),
                  SizedBox(
                    height: 8,
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12), // coins arrondis
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.deepPurple.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.bed,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _selectedRoom!.code ?? '_',
                          style: TextStyle(
                            color: Colors.white,
                            // direct au lieu de ColorScheme
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          '${_selectedRoom?.category.target?.name ?? "—"}',
                          style: TextStyle(
                            color: Colors.white,
                            // direct au lieu de ColorScheme
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dates
            Row(
              children: [
                Expanded(
                    child: _buildDateField(
                        FontAwesomeIcons.planeArrival, '  Arrived', _fromDate,
                        (date) {
                  setState(() {
                    _fromDate = date;
                    if (_toDate != null &&
                        _toDate!.isBefore(date.add(Duration(days: 1)))) {
                      _toDate = date.add(Duration(days: 1));
                    }
                    _updateAllExtraPrices();
                  });
                }, true)),
                SizedBox(width: 16),
                Expanded(
                    child: _buildDateField(
                        FontAwesomeIcons.planeDeparture, '  Départ', _toDate,
                        (date) {
                  setState(() {
                    _toDate = date;
                    _updateAllExtraPrices();
                  });
                }, false)),
              ],
            ),

            // ================= Price & Status Section =================
            Column(
              children: [
                SeasonalPricingCard2(
                  basePrice: _selectedRoom!.category.target!.basePrice,
                  imageUrl: 'assets/photos/a (15).png',
                  seasonalPricings: _seasonalPricings,
                  recentSeason: _selectedSeasonalPricing!,
                ),
                // _buildPriceFieldImproved(),
                const SizedBox(height: 8),
                IconTheme(
                  data: IconThemeData(
                      color: Theme.of(context).colorScheme.onSecondary),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary),
                    child: Row(
                      children: [
                        Icon(Icons.star),
                        const SizedBox(width: 5),
                        Text('Statut',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 5),
                        Expanded(child: Text(_status)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow99(String label, String value,
      {bool isHeader = false, bool isHighlighted = false, IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(icon, size: 17, color: Colors.grey.shade600),
            ),
          SizedBox(
            width: isHeader ? 85 : 100,
            child: Text('$label:',
                style: TextStyle(
                    fontWeight: isHeader ? FontWeight.w300 : FontWeight.w300,
                    fontSize: isHeader ? 13 : 12,
                    color: ColorScheme.of(context).onPrimary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.w400 : FontWeight.normal,
                fontSize: isHighlighted ? 17 : 13,
                color: Theme.of(context).primaryColorLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(icon, String label, DateTime? date,
      Function(DateTime) onDateSelected, bool departarrive) {
    return InkWell(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          // decoration: BoxDecoration(
          //   border: Border.all(color: Colors.grey[300]!),
          //   borderRadius: BorderRadius.circular(8),
          // ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: departarrive ? Colors.green[600] : Colors.red[600],
              ),
              SizedBox(width: 12),
              Text(
                date != null ? _formatDate(date) : 'Sélectionner',
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).secondaryHeaderColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceFieldImproved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage du prix de base de la chambre
        if (_selectedRoom?.category.target != null) ...[
          PriceCard22(
            basePrice: _selectedRoom!.category.target!.basePrice,
            seasonalMultiplier: _seasonalMultiplier,
            season: _selectedSeasonalPricing,
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
