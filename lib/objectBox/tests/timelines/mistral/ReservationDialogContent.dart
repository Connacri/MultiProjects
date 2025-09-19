import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/provider_hotel.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/widgets.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';

import '../../../Entity.dart';
import 'claude_crud.dart';

// Enhanced ReservationDialogContent with Board Basis and Extra Services integration
class ReservationDialogContent extends StatefulWidget {
  final Room? preselectedRoom;
  final DateTime? preselectedDate;
  final Hotel currentHotel;
  final HotelProvider provider;
  final BuildContext parentContext;
  final VoidCallback onReservationAdded;
  final bool isEditing;
  final Reservation? existingReservation;
  final List<SeasonalPricing> seasonalPricings;

  const ReservationDialogContent({
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
  State<ReservationDialogContent> createState() =>
      _ReservationDialogContentState();
}

class _ReservationDialogContentState extends State<ReservationDialogContent> {
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
  String _status = "Confirmée";
  bool _isLoading = false;
  bool _isPriceEditable = false; // Nouveau: pour contrôler l'édition du prix

  // Board Basis and Extra Services
  BoardBasis? _selectedBoardBasis;
  List<ReservationExtraItem> _selectedExtras = [];

  // Variables pour l'édition de client
  bool _isEditingGuest = false;
  Guest? _guestBeingEdited;
  int? _editingGuestIndex;

  final List<String> _statuses = [
    "Confirmée",
    "En attente",
    "Arrivé",
    "Parti",
    "Annulée"
  ];

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

    final provider = Provider.of<HotelProvider>(context, listen: false);

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

    // Après build, recalculer le multiplicateur sur la plage et mettre à jour le prix
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_fromDate != null && _toDate != null) {
    //     _seasonalMultiplier =
    //         _calculateSeasonalMultiplier(_fromDate!, _toDate!);

    //     _updateRoomPrice(); // doit utiliser _seasonalMultiplier ou la fonction per-night
    //     setState(() {}); // uniquement si UI doit se rafraichir
    //   }
    // });.
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final provider = Provider.of<HotelProvider>(context, listen: true);
  //   final active = provider.selectedSeasonalPricing;
  //
  //   if (active != null && active.id != _selectedSeasonalPricing?.id) {
  //     setState(() {
  //       _selectedSeasonalPricing = active;
  //       _seasonalMultiplier = active.multiplier;
  //       print('didChangeDependencies');
  //       print(_seasonalMultiplier);
  //       _updateRoomPrice();
  //     });
  //   }
  // }

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

  void _removeExtraService(ReservationExtraItem item) {
    setState(() {
      _selectedExtras.remove(item);
    });
    print("Après suppression: ${_selectedExtras.length}");
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
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Middle Column
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildBoardBasisSection(),
                            _buildGuestsSection(),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Right Column
                      Expanded(
                        flex: 2,
                        child: Column(children: [
                          _buildExtraServicesSection(),

                          // _buildSeasonalPricingSection2(),
                          // Dans _buildDesktopForm(), _buildMobileForm(), et _buildTabletForm()
                          // Remplacer SeasonalPricingDropdown() par :

                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            child: SeasonalPricingDropdown(
                              selectedValue: _selectedSeasonalPricing,
                              customSeasonalPricings: _seasonalPricings,
                              useLocalState: true,
                              savedSeason: _selectedSeasonalPricing,

                              onChanged:
                                  _onSeasonalPricingChanged, // Utiliser le nouveau callback
                            ),
                          ),
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
                children: [
                  _buildBasicInfoSection(),
                  SizedBox(height: 16),
                  _buildBoardBasisSection(),
                  SizedBox(height: 16),
                  _buildGuestsSection(),
                  SizedBox(height: 16),
                  _buildExtraServicesSection(),
                  SizedBox(height: 16),
                  // Dans _buildDesktopForm(), _buildMobileForm(), et _buildTabletForm()
// Remplacer SeasonalPricingDropdown() par

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
                    widget.isEditing
                        ? 'Modifier la réservation'
                        : 'Nouvelle Réservation',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
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
            SizedBox(height: 16),

            // Room and Employee
            SizedBox(
              height: 160,
              child: Column(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedEmployee?.id,
                      decoration: InputDecoration(
                        labelText: 'Réceptionniste *',
                        prefixIcon: Icon(Icons.person),
                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(8),
                        // ),
                      ),
                      items: widget.provider.employees.map((emp) {
                        return DropdownMenuItem<int>(
                          value: emp.id,
                          child: Text(emp.fullName),
                        );
                      }).toList(),
                      onChanged: (int? empId) {
                        setState(() {
                          _selectedEmployee = widget.provider.employees
                              .firstWhere((emp) => emp.id == empId);
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Choisissez un réceptionniste' : null,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: DropdownButtonFormField<Room>(
                      isDense: false,
                      isExpanded: true,
                      value: _selectedRoom,
                      decoration: InputDecoration(
                        labelText: 'Chambre *',
                        // prefixIcon: Icon(Icons.bed),
                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(8),
                        // ),
                      ),
                      items: widget.currentHotel.rooms.map((room) {
                        final categoryName =
                            widget.provider.getRoomCategoryName(room);
                        return DropdownMenuItem(
                          value: room,
                          child: Row(
                            children: [
                              Text('${room.code}'),
                              const SizedBox(width: 8),
                              // 👉 le texte peut s'adapter
                              Expanded(
                                child: Text(
                                  '$categoryName ${room.category.target!.bedType ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                  // coupe avec "..."
                                  maxLines: 1, // une seule ligne
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (room) {
                        setState(() {
                          _selectedRoom = room;
                          _updateRoomPrice(); // Recalculer le prix
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Choisissez une chambre' : null,
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                    child: _buildDateField(
                        FontAwesomeIcons.planeArrival, '  Arrivée', _fromDate,
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

            SizedBox(height: 16),

            // ================= Price & Status Section =================
            Padding(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 0 : 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildPriceFieldImproved(),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    isDense: true,
                    isExpanded: true,
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (status) => setState(() => _status = status!),
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
            Row(
              children: [
                Text('Réductions',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  onPressed: _showDiscountDialog,
                  icon: Icon(Icons.percent),
                  tooltip: 'Configurer la réduction',
                ),
              ],
            ),
            SizedBox(height: 16),

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
            DropdownButtonFormField<String>(
              isDense: false,
              isExpanded: true,
              value: _selectedBoardBasis?.code,
              decoration: InputDecoration(
                labelText: 'Type de pension',
                // prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: _selectedBoardBasis != null
                    ? '${_selectedBoardBasis!.pricePerPerson}/personne/nuitée'
                    : null,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              menuMaxHeight: 250,
              items: () {
                final allItems = widget.provider
                    .getBoardBasisList()
                    .where((bb) => bb.isActive)
                    .toList();

                final uniqueItems = <String, BoardBasis>{};
                for (final item in allItems) {
                  uniqueItems.putIfAbsent(item.code, () => item);
                }

                // Si le selected n'existe plus, on remet à null
                if (_selectedBoardBasis != null &&
                    !uniqueItems.containsKey(_selectedBoardBasis!.code)) {
                  _selectedBoardBasis = null;
                }

                return uniqueItems.values.map((boardBasis) {
                  return DropdownMenuItem<String>(
                    value: boardBasis.code,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${boardBasis.name} (${boardBasis.code})',
                            style: TextStyle(fontSize: 14)),
                        if (boardBasis.inclusionsSummary.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  boardBasis.inclusionsSummary,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${boardBasis.pricePerPerson.toStringAsFixed(2)}/person',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList();
              }(),
              onChanged: (String? selectedCode) {
                setState(() {
                  final allItems = widget.provider
                      .getBoardBasisList()
                      .where((bb) => bb.isActive)
                      .toList();

                  // méthode sûre : retourne null si pas trouvé
                  final matches =
                      allItems.where((bb) => bb.code == selectedCode);
                  _selectedBoardBasis =
                      matches.isNotEmpty ? matches.first : null;
                });
              },
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
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Services supplémentaires',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                IconButton(
                  onPressed: _showExtraServicesDialog,
                  icon: Icon(Icons.add_circle),
                  tooltip: 'Ajouter un service',
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_selectedExtras.isEmpty)
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Aucun service supplémentaire sélectionné',
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
                            ListTile(
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
                              onLongPress: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Confirmation"),
                                    content: const Text(
                                        "Voulez-vous vraiment supprimer ce service ?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text("Annuler"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text("Supprimer"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  _removeExtraService(extra);
                                }
                              },
                              title: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  extra.extraService.name,
                                ),
                              ),
                              subtitle: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Qtt: ${extra.quantity} | PU: ${extra.unitPrice}${info.text} = ',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    Text(
                                      '${extra.totalPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
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
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 30)),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
          // Recalculer le multiplicateur saisonnier
          if (_fromDate != null && _toDate != null) {
            setState(() {
              // _seasonalMultiplier =
              //     _calculateSeasonalMultiplier(_fromDate!, _toDate!);
            });
          }
        }
      },
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
                Spacer(),
                IconButton(
                  onPressed: _showAddGuestDialog,
                  icon: Icon(Icons.person_add),
                  tooltip: 'Ajouter un client',
                ),
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
              // ListView.builder(
              //   shrinkWrap: true,
              //   physics: NeverScrollableScrollPhysics(),
              //   itemCount: _selectedGuests.length,
              //   itemBuilder: (context, index) {
              //     final guest = _selectedGuests[index];
              //     return Card(
              //       margin: EdgeInsets.only(bottom: 8),
              //       child: ListTile(
              //         onTap: () {
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder: (_) => ClientDetailPage(guest: guest),
              //             ),
              //           );
              //         },
              //         leading: CircleAvatar(
              //           child:
              //               Text(guest.fullName.substring(0, 1).toUpperCase()),
              //         ),
              //         title: Text(guest.fullName),
              //         subtitle: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             if (guest.phoneNumber.isNotEmpty)
              //               Text('Tél: ${guest.phoneNumber}'),
              //             // if (guest.idCardNumber.isNotEmpty)
              //             //   Text('ID: ${guest.idCardNumber}'),
              //           ],
              //         ),
              //         onLongPress: () async {
              //           final action = await showDialog<String>(
              //             context: context,
              //             builder: (context) => SimpleDialog(
              //               title: const Text("Choisissez une action"),
              //               children: [
              //                 SimpleDialogOption(
              //                   onPressed: () => Navigator.pop(context, "edit"),
              //                   child: Row(
              //                     children: const [
              //                       Icon(Icons.edit, color: Colors.blue),
              //                       SizedBox(width: 8),
              //                       Text("Éditer"),
              //                     ],
              //                   ),
              //                 ),
              //                 SimpleDialogOption(
              //                   onPressed: () =>
              //                       Navigator.pop(context, "delete"),
              //                   child: Row(
              //                     children: const [
              //                       Icon(Icons.delete, color: Colors.red),
              //                       SizedBox(width: 8),
              //                       Text("Supprimer"),
              //                     ],
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           );
              //
              //           if (action == "edit") {
              //             _editGuest(index);
              //           } else if (action == "delete") {
              //             final confirm = await showDialog<bool>(
              //               context: context,
              //               builder: (context) => AlertDialog(
              //                 title: const Text("Confirmation"),
              //                 content: const Text(
              //                     "Voulez-vous vraiment supprimer ce client ?"),
              //                 actions: [
              //                   TextButton(
              //                     onPressed: () =>
              //                         Navigator.of(context).pop(false),
              //                     child: const Text("Annuler"),
              //                   ),
              //                   ElevatedButton(
              //                     onPressed: () =>
              //                         Navigator.of(context).pop(true),
              //                     child: const Text("Supprimer"),
              //                   ),
              //                 ],
              //               ),
              //             );
              //
              //             if (confirm == true) {
              //               _removeGuest(index);
              //             }
              //           }
              //         },
              //       ),
              //     );
              //   },
              // ),
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
                    onDeleted: () async {
                      final action = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text("Choisissez une action"),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, "edit"),
                              child: Row(
                                children: const [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("Éditer"),
                                ],
                              ),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, "delete"),
                              child: Row(
                                children: const [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Supprimer"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (action == "edit") {
                        _editGuest(index);
                      } else if (action == "delete") {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text(
                                "Voulez-vous vraiment supprimer ce client ?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Annuler"),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Supprimer"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          _removeGuest(index);
                        }
                      }
                    },
                    deleteIcon: const Icon(
                      Icons.delete,
                    ),
                  );
                }),
              )
          ],
        ),
      ),
    );
  }

  void _showAddGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildGuestDialog(),
    );
  }

  void _editGuest(int index) {
    _isEditingGuest = true;
    _editingGuestIndex = index;
    _guestBeingEdited = _selectedGuests[index];

    // Pré-remplir les champs
    _guestController.text = _guestBeingEdited!.fullName;
    _phoneController.text = _guestBeingEdited!.phoneNumber;
    _idCardController.text = _guestBeingEdited!.idCardNumber;

    _showAddGuestDialog();
  }

  void _removeGuest(int index) {
    setState(() {
      _selectedGuests.removeAt(index);
      _updateAllExtraPrices(); // Recalculer les prix
    });
  }

  Widget _buildGuestDialog() {
    return AlertDialog(
      title: Text(_isEditingGuest ? 'Modifier le client' : 'Ajouter un client'),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _guestController,
              decoration: InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _idCardController,
              decoration: InputDecoration(
                labelText: 'Numéro de carte d\'identité',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clearGuestForm();
            Navigator.pop(context);
          },
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveGuest,
          child: Text(_isEditingGuest ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  void _saveGuest() {
    if (_guestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nom du client est requis')),
      );
      return;
    }

    final guest = Guest(
      fullName: _guestController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      idCardNumber: _idCardController.text.trim(),
    );

    setState(() {
      if (_isEditingGuest && _editingGuestIndex != null) {
        _selectedGuests[_editingGuestIndex!] = guest;
      } else {
        _selectedGuests.add(guest);
      }
      _updateAllExtraPrices(); // Recalculer les prix
    });

    _clearGuestForm();
    print("Avant recalcul extras: ${_selectedExtras.length}");

    Navigator.pop(context);
  }

  void _clearGuestForm() {
    _guestController.clear();
    _phoneController.clear();
    _idCardController.clear();
    // _selectedExtras.clear();
    _isEditingGuest = false;
    _editingGuestIndex = null;
    _guestBeingEdited = null;
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

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: 700,
            height: 700,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Configuration de la réduction',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 16),

                // Type de réduction
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Type de réduction:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        // Réinitialiser
                        setDialogState(() {
                          _discountPercent = 0.0;
                          _discountAmount = 0.0;
                          _discountPercentController.text = "0";
                          _discountAmountController.text = "0";
                          _discountAppliedTo = 'total';
                          _selectedDiscountItems.clear();
                          _onDiscountChanged();
                          Navigator.pop(context);
                        });
                      },
                      child: Text('Tout Réinitialiser',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Version desktop / tablette large
                      return Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Pourcentage'),
                              value: 'percentage',
                              groupValue: _discountType,
                              onChanged: (value) =>
                                  setDialogState(() => _discountType = value!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Montant fixe'),
                              value: 'amount',
                              groupValue: _discountType,
                              onChanged: (value) =>
                                  setDialogState(() => _discountType = value!),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Version mobile (<600px)
                      return Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Icon(FontAwesomeIcons.percent),
                              dense: true,
                              // Text('Pourcentage'),
                              value: 'percentage',
                              groupValue: _discountType,
                              onChanged: (value) =>
                                  setDialogState(() => _discountType = value!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Icon(FontAwesomeIcons.dollarSign),
                              //Text('Montant fixe'),
                              value: 'amount',
                              groupValue: _discountType,
                              onChanged: (value) =>
                                  setDialogState(() => _discountType = value!),
                            ),
                          ),
                        ],
                      );

                      //
                      //     Column(
                      //     mainAxisSize: MainAxisSize.min,
                      //     // adapte la hauteur à son contenu
                      //     children: [
                      //       RadioListTile<String>(
                      //         title: const Text('Pourcentage'),
                      //         value: 'percentage',
                      //         groupValue: _discountType,
                      //         onChanged: (value) =>
                      //             setDialogState(() => _discountType = value!),
                      //       ),
                      //       RadioListTile<String>(
                      //         title: const Text('Montant fixe'),
                      //         value: 'amount',
                      //         groupValue: _discountType,
                      //         onChanged: (value) =>
                      //             setDialogState(() => _discountType = value!),
                      //       ),
                      //     ],
                      //   );
                    }
                  },
                ),

                SizedBox(height: 16),

                // Valeur de la réduction
                if (_discountType == 'percentage')
                  TextFormField(
                    controller: _discountPercentController,
                    decoration: InputDecoration(
                      labelText: 'Pourcentage de réduction (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setDialogState(() {
                      _discountPercent = double.tryParse(value) ?? 0.0;
                      _discountAmount = 0.0;
                      _discountAmountController.text = "0";
                    }),
                  )
                else
                  TextFormField(
                    controller: _discountAmountController,
                    decoration: InputDecoration(
                      labelText: 'Montant de réduction (DA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setDialogState(() {
                      _discountAmount = double.tryParse(value) ?? 0.0;
                      _discountPercent = 0.0;
                      _discountPercentController.text = "0";
                    }),
                  ),

                SizedBox(height: 16),

                // Application de la réduction
                Text('Appliquer la réduction sur:',
                    style: TextStyle(fontWeight: FontWeight.bold)),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: Text('Total général'),
                          value: 'total',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        RadioListTile<String>(
                          title: Text('Chambre'),
                          value: 'room',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        RadioListTile<String>(
                          title: Text(
                            'Pension',
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: 'board',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        if (!_selectedExtras.isEmpty)
                          RadioListTile<String>(
                            title: Text('Services Supplément'),
                            value: 'extras',
                            groupValue: _discountAppliedTo,
                            onChanged: (value) => setDialogState(
                                () => _discountAppliedTo = value!),
                          ),

                        RadioListTile<String>(
                          title: Text('Éléments spécifiques'),
                          value: 'specific',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),

                        // Sélection spécifique si nécessaire
                        if (_discountAppliedTo == 'specific') ...[
                          Divider(),
                          Text('Sélectionnez les éléments:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(
                            height: 8,
                          ),
                          // Chambre
                          if (_selectedRoom != null)
                            CheckboxListTile(
                              title: Text('Chambre (${_selectedRoom!.code})'),
                              subtitle: Text(
                                  'Prix: ${(double.tryParse(_priceController.text) ?? 0.0 * _seasonalMultiplier).toStringAsFixed(2)}/nuit'),
                              value: _selectedDiscountItems.contains('room'),
                              onChanged: (bool? value) => setDialogState(() {
                                if (value == true) {
                                  _selectedDiscountItems.add('room');
                                } else {
                                  _selectedDiscountItems.remove('room');
                                }
                              }),
                            ),

                          // Plan de pension
                          if (_selectedBoardBasis != null)
                            CheckboxListTile(
                              title: Text(
                                  'Plan de pension (${_selectedBoardBasis!.name})'),
                              subtitle: Text(
                                  'Prix: ${_selectedBoardBasis!.pricePerPerson.toStringAsFixed(2)}/personne/nuit'),
                              value: _selectedDiscountItems.contains('board'),
                              onChanged: (bool? value) => setDialogState(() {
                                if (value == true) {
                                  _selectedDiscountItems.add('board');
                                } else {
                                  _selectedDiscountItems.remove('board');
                                }
                              }),
                            ),

                          // Services supplémentaires
                          ..._selectedExtras.map((extra) {
                            final itemId = 'extra_${extra.extraService.id}';
                            return CheckboxListTile(
                              title: Text(extra.extraService.name),
                              subtitle: Text(
                                  'Prix total: ${extra.totalPrice.toStringAsFixed(2)}'),
                              value: _selectedDiscountItems.contains(itemId),
                              onChanged: (bool? value) => setDialogState(() {
                                if (value == true) {
                                  _selectedDiscountItems.add(itemId);
                                } else {
                                  _selectedDiscountItems.remove(itemId);
                                }
                              }),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Aperçu de la réduction
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aperçu:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_getDiscountPreview()),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    SizedBox(width: 8),
                    // ElevatedButton(
                    //   onPressed: () {
                    //     _onDiscountChanged();
                    //     Navigator.pop(context);
                    //   },
                    //   child: Text('Appliquer'),
                    // ),
                    ElevatedButton(
                      onPressed: () {
                        bool hasError = false;
                        String errorMessage = '';

                        if (_discountType == 'percentage' &&
                            (_discountPercent <= 0 ||
                                _discountPercentController.text.isEmpty)) {
                          hasError = true;
                          errorMessage =
                              'Le pourcentage de réduction doit être supérieur à 0.';
                        } else if (_discountType == 'amount' &&
                            (_discountAmount <= 0 ||
                                _discountAmountController.text.isEmpty)) {
                          hasError = true;
                          errorMessage =
                              'Le montant de réduction doit être supérieur à 0.';
                        } else if (_discountAppliedTo == 'specific' &&
                            _selectedDiscountItems.isEmpty) {
                          hasError = true;
                          errorMessage =
                              'Veuillez sélectionner au moins un élément pour appliquer la réduction.';
                        }

                        if (hasError) {
                          // Afficher un AlertDialog au lieu d'un SnackBar
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Erreur de validation"),
                                content: Text(errorMessage),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("OK"),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Fermer l'AlertDialog
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          return;
                        }

                        _onDiscountChanged();
                        Navigator.pop(context);
                      },
                      child: Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}

class PricingInfo {
  final String text;
  final Color color;
  final IconData icon;

  PricingInfo(this.text, this.color, this.icon);
}

class ReservationExtraItem {
  final ExtraService extraService;
  int quantity;
  double unitPrice;
  double totalPrice;
  DateTime? scheduledDate;
  String? notes;

  ReservationExtraItem({
    required this.extraService,
    this.quantity = 1,
    required this.unitPrice,
    this.totalPrice = 0.0,
    this.scheduledDate,
    this.notes,
  });
}

class SeasonalPricingDropdown extends StatelessWidget {
  final SeasonalPricing? selectedValue;
  final SeasonalPricing? savedSeason;
  final Function(SeasonalPricing?)? onChanged;
  final List<SeasonalPricing>? customSeasonalPricings;
  final bool useLocalState;
  final bool autoSave;

  const SeasonalPricingDropdown({
    super.key,
    this.selectedValue,
    required this.savedSeason,
    this.onChanged,
    this.customSeasonalPricings,
    this.useLocalState = false,
    this.autoSave = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (context, provider, child) {
        // Utiliser les tarifs personnalisés si fournis, sinon ceux du provider
        final list = customSeasonalPricings ?? provider.getSeasonalPricings();

        // Utiliser la valeur sélectionnée personnalisée si fournie, sinon celle du provider
        final selected = savedSeason != null
            ? savedSeason
            : useLocalState
                ? selectedValue
                : provider.selectedSeasonalPricing;

        // Éliminer les doublons de la liste
        final uniqueMap = <int, SeasonalPricing>{};
        for (final sp in list) {
          uniqueMap[sp.id] = sp;
        }
        final uniqueList = uniqueMap.values.toList();

        // Trier par priorité puis par nom
        uniqueList.sort((a, b) {
          final priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) return priorityComparison;
          return a.name.compareTo(b.name);
        });

        // Trouver la bonne instance dans la liste unique
        SeasonalPricing? validValue;
        if (selected != null) {
          try {
            validValue =
                uniqueList.firstWhere((item) => item.id == selected.id);
          } catch (e) {
            // Si l'élément sélectionné n'est plus dans la liste
            validValue = null;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(0.0),
          child: DropdownButtonFormField<SeasonalPricing>(
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'OSWALD'),
            value: validValue,
            isExpanded: true,
            isDense: false,
            decoration: InputDecoration(
              labelText: 'Tarif saisonnier',
              // prefixIcon: const Icon(Icons.calendar_today),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: uniqueList.map((sp) {
              return DropdownMenuItem(
                value: sp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Centrer verticalement
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${sp.name} (${sp.multiplier}x)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateRange(sp),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return uniqueList.map((sp) {
                return SizedBox(
                  // ✅ Contraint la hauteur affichée
                  height: 50, // Ajuste selon le design (par défaut 48px)
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${sp.name} (${sp.multiplier}x)',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatDateRange(sp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
            onChanged: (SeasonalPricing? newValue) {
              if (newValue == null) return;

              if (onChanged != null) {
                onChanged!(newValue);
              } else if (provider.currentHotel != null) {
                _handleSeasonChange(context, provider, newValue);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner un tarif saisonnier';
              }
              return null;
            },
          ),
        );
      },
    );
  }

  /// Gère le changement de saison de manière asynchrone
  void _handleSeasonChange(
      BuildContext context, HotelProvider provider, SeasonalPricing newValue) {
    provider
        .setSelectedSeasonalPricing(
      provider.currentHotel!,
      newValue,
      autoSave: autoSave,
    )
        .then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saison "${newValue.name}" sélectionnée'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  String _formatDateRange(SeasonalPricing sp) {
    final startFormatted =
        '${sp.startDate.day}/${sp.startDate.month}/${sp.startDate.year}';
    final endFormatted =
        '${sp.endDate.day}/${sp.endDate.month}/${sp.endDate.year}';
    return '$startFormatted - $endFormatted';
  }

  String _getSeasonInfo(SeasonalPricing sp) {
    final now = DateTime.now();
    final isCurrentlyActive = sp.isDateInSeason(now);

    if (isCurrentlyActive) {
      return '✓ Saison active - ${_formatDateRange(sp)}';
    } else {
      return _formatDateRange(sp);
    }
  }
}

/// Widget pour afficher un indicateur de la saison actuelle
class CurrentSeasonIndicator extends StatelessWidget {
  const CurrentSeasonIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (context, provider, child) {
        final currentSeason = provider.selectedSeasonalPricing;

        if (currentSeason == null) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('Aucune saison sélectionnée',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final isActive = currentSeason.isDateInSeason(now);

        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: isActive ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                '${currentSeason.name} (${currentSeason.multiplier}x)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
