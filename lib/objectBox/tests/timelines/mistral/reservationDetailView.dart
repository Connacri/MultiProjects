import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/provider_hotel.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/widgets.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../../Entity.dart';
import 'ReservationDialogContent.dart';
import 'claude_crud.dart';
import 'generated/profile1.dart';
import 'generated/profile22.dart';
import 'generated/profile3.dart';

// Enhanced ReservationDialogContent with Board Basis and Extra Services integration
class ReservationDetailView extends StatefulWidget {
  final Room? preselectedRoom;
  final DateTime? preselectedDate;
  final Hotel currentHotel;
  final HotelProvider provider;
  final BuildContext parentContext;
  final VoidCallback onReservationAdded;
  final bool isEditing;
  final Reservation? existingReservation;
  final List<SeasonalPricing> seasonalPricings;

  const ReservationDetailView({
    Key? key,
    this.preselectedRoom,
    this.preselectedDate,
    required this.currentHotel,
    required this.provider,
    required this.parentContext,
    required this.onReservationAdded,
    this.isEditing = false,
    this.existingReservation,
    required this.seasonalPricings,
  }) : super(key: key);

  @override
  State<ReservationDetailView> createState() => _ReservationDetailViewState();
}

class _ReservationDetailViewState extends State<ReservationDetailView> {
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
    final provider = Provider.of<HotelProvider>(context, listen: false);
    // Valeur par défaut sûre
    _seasonalMultiplier = 1.0;

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
    } else {
      _initializeForNew();
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

  void _initializeForNew() {
    _selectedRoom = widget.preselectedRoom;
    _fromDate = widget.preselectedDate ?? DateTime.now();
    _toDate = _fromDate!.add(Duration(days: 1));

    // NOUVEAU: Initialiser le prix de base de la chambre sélectionnée
    if (_selectedRoom != null) {
      _updateRoomPrice();
    }

    // Set default board basis
    final defaultBoardBasis = widget.provider
        .getBoardBasisList()
        .where((bb) => bb.isActive && bb.code == 'RO')
        .firstOrNull;
    _selectedBoardBasis = defaultBoardBasis;
  }

  // Add/Remove Extra Services
  void _addExtraService(ExtraService service) {
    final existingIndex = _selectedExtras
        .indexWhere((item) => item.extraService.id == service.id);

    if (existingIndex != -1) {
      setState(() {
        _selectedExtras[existingIndex].quantity++;
        _updateExtraPrice(_selectedExtras[existingIndex]);
      });
    } else {
      final extraItem = ReservationExtraItem(
        extraService: service,
        quantity: 1,
        unitPrice: service.price,
      );
      _updateExtraPrice(extraItem);

      setState(() {
        _selectedExtras.add(extraItem);
      });
    }
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

  void _updateAllExtraPrices() {
    setState(() {
      for (final extra in _selectedExtras) {
        _updateExtraPrice(extra);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double w = constraints.maxWidth;

        if (w < 600) {
          return _buildMobileForm();
        } else if (w < 900) {
          return _buildTabletForm();
        } else {
          return _buildDesktopForm();
        }
      },
    );
  }

  // CORRECTION 7: Améliorer _buildDesktopForm pour inclure la section saisonnière
  Widget _buildDesktopForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildBasicInfoSection(),
                            SizedBox(height: 16),
                            _buildBoardBasisSection(),
                          ],
                        ),
                      ),

                      SizedBox(width: 16),
                      // Right Column
                      Expanded(
                        flex: 2,
                        child: Column(children: [
                          _buildExtraServicesSection(),
                          // Card(
                          //   child: Padding(
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 8, vertical: 16),
                          //     child: ListTile(
                          //         leading: CircleAvatar(
                          //           child: Text(
                          //               '${_selectedSeasonalPricing!.multiplier}x'),
                          //         ),
                          //         title: Text(_selectedSeasonalPricing!.name)),
                          //   ),
                          // ),
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 8, vertical: 16),
                          //   child: SeasonalPricingDropdown(
                          //     selectedValue: _selectedSeasonalPricing,
                          //     customSeasonalPricings: _seasonalPricings,
                          //     useLocalState: true,
                          //     savedSeason: _selectedSeasonalPricing,
                          //
                          //     onChanged:
                          //         _onSeasonalPricingChanged, // Utiliser le nouveau callback
                          //   ),
                          // ),
                          _buildDiscountSection(),
                        ]),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // CORRECTION: Placer la section saisonnière ici
                  _buildPricingSummary700(context),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildMobileForm() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBasicInfoSection(),
                  SizedBox(height: 16),
                  _buildBoardBasisSection(),
                  SizedBox(height: 16),
                  _buildGuestsSection(),
                  SizedBox(height: 16),
                  _buildExtraServicesSection(),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Text(
                              '${_selectedSeasonalPricing!.multiplier}x',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: FittedBox(
                              child: Text(
                                _selectedSeasonalPricing!.name.toUpperCase() ??
                                    'Pas de saison',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.blueGrey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // SeasonalPricingDropdown(
                  //   selectedValue: _selectedSeasonalPricing,
                  //   customSeasonalPricings: _seasonalPricings,
                  //   savedSeason: _selectedSeasonalPricing,
                  //   useLocalState: true,
                  //   onChanged: (SeasonalPricing? newValue) {
                  //     setState(() {
                  //       _selectedSeasonalPricing = newValue;
                  //       _seasonalMultiplier = newValue?.multiplier ?? 1.0;
                  //
                  //       // Mettre à jour le prix si pas édité manuellement
                  //       if (!_isPriceManuallyEdited) {
                  //         _updateRoomPrice();
                  //       }
                  //
                  //       _updateAllExtraPrices();
                  //     });
                  //   },
                  // ),
                  SizedBox(height: 16),
                  _buildDiscountSection(),
                  SizedBox(height: 16),
                  _buildPricingSummary600(context),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildTabletForm() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildBasicInfoSection(),
                            SizedBox(height: 16),
                            _buildBoardBasisSection(),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildGuestsSection(),
                            SizedBox(height: 16),
                            _buildExtraServicesSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Dans _buildDesktopForm(), _buildMobileForm(), et _buildTabletForm()
// Remplacer SeasonalPricingDropdown() par :

                  SeasonalPricingDropdown(
                    selectedValue: _selectedSeasonalPricing,
                    customSeasonalPricings: _seasonalPricings,
                    savedSeason: _selectedSeasonalPricing,
                    useLocalState: true,
                    onChanged: (SeasonalPricing? newValue) {
                      setState(() {
                        _selectedSeasonalPricing = newValue;
                        _seasonalMultiplier = newValue?.multiplier ?? 1.0;

                        // Mettre à jour le prix si pas édité manuellement
                        if (!_isPriceManuallyEdited) {
                          _updateRoomPrice();
                        }

                        _updateAllExtraPrices();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildPricingSummary700(context),
                  _buildDiscountSection(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.hotel, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Flexible(
                  // Utilise Flexible pour le texte
                  child: Text(
                    'Réservation Détail',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => Profile1(),
            )),
            icon: Icon(Icons.mediation, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              // 👉 Ouvre le dialog
              showProfileDialog22(context);
            },
            icon: Icon(Icons.mediation, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => Profile3(),
            )),
            icon: Icon(Icons.mediation, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void showProfileDialog22(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Profile22(
          preselectedRoom: widget.preselectedRoom,
          preselectedDate: widget.preselectedDate,
          currentHotel: widget.currentHotel,
          provider: widget.provider,
          parentContext: widget.parentContext,
          onReservationAdded: widget.onReservationAdded,
          isEditing: widget.isEditing,
          existingReservation: widget.existingReservation,
          seasonalPricings: widget.seasonalPricings),
    );
  }

  // 1. CORRECTION: Utiliser _calculateTotalPrice() dans _buildPricingSummary
  Widget _buildPricingSummary700(BuildContext context) {
    if (_fromDate == null || _toDate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Sélectionnez les dates pour voir le récapitulatif des prix',
          ),
        ),
      );
    }

    final nights = _toDate!.difference(_fromDate!).inDays;
    final persons = _selectedGuests.length;

    // UTILISER _calculateTotalPrice() au lieu de recalculer ici
    final grandTotal = _calculateTotalPrice();

    // Calcul des sous-totaux pour l'affichage
    final roomPricePerNight = _getEffectiveRoomPrice();
    final roomTotal = roomPricePerNight * nights;

    double boardBasisTotal = 0.0;
    if (_selectedBoardBasis != null) {
      boardBasisTotal = _selectedBoardBasis!.pricePerPerson * persons * nights;
    }

    double extrasTotal =
        _selectedExtras.fold(0.0, (sum, extra) => sum + extra.totalPrice);

    // Calculer les réductions appliquées
    double roomDiscount = 0.0;
    double boardDiscount = 0.0;
    double extrasDiscount = 0.0;
    double totalDiscount = 0.0;

    switch (_discountAppliedTo) {
      case 'room':
        roomDiscount = _calculateDiscount(roomTotal);
        break;
      case 'board':
        boardDiscount = _calculateDiscount(boardBasisTotal);
        break;
      case 'extras':
        extrasDiscount = _calculateDiscount(extrasTotal);
        break;
      case 'total':
        totalDiscount =
            _calculateDiscount(roomTotal + boardBasisTotal + extrasTotal);
        break;
      case 'specific':
        if (_selectedDiscountItems.contains('room')) {
          roomDiscount = _calculateDiscount(roomTotal);
        }
        if (_selectedDiscountItems.contains('board')) {
          boardDiscount = _calculateDiscount(boardBasisTotal);
        }
        for (int i = 0; i < _selectedExtras.length; i++) {
          final extra = _selectedExtras[i];
          if (_selectedDiscountItems
              .contains('extra_${extra.extraService.id}')) {
            extrasDiscount += _calculateDiscount(extra.totalPrice);
          }
        }
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif des prix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chambre
            _buildPriceRow600(
              '$nights Nuitée(s)                 ',
              '${roomTotal.toStringAsFixed(2)}',
            ),
            if (roomDiscount > 0)
              _buildPriceRow600(
                'Réduction chambre',
                '-${roomDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),

            // Multiplicateur saisonnier
            if (_seasonalMultiplier != 1.0)
              Container(
                color: Colors.deepPurple.shade100,
                child: _buildPriceRow600(
                  'Saison Indice ${((_seasonalMultiplier * 100) - 100).toStringAsFixed(2)}%',
                  '${(roomTotal - (roomTotal / _seasonalMultiplier)).toStringAsFixed(2)}',
                ),
              ),

            // Plan de pension
            if (_selectedBoardBasis != null) ...[
              _buildPriceRow600(
                '${_selectedBoardBasis!.name} ($persons personnes, $nights nuits)',
                '${boardBasisTotal.toStringAsFixed(2)}',
              ),
              if (boardDiscount > 0)
                _buildPriceRow600(
                  'Réduction pension',
                  '-${boardDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Services supplémentaires
            if (_selectedExtras.isNotEmpty) ...[
              _buildPriceRow600(
                'Services supplémentaires',
                '${extrasTotal.toStringAsFixed(2)}',
              ),
              if (extrasDiscount > 0)
                _buildPriceRow600(
                  'Réduction services',
                  '-${extrasDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Réduction totale
            if (totalDiscount > 0)
              _buildPriceRow600(
                'Réduction totale',
                '-${totalDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            const Divider(),
            _buildPriceRow600(
              'Total général',
              '${(roomTotal + boardBasisTotal + extrasTotal).toStringAsFixed(2)}',
              isTotal: true,
            ),
            const Divider(),
            _buildPriceRow2600(
              'Net à Payer',
              '${(grandTotal).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSummary600(BuildContext context) {
    if (_fromDate == null || _toDate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Sélectionnez les dates pour voir le récapitulatif des prix',
          ),
        ),
      );
    }

    final nights = _toDate!.difference(_fromDate!).inDays;
    final persons = _selectedGuests.length;

    // UTILISER _calculateTotalPrice() au lieu de recalculer ici
    final grandTotal = _calculateTotalPrice();

    // Calcul des sous-totaux pour l'affichage
    final roomPricePerNight = _getEffectiveRoomPrice();
    final roomTotal = roomPricePerNight * nights;

    double boardBasisTotal = 0.0;
    if (_selectedBoardBasis != null) {
      boardBasisTotal = _selectedBoardBasis!.pricePerPerson * persons * nights;
    }

    double extrasTotal =
        _selectedExtras.fold(0.0, (sum, extra) => sum + extra.totalPrice);

    // Calculer les réductions appliquées
    double roomDiscount = 0.0;
    double boardDiscount = 0.0;
    double extrasDiscount = 0.0;
    double totalDiscount = 0.0;

    switch (_discountAppliedTo) {
      case 'room':
        roomDiscount = _calculateDiscount(roomTotal);
        break;
      case 'board':
        boardDiscount = _calculateDiscount(boardBasisTotal);
        break;
      case 'extras':
        extrasDiscount = _calculateDiscount(extrasTotal);
        break;
      case 'total':
        totalDiscount =
            _calculateDiscount(roomTotal + boardBasisTotal + extrasTotal);
        break;
      case 'specific':
        if (_selectedDiscountItems.contains('room')) {
          roomDiscount = _calculateDiscount(roomTotal);
        }
        if (_selectedDiscountItems.contains('board')) {
          boardDiscount = _calculateDiscount(boardBasisTotal);
        }
        for (int i = 0; i < _selectedExtras.length; i++) {
          final extra = _selectedExtras[i];
          if (_selectedDiscountItems
              .contains('extra_${extra.extraService.id}')) {
            extrasDiscount += _calculateDiscount(extra.totalPrice);
          }
        }
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif des prix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chambre
            _buildPriceRow(
              '$nights Nuitée(s)                 ',
              '${roomTotal.toStringAsFixed(2)}',
            ),
            if (roomDiscount > 0)
              _buildPriceRow(
                'Réduction chambre',
                '-${roomDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),

            // Multiplicateur saisonnier
            if (_seasonalMultiplier != 1.0)
              Container(
                color: Colors.deepPurple.shade100,
                child: _buildPriceRow(
                  'Saison Indice ${((_seasonalMultiplier * 100) - 100).toStringAsFixed(2)}%',
                  '${(roomTotal - (roomTotal / _seasonalMultiplier)).toStringAsFixed(2)}',
                ),
              ),

            // Plan de pension
            if (_selectedBoardBasis != null) ...[
              _buildPriceRow(
                '${_selectedBoardBasis!.name} ($persons personnes, $nights nuits)',
                '${boardBasisTotal.toStringAsFixed(2)}',
              ),
              if (boardDiscount > 0)
                _buildPriceRow(
                  'Réduction pension',
                  '-${boardDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Services supplémentaires
            if (_selectedExtras.isNotEmpty) ...[
              _buildPriceRow(
                'Services supplémentaires',
                '${extrasTotal.toStringAsFixed(2)}',
              ),
              if (extrasDiscount > 0)
                _buildPriceRow(
                  'Réduction services',
                  '-${extrasDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Réduction totale
            if (totalDiscount > 0)
              _buildPriceRow(
                'Réduction totale',
                '-${totalDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            const Divider(),
            _buildPriceRow(
              'Total général',
              '${(roomTotal + boardBasisTotal + extrasTotal).toStringAsFixed(2)}',
              isTotal: true,
            ),

            const Divider(),
            _buildPriceRow2(
              'Net à Payer',
              '${grandTotal.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations de base',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow99(
                          icon: Icons.person_4_outlined,
                          'Réception',
                          _selectedEmployee!.fullName,
                          isHeader: true),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.person,
                                size: 20, color: Colors.grey.shade600),
                          ),
                          const Text(
                            'Client:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

                                for (int i = 0;
                                    i < _selectedGuests.length;
                                    i++) {
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
                                    final remaining =
                                        _selectedGuests.length - i;

                                    // Ajout du chip "+X"
                                    chips.add(
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text(
                                                  "Clients avec ${_selectedGuests.first.fullName} de ${_selectedRoom!.code}"),
                                              content: SizedBox(
                                                width: double.minPositive,
                                                child: ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      _selectedGuests.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final g =
                                                        _selectedGuests[index];
                                                    return ListTile(
                                                      leading: CircleAvatar(
                                                        backgroundColor: Colors
                                                            .blue.shade100,
                                                        child: Text(
                                                          g.fullName
                                                              .substring(0, 1)
                                                              .toUpperCase(),
                                                        ),
                                                      ),
                                                      title: Text(g
                                                          .fullName.capitalize),
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
                                            backgroundColor:
                                                Colors.grey.shade300,
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
                                            backgroundColor:
                                                Colors.blue.shade100,
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
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                          backgroundColor:
                                              Colors.deepPurpleAccent,
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClientDetailPage(
                                                        guest: guest),
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
                      _buildDetailRow99(
                          icon: Icons.bed,
                          'Chambre',
                          _selectedRoom!.code,
                          isHeader: true),
                      Container(
                        color: Colors.blueGrey,
                        padding: EdgeInsets.all(2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${_selectedRoom!.category.target!.name}',
                                style: TextStyle(
                                    color:
                                        ColorScheme.light(primary: Colors.white)
                                            .onPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
            Padding(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 0 : 8.0),
              child: Column(
                children: [
                  _buildPriceFieldImproved(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Statut',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(child: Text(_status)),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   children: [
            //     Text('Réductions',
            //         style:
            //             TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            //     Spacer(),
            //     IconButton(
            //       onPressed: _showDiscountDialog,
            //       icon: Icon(Icons.percent),
            //       tooltip: 'Configurer la réduction',
            //     ),
            //   ],
            // ),
            // SizedBox(height: 16),

            /////////////chatgpt////////////////
            if (_discountPercent > 0 || _discountAmount > 0) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_discountPercent > 0)
                      Text(
                        'Réduction: ${_discountPercent.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 20),
                      ),
                    if (_discountAmount > 0)
                      Text(
                          'Montant fixe: ${_discountAmount.toStringAsFixed(0)}'),
                    SizedBox(height: 8),
                    Text(
                      'Appliqué sur:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      _getDiscountDetails(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Text(
                  'Aucune réduction appliquée',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDiscountDetails() {
    List<String> details = [];

    // Si réduction appliquée sur tout
    if (_discountAppliedTo == 'total') {
      details.add("Total général");
    } else if (_discountAppliedTo == 'room') {
      details.add(
          "Chambre (${_selectedRoom!.code}) devient ${(_selectedRoom!.category.target!.basePrice * _seasonalMultiplier * _discountPercent / 100).toStringAsFixed(2)}");
    } else if (_discountAppliedTo == 'board') {
      details.add(
          "Pension (${_selectedBoardBasis?.name ?? '-'}) devient ${(_selectedBoardBasis!.pricePerPerson * _discountPercent / 100).toStringAsFixed(2)}/person");
    } else if (_discountAppliedTo == 'extras') {
      if (_selectedExtras.isNotEmpty) {
        details.addAll(_selectedExtras.map((extra) =>
            "Service: ${extra.extraService.name} devient ${(extra.totalPrice * _discountPercent / 100).toStringAsFixed(2)}"));
      }
    } else if (_discountAppliedTo == 'specific') {
      // Pour les sélections spécifiques
      if (_selectedDiscountItems.contains('room') && _selectedRoom != null) {
        details.add(
            "Chambre (${_selectedRoom!.code})  devient ${(_selectedRoom!.category.target!.basePrice * _seasonalMultiplier * _discountPercent / 100).toStringAsFixed(2)}/nuitée");
      }
      if (_selectedDiscountItems.contains('board') &&
          _selectedBoardBasis != null) {
        details.add(
            "Pension (${_selectedBoardBasis!.name}) devient ${(_selectedBoardBasis!.pricePerPerson * _discountPercent / 100).toStringAsFixed(2)}/person");
      }
      for (var extra in _selectedExtras) {
        final itemId = 'extra_${extra.extraService.id}';
        if (_selectedDiscountItems.contains(itemId)) {
          details.add("Supplément: ${extra.extraService.name} "
              "devient ${(extra.totalPrice * _discountPercent / 100).toStringAsFixed(2)}");
        }
      }
    }

    return details.isEmpty ? "Aucune sélection" : details.join("\n");
  }

  String _getDiscountAppliedToLabel() {
    switch (_discountAppliedTo) {
      case 'room':
        return 'Chambre uniquement';
      case 'board':
        return 'Plan de pension uniquement';
      case 'extras':
        return 'Services supplémentaires uniquement';
      case 'total':
        return 'Total général';
      case 'specific':
        return 'Éléments sélectionnés';
      default:
        return 'Non défini';
    }
  }

  double _calculateTotalPrice() {
    if (_fromDate == null || _toDate == null) return 0.0;
    final nights = _toDate!.difference(_fromDate!).inDays;
    final persons = _selectedGuests.length;

    // Utiliser le prix effectif (auto ou manuel)
    final roomPricePerNight = _getEffectiveRoomPrice();
    double roomTotal = roomPricePerNight * nights;

    double boardBasisTotal = 0.0;
    if (_selectedBoardBasis != null) {
      boardBasisTotal = _selectedBoardBasis!.pricePerPerson * persons * nights;
    }

    double extrasTotal =
        _selectedExtras.fold(0.0, (sum, extra) => sum + extra.totalPrice);

    // Appliquer la réduction INSTANTANÉMENT selon la sélection
    double finalRoomTotal = roomTotal;
    double finalBoardTotal = boardBasisTotal;
    double finalExtrasTotal = extrasTotal;

    switch (_discountAppliedTo) {
      case 'room':
        finalRoomTotal = roomTotal - _calculateDiscount(roomTotal);
        break;
      case 'board':
        finalBoardTotal = boardBasisTotal - _calculateDiscount(boardBasisTotal);
        break;
      case 'extras':
        finalExtrasTotal = extrasTotal - _calculateDiscount(extrasTotal);
        break;
      case 'specific':
        if (_selectedDiscountItems.contains('room')) {
          finalRoomTotal = roomTotal - _calculateDiscount(roomTotal);
        }
        if (_selectedDiscountItems.contains('board')) {
          finalBoardTotal =
              boardBasisTotal - _calculateDiscount(boardBasisTotal);
        }
        // Pour chaque extra sélectionné
        for (int i = 0; i < _selectedExtras.length; i++) {
          final extra = _selectedExtras[i];
          if (_selectedDiscountItems
              .contains('extra_${extra.extraService.id}')) {
            final reduction = _calculateDiscount(extra.totalPrice);
            finalExtrasTotal -= reduction;
          }
        }
        break;
      case 'total':
        final subtotal = roomTotal + boardBasisTotal + extrasTotal;
        // print('roomTotal ');
        // print(roomTotal);
        // print('boardBasisTotal ');
        // print(boardBasisTotal);
        // print('extrasTotal ');
        // print(extrasTotal);
        final totalReduction = _calculateDiscount(subtotal);
        // print('totalReduction ');
        // print(totalReduction);
        return (subtotal - totalReduction).clamp(0, double.infinity);
    }

    return (finalRoomTotal + finalBoardTotal + finalExtrasTotal)
        .clamp(0, double.infinity);
  }

  double _calculateDiscount(double baseAmount) {
    if (_discountType == 'percentage') {
      return baseAmount * (_discountPercent / 100);
    } else {
      return _discountAmount;
    }
  }

  Widget _buildBoardBasisSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                children: [
                  Icon(Icons.restaurant),
                  SizedBox(width: 8),
                  Text('Plan de pension',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 16),
            _buildDetailRow99('Type de pension', _selectedBoardBasis!.code),
            Text('${_selectedBoardBasis!.name}'),
            Text('${_selectedBoardBasis!.pricePerPerson}/personne/nuitée'),
            Text('${_selectedBoardBasis!.description}'),
            Text(
              _selectedBoardBasis!.inclusionsSummary,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraServicesSection() {
    // Calcule le total de tous les extras sélectionnés
    final double totalExtras = _selectedExtras.fold(
      0.0,
      (previousValue, extra) => previousValue + extra.totalPrice,
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Services supplémentaires',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 16),
            if (_selectedExtras.isEmpty)
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Aucun service supplémentaire sélectionné',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    // prend juste la hauteur nécessaire
                    physics: NeverScrollableScrollPhysics(),
                    // désactive le scroll interne
                    itemCount: _selectedExtras.length,

                    itemBuilder: (context, index) {
                      final extra = _selectedExtras[index];

                      final info =
                          _getPricingInfo(extra.extraService.pricingUnit);
                      return Card(
                        color: info.color,
                        margin: EdgeInsets.only(bottom: 8),
                        child: Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ExtraServiceDetailPage(
                                      extraItem:
                                          extra, // Passez directement l'extraItem
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: CircleAvatar(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      foregroundColor: Theme.of(context)
                                          .secondaryHeaderColor,
                                      child: Text('${extra.quantity}'),
                                      maxRadius: 15,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            extra.extraService.name.capitalize,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            children: [
                                              Text(
                                                '${extra.unitPrice}${info.text} = ',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 15),
                                              ),
                                              Text(
                                                '${extra.totalPrice.toStringAsFixed(2)}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Icon(
                                      info.icon,
                                      color: ColorScheme.of(context)
                                          .inverseSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ListTile(
                            //   onTap: () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) =>
                            //             ExtraServiceDetailPage(
                            //           extraItem:
                            //               extra, // Passez directement l'extraItem
                            //         ),
                            //       ),
                            //     );
                            //   },
                            //   title: FittedBox(
                            //     fit: BoxFit.scaleDown,
                            //     child: Text(
                            //       extra.extraService.name,
                            //     ),
                            //   ),
                            //   dense: true,
                            //   leading: CircleAvatar(
                            //     child: Text('${extra.quantity}'),
                            //   ),
                            //   subtitle: FittedBox(
                            //     fit: BoxFit.scaleDown,
                            //     child: Row(
                            //       children: [
                            //         Text(
                            //           'PU: ${extra.unitPrice}${info.text} = ',
                            //           style: TextStyle(fontSize: 15),
                            //         ),
                            //         Text(
                            //           '${extra.totalPrice.toStringAsFixed(2)}',
                            //           style: TextStyle(
                            //             fontSize: 15,
                            //             fontWeight: FontWeight.bold,
                            //             color: Theme.of(context).primaryColor,
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            // Positioned(
                            //   top: 8,
                            //   right: 8,
                            //   child: Icon(
                            //     info.icon,
                            //     color: ColorScheme.of(context).inverseSurface,
                            //   ),
                            // ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Card de TOTAL
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black26,
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_money_rounded,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 50,
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        "Total Extras",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "${totalExtras.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // ListTile(
                          //   dense: true,
                          //   isThreeLine: false,
                          //   // leading: Icon(
                          //   //   Icons.attach_money_rounded,
                          //   //   color: Theme.of(context).colorScheme.primary,
                          //   //   size: 50,
                          //   // ),
                          //   title: FittedBox(fit: BoxFit.scaleDown,
                          //     child: const Text(
                          //       "Total Extras",
                          //       style: TextStyle(
                          //         fontSize: 18,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ),
                          //   subtitle: FittedBox(fit: BoxFit.scaleDown,
                          //     child: Text(
                          //       "${totalExtras.toStringAsFixed(2)}",
                          //       style: TextStyle(
                          //         fontSize: 20,
                          //         fontWeight: FontWeight.w500,
                          //         color: Theme.of(context).colorScheme.primary,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     Icon(
                          //       Icons.attach_money_rounded,
                          //       color: Theme.of(context).colorScheme.primary,
                          //       size: 25,
                          //     ),
                          //     const Text(
                          //       "Total Extras",
                          //       style: TextStyle(
                          //         fontSize: 18,
                          //         fontWeight: FontWeight.w600,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          // FittedBox(fit: BoxFit.scaleDown,
                          //   child: Text(
                          //     "${totalExtras.toStringAsFixed(2)}",
                          //     style: TextStyle(
                          //       fontSize: 20,
                          //       fontWeight: FontWeight.w500,
                          //       color: Theme.of(context).colorScheme.primary,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 2. CORRECTION: Améliorer _buildPriceRow pour supporter les réductions
  Widget _buildPriceRow(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                  color: isDiscount ? Colors.red : null,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal
                  ? Theme.of(context).primaryColor
                  : isDiscount
                      ? Colors.red
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow2(String label, String amount) {
    return Card(
      color: Theme.of(context).primaryColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Version desktop / tablette large
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Version mobile (<600px)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // occupe toute la largeur
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPriceRow600(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isDiscount ? Colors.red : null,
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal
                  ? Theme.of(context).primaryColor
                  : isDiscount
                      ? Colors.red
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow2600(String label, String amount) {
    return Card(
      color: Theme.of(context).primaryColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Version desktop / tablette large
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Version mobile (<600px)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // occupe toute la largeur
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

// 3. CORRECTION: Améliorer le champ prix avec prix automatique
  Widget _buildPriceFieldImproved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage du prix de base de la chambre
        if (_selectedRoom?.category.target != null) ...[
          PriceCard(
            basePrice: _selectedRoom!.category.target!.basePrice,
            seasonalMultiplier: _seasonalMultiplier,
            season: _selectedSeasonalPricing,
          ),
        ],
      ],
    );
  }

// 4. CORRECTION: Améliorer _getEffectiveRoomPrice pour gérer prix auto
  double _getEffectiveRoomPrice() {
    if (_priceController.text.isNotEmpty && _isPriceManuallyEdited) {
      // Prix manuel saisi - appliquer le multiplicateur saisonnier
      return (double.tryParse(_priceController.text) ?? 0.0) *
          _seasonalMultiplier;
    } else if (_selectedRoom?.category.target != null) {
      // Prix automatique basé sur la catégorie avec multiplicateur saisonnier
      return _selectedRoom!.category.target!.basePrice * _seasonalMultiplier;
    }
    return 0.0;
  }

// 5. CORRECTION: Callback pour mise à jour automatique des totaux lors du changement de saison
  void _onSeasonalPricingChanged(SeasonalPricing? newValue) {
    setState(() {
      _selectedSeasonalPricing = newValue;
      _seasonalMultiplier = newValue?.multiplier ?? 1.0;

      // Mettre à jour le prix si pas édité manuellement
      if (!_isPriceManuallyEdited && _selectedRoom?.category.target != null) {
        _updateRoomPrice();
      }

      // Recalculer tous les prix des extras
      _updateAllExtraPrices();

      // Forcer la mise à jour de l'affichage (les totaux se mettront à jour automatiquement)
    });
  }

// 6. CORRECTION: Améliorer _updateRoomPrice pour gérer le prix automatique
  void _updateRoomPrice() {
    if (_isPriceManuallyEdited) return; // Ne pas écraser si édité manuellement

    if (_selectedRoom != null && _selectedRoom!.category.target != null) {
      final basePrice = _selectedRoom!.category.target!.basePrice;
      // NE PAS appliquer le multiplicateur ici car il sera appliqué dans _getEffectiveRoomPrice
      // _priceController.text =
      //     (basePrice * _seasonalMultiplier).toStringAsFixed(2);
      basePrice.toStringAsFixed(2);
    }
  }

  void _showExtraServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter Des Services Supplémentaires'.capitalize,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.provider.getExtraServicesList().length,
                  itemBuilder: (context, index) {
                    final service =
                        widget.provider.getExtraServicesList()[index];
                    if (!service.isActive) return Container();
                    final info = _getPricingInfo(service.pricingUnit);
                    return Card(
                      color: info.color,
                      child: Stack(
                        children: [
                          ListTile(
                            onLongPress: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ExtraServiceDetailPage(
                                            extraService: service)),
                              );
                            },
                            onTap: () {
                              _addExtraService(service);
                              Navigator.pop(context);
                            },
                            title: Text(
                              service.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  service.description,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${service.price} DA ${info.text}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              info.icon,
                              color: ColorScheme.of(context).inverseSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PricingInfo _getPricingInfo(String pricingUnit) {
    switch (pricingUnit.toLowerCase()) {
      case 'per_person':
        return PricingInfo('/Personne', Colors.blue.shade100, Icons.person);
      case 'per_item':
        return PricingInfo(
            '/Article', Colors.green.shade100, Icons.shopping_bag);
      case 'per_night':
        return PricingInfo(
            '/Nuit', Colors.purple.shade100, Icons.nightlight_round);
      case 'per_stay':
        return PricingInfo('/Séjour', Colors.orange.shade100, Icons.home);
      default:
        return PricingInfo('', Colors.grey.shade100, Icons.help_outline);
    }
  }

  Widget _buildDateField(icon, String label, DateTime? date,
      Function(DateTime) onDateSelected, bool departarrive) {
    return InkWell(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(label,
              //     style: TextStyle(
              //         fontSize: 16,
              //         color:
              //             departarrive ? Colors.green[600] : Colors.red[600])),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: departarrive ? Colors.green[600] : Colors.red[600],
                      fontSize: 16),
                  children: [
                    WidgetSpan(
                      child: Icon(
                        icon,
                        size: 16,
                        color:
                            departarrive ? Colors.green[600] : Colors.red[600],
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                    TextSpan(
                        text: label, style: TextStyle(fontFamily: 'oswald')),
                  ],
                ),
              ),

              SizedBox(height: 4),
              Text(
                date != null ? _formatDate(date) : 'Sélectionner',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text('Annuler'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveReservation,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.isEditing
                      ? 'Modifier la réservation'
                      : 'Créer la réservation'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add the missing methods from your original code
  Widget _buildGuestsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Clients',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),

            // Liste des clients sélectionnés
            if (_selectedGuests.isEmpty)
              Center(
                child: Text(
                  'Aucun client ajouté',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_selectedGuests.length, (index) {
                  final guest = _selectedGuests[index];

                  return InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        guest.fullName.substring(0, 1).toUpperCase(),
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                    label: Text(
                      guest.fullName.capitalize,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    backgroundColor: Colors.deepPurpleAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDetailPage(guest: guest),
                        ),
                      );
                    },
                  );
                }),
              )
          ],
        ),
      ),
    );
  }

  // ============================================================================
// 5. CORRECTION - _saveReservation() complète
// ============================================================================

  // CORRECTION 8: Améliorer la sauvegarde pour inclure BoardBasis et Extras
  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) {
      _showErrorSnackBar('Veuillez sélectionner une chambre');
      return;
    }
    if (_selectedEmployee == null) {
      _showErrorSnackBar('Veuillez sélectionner un réceptionniste');
      return;
    }
    if (_selectedGuests.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins un client');
      return;
    }
    if (_fromDate == null || _toDate == null) {
      _showErrorSnackBar('Veuillez sélectionner les dates');
      return;
    }
    if (_fromDate!.isAfter(_toDate!) || _fromDate!.isAtSameMomentAs(_toDate!)) {
      _showErrorSnackBar(
          'La date d\'arrivée doit être antérieure à la date de départ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double priceToSave;

      if (_priceController.text.isNotEmpty && _isPriceManuallyEdited) {
        // Prix manuel saisi
        priceToSave = double.tryParse(_priceController.text) ?? 0.0;
      } else if (_selectedRoom?.category.target != null) {
        // Prix automatique basé sur la catégorie + saison
        priceToSave =
            _selectedRoom!.category.target!.basePrice * _seasonalMultiplier;
      } else {
        priceToSave = 0.0;
      }
      for (final guest in _selectedGuests) {
        if (guest.id == 0) {
          final guestId = await widget.provider.addGuest(guest);
          guest.id = guestId;
        }
      }

      ReservationResult result;

      if (widget.isEditing && widget.existingReservation != null) {
        // Pour l'édition
        widget.existingReservation!.discountType = _discountType;
        widget.existingReservation!.discountAppliedTo = _discountAppliedTo;
        widget.existingReservation!.selectedDiscountItems =
            _discountAppliedTo == 'specific'
                ? jsonEncode(_selectedDiscountItems)
                : '';

        result = await widget.provider.updateReservationComplete(
          reservation: widget.existingReservation!,
          newRoom: _selectedRoom!,
          newReceptionist: _selectedEmployee!,
          newGuests: _selectedGuests,
          newFrom: _fromDate!,
          newTo: _toDate!,
          newPricePerNight: priceToSave,
          newStatus: _status,
          newExtras: _selectedExtras,
          newBoardBasis: _selectedBoardBasis,
          newDiscountPercent: _discountPercent,
          newDiscountAmount: _discountAmount,
          newDiscountType: _discountType,
          newDiscountAppliedTo: _discountAppliedTo,
          newSelectedDiscountItems: jsonEncode(_selectedDiscountItems),
        );
      } else {
        final newReservation = Reservation(
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: priceToSave,
          status: _status,
        );

        newReservation.room.target = _selectedRoom!;
        newReservation.seasonalPricing.target = _selectedSeasonalPricing;
        newReservation.guests.addAll(_selectedGuests);

        result = await widget.provider.addReservation(
          room: _selectedRoom!,
          receptionist: _selectedEmployee!,
          guests: _selectedGuests,
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: priceToSave,
          status: _status,
          boardBasis: _selectedBoardBasis,
          discountPercent: _discountPercent,
          discountAmount: _discountAmount,
          seasonalPricing: _selectedSeasonalPricing,
          discountType: _discountType,
          discountAppliedTo: _discountAppliedTo,
          selectedDiscountItems: jsonEncode(_selectedDiscountItems),
        );
      }

      if (result.isSuccess && result.id != null) {
        // Sauvegarder les extras si nécessaire
        if (_selectedExtras.isNotEmpty) {
          await _saveReservationExtras(result.id!);
        }

        widget.onReservationAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Réservation modifiée avec succès'
                : 'Réservation créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.conflict != null) {
        _showConflictDialog(result.conflict!);
      } else {
        _showErrorSnackBar(result.error ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReservationForced() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pricePerNight = double.tryParse(_priceController.text) ?? 0.0;
      final result = await widget.provider.addReservation(
        room: _selectedRoom!,
        receptionist: _selectedEmployee!,
        guests: _selectedGuests,
        from: _fromDate!,
        to: _toDate!,
        pricePerNight: pricePerNight,
        status: _status,
        boardBasis: _selectedBoardBasis,
        forceOverride: true,
        discountPercent: _discountPercent,
        discountAmount: _discountAmount,
      );

      if (result.isSuccess && result.id != null) {
        if (_selectedExtras.isNotEmpty) {
          await _saveReservationExtras(result.id!);
        }

        widget.onReservationAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Réservation forcée créée avec succès'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// 9. CORRECTION: Mise à jour automatique lors du changement de réduction
  void _onDiscountChanged() {
    setState(() {
      // Forcer la mise à jour de l'affichage
      _calculateTotalPrice();
      // sera automatiquement appelé dans _buildPricingSummary
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showConflictDialog(ReservationConflict conflict) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conflit de réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'La chambre ${conflict.room.code} n\'est pas disponible pour ces dates.'),
            SizedBox(height: 16),
            Text('Réservations en conflit:'),
            ...conflict.conflictingReservations.map((res) =>
                Text('• ${_formatDate(res.from)} - ${_formatDate(res.to)}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Forcer la sauvegarde malgré le conflit
              _saveReservationForced();
            },
            child: Text('Forcer la réservation'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _guestController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _priceController.dispose();
    _discountPercentController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveReservationExtras(int reservationId) async {
    try {
      // Récupérer la réservation nouvellement créée/mise à jour
      final reservation =
          widget.provider.reservations.firstWhere((r) => r.id == reservationId);

      // Sauvegarder chaque extra
      for (final extraItem in _selectedExtras) {
        final extra = ReservationExtra(
          quantity: extraItem.quantity,
          unitPrice: extraItem.unitPrice,
          totalPrice: extraItem.totalPrice,
          status: 'Confirmed',
          scheduledDate: extraItem.scheduledDate,
        );
        extra.reservation.target = reservation;
        extra.extraService.target = extraItem.extraService;

        // Sauvegarder dans ObjectBox
        await widget.provider.reservationExtraBox.put(extra);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des extras: $e');
      _showErrorSnackBar(
          'Erreur lors de la sauvegarde des services supplémentaires');
    }
  }

  String _getDiscountPreview() {
    if (_discountPercent == 0 && _discountAmount == 0) {
      return 'Aucune réduction configurée';
    }

    String discountText = _discountType == 'percentage'
        ? '${_discountPercent.toStringAsFixed(1)}%'
        : '${_discountAmount.toStringAsFixed(2)}';

    String appliedText = _getDiscountAppliedToLabel();

    return 'Réduction de $discountText appliquée sur: $appliedText';
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
              child: Icon(icon, size: 20, color: Colors.grey.shade600),
            ),
          SizedBox(
            width: isHeader ? 85 : 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                fontSize: isHeader ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlighted ? 16 : 14,
                color: isHighlighted ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReservationDetailView2 extends StatefulWidget {
  const ReservationDetailView2({super.key});

  @override
  State<ReservationDetailView2> createState() => _ReservationDetailView2State();
}

class _ReservationDetailView2State extends State<ReservationDetailView2> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
