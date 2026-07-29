import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../objectBox/Entity.dart';
import '../../../../../objectBox/classeObjectBox.dart';
import '../../../../../objectbox.g.dart';

class ObjectBoxDataViewerPage extends StatefulWidget {
  const ObjectBoxDataViewerPage({super.key});

  @override
  State<ObjectBoxDataViewerPage> createState() =>
      _ObjectBoxDataViewerPageState();
}

class _ObjectBoxDataViewerPageState extends State<ObjectBoxDataViewerPage> {
  String _search = '';
  late List<_BoxHandle> _boxes;

  @override
  void initState() {
    super.initState();
    _boxes = _buildBoxHandles(context.read<ObjectBox>());
  }

  List<_BoxHandle> _buildBoxHandles(ObjectBox o) {
    return [
      _BoxSection('Staff & Planning (ancien)'),
      _BoxItem(
          'Staff',
          Icons.people,
          Colors.blue,
          () => o.staffBox.count(),
          () => o.staffBox.getAll(),
          (id) => o.staffBox.remove(id),
          () => o.staffBox.removeAll()),
      _BoxItem(
          'ActiviteJour',
          Icons.event,
          Colors.indigo,
          () => o.activiteBox.count(),
          () => o.activiteBox.getAll(),
          (id) => o.activiteBox.remove(id),
          () => o.activiteBox.removeAll()),
      _BoxItem(
          'Branch',
          Icons.business,
          Colors.brown,
          () => o.branchBox.count(),
          () => o.branchBox.getAll(),
          (id) => o.branchBox.remove(id),
          () => o.branchBox.removeAll()),
      _BoxItem(
          'TimeOff',
          Icons.beach_access,
          Colors.orange,
          () => o.timeOffBox.count(),
          () => o.timeOffBox.getAll(),
          (id) => o.timeOffBox.remove(id),
          () => o.timeOffBox.removeAll()),
      _BoxItem(
          'Planification',
          Icons.calendar_month,
          Colors.red,
          () => o.planificationBox.count(),
          () => o.planificationBox.getAll(),
          (id) => o.planificationBox.remove(id),
          () => o.planificationBox.removeAll()),
      _BoxItem(
          'PlanningHebdo',
          Icons.calendar_view_week,
          Colors.purple,
          () => o.planningHebdoBox.count(),
          () => o.planningHebdoBox.getAll(),
          (id) => o.planningHebdoBox.remove(id),
          () => o.planningHebdoBox.removeAll()),
      _BoxItem(
          'TypeActivite',
          Icons.category,
          Colors.teal,
          () => o.typeActiviteBox.count(),
          () => o.typeActiviteBox.getAll(),
          (id) => o.typeActiviteBox.remove(id),
          () => o.typeActiviteBox.removeAll()),
      _BoxSection('Planning (nouvelle archi)'),
      _BoxItem(
          'PlanningSnapshot',
          Icons.camera,
          Colors.deepPurple,
          () => o.planningSnapshotBox.count(),
          () => o.planningSnapshotBox.getAll(),
          (id) => o.planningSnapshotBox.remove(id),
          () => o.planningSnapshotBox.removeAll()),
      _BoxItem(
          'PlanningAssignment',
          Icons.assignment,
          Colors.deepOrange,
          () => o.planningAssignmentBox.count(),
          () => o.planningAssignmentBox.getAll(),
          (id) => o.planningAssignmentBox.remove(id),
          () => o.planningAssignmentBox.removeAll()),
      _BoxItem(
          'RotationState',
          Icons.rotate_right,
          Colors.cyan,
          () => o.rotationStateSnapshotBox.count(),
          () => o.rotationStateSnapshotBox.getAll(),
          (id) => o.rotationStateSnapshotBox.remove(id),
          () => o.rotationStateSnapshotBox.removeAll()),
      _BoxSection('POS / Commerce'),
      _BoxItem(
          'Usero',
          Icons.person,
          Colors.grey,
          () => o.userBox.count(),
          () => o.userBox.getAll(),
          (id) => o.userBox.remove(id),
          () => o.userBox.removeAll()),
      _BoxItem(
          'Crud',
          Icons.shopping_cart,
          Colors.amber,
          () => o.crudBox.count(),
          () => o.crudBox.getAll(),
          (id) => o.crudBox.remove(id),
          () => o.crudBox.removeAll()),
      _BoxItem(
          'Produit',
          Icons.inventory_2,
          Colors.green,
          () => o.produitBox.count(),
          () => o.produitBox.getAll(),
          (id) => o.produitBox.remove(id),
          () => o.produitBox.removeAll()),
      _BoxItem(
          'Approvisionnement',
          Icons.local_shipping,
          Colors.brown,
          () => o.approvisionnementBox.count(),
          () => o.approvisionnementBox.getAll(),
          (id) => o.approvisionnementBox.remove(id),
          () => o.approvisionnementBox.removeAll()),
      _BoxItem(
          'Fournisseur',
          Icons.store,
          Colors.orange,
          () => o.fournisseurBox.count(),
          () => o.fournisseurBox.getAll(),
          (id) => o.fournisseurBox.remove(id),
          () => o.fournisseurBox.removeAll()),
      _BoxItem(
          'Facture',
          Icons.receipt_long,
          Colors.red,
          () => o.factureBox.count(),
          () => o.factureBox.getAll(),
          (id) => o.factureBox.remove(id),
          () => o.factureBox.removeAll()),
      _BoxItem(
          'LigneFacture',
          Icons.receipt,
          Colors.deepOrange,
          () => o.ligneFacture.count(),
          () => o.ligneFacture.getAll(),
          (id) => o.ligneFacture.remove(id),
          () => o.ligneFacture.removeAll()),
      _BoxItem(
          'Client',
          Icons.people_outline,
          Colors.indigo,
          () => o.clientBox.count(),
          () => o.clientBox.getAll(),
          (id) => o.clientBox.remove(id),
          () => o.clientBox.removeAll()),
      _BoxItem(
          'DeletedProduct',
          Icons.delete_outline,
          Colors.grey,
          () => o.deletedProduct.count(),
          () => o.deletedProduct.getAll(),
          (id) => o.deletedProduct.remove(id),
          () => o.deletedProduct.removeAll()),
      _BoxSection('Hôtel'),
      _BoxItem(
          'Hotel',
          Icons.hotel,
          Colors.amber,
          () => o.hotelBox.count(),
          () => o.hotelBox.getAll(),
          (id) => o.hotelBox.remove(id),
          () => o.hotelBox.removeAll()),
      _BoxItem(
          'Room',
          Icons.room,
          Colors.blue,
          () => o.roomBox.count(),
          () => o.roomBox.getAll(),
          (id) => o.roomBox.remove(id),
          () => o.roomBox.removeAll()),
      _BoxItem(
          'Guest',
          Icons.people,
          Colors.teal,
          () => o.guestBox.count(),
          () => o.guestBox.getAll(),
          (id) => o.guestBox.remove(id),
          () => o.guestBox.removeAll()),
      _BoxItem(
          'Employee',
          Icons.badge,
          Colors.brown,
          () => o.employeeBox.count(),
          () => o.employeeBox.getAll(),
          (id) => o.employeeBox.remove(id),
          () => o.employeeBox.removeAll()),
      _BoxItem(
          'RoomCategory',
          Icons.category,
          Colors.purple,
          () => o.roomCategory.count(),
          () => o.roomCategory.getAll(),
          (id) => o.roomCategory.remove(id),
          () => o.roomCategory.removeAll()),
      _BoxItem(
          'BoardBasis',
          Icons.restaurant,
          Colors.orange,
          () => o.boardBasis.count(),
          () => o.boardBasis.getAll(),
          (id) => o.boardBasis.remove(id),
          () => o.boardBasis.removeAll()),
      _BoxItem(
          'ExtraService',
          Icons.miscellaneous_services,
          Colors.cyan,
          () => o.extraService.count(),
          () => o.extraService.getAll(),
          (id) => o.extraService.remove(id),
          () => o.extraService.removeAll()),
      _BoxItem(
          'ReservationExtra',
          Icons.topic,
          Colors.lightGreen,
          () => o.reservationExtra.count(),
          () => o.reservationExtra.getAll(),
          (id) => o.reservationExtra.remove(id),
          () => o.reservationExtra.removeAll()),
      _BoxItem(
          'SeasonalPricing',
          Icons.attractions,
          Colors.pink,
          () => o.seasonalPricing.count(),
          () => o.seasonalPricing.getAll(),
          (id) => o.seasonalPricing.remove(id),
          () => o.seasonalPricing.removeAll()),
      _BoxSection('Messagerie'),
      _BoxItem(
          'Message',
          Icons.message,
          Colors.blue,
          () => o.messageBox.count(),
          () => o.messageBox.getAll(),
          (id) => o.messageBox.remove(id),
          () => o.messageBox.removeAll()),
      _BoxItem(
          'Conversation',
          Icons.chat,
          Colors.green,
          () => o.conversationBox.count(),
          () => o.conversationBox.getAll(),
          (id) => o.conversationBox.remove(id),
          () => o.conversationBox.removeAll()),
      _BoxItem(
          'MessageReceipt',
          Icons.done_all,
          Colors.cyan,
          () => o.messageReceiptBox.count(),
          () => o.messageReceiptBox.getAll(),
          (id) => o.messageReceiptBox.remove(id),
          () => o.messageReceiptBox.removeAll()),
      _BoxItem(
          'ConversationParticipant',
          Icons.group,
          Colors.teal,
          () => o.conversationParticipantBox.count(),
          () => o.conversationParticipantBox.getAll(),
          (id) => o.conversationParticipantBox.remove(id),
          () => o.conversationParticipantBox.removeAll()),
      _BoxItem(
          'MessageSyncQueue',
          Icons.sync,
          Colors.orange,
          () => o.messageSyncQueueBox.count(),
          () => o.messageSyncQueueBox.getAll(),
          (id) => o.messageSyncQueueBox.remove(id),
          () => o.messageSyncQueueBox.removeAll()),
      _BoxItem(
          'MessageSearchIndex',
          Icons.search,
          Colors.indigo,
          () => o.messageSearchIndexBox.count(),
          () => o.messageSearchIndexBox.getAll(),
          (id) => o.messageSearchIndexBox.remove(id),
          () => o.messageSearchIndexBox.removeAll()),
      _BoxSection('Autres'),
      _BoxItem(
          'Annonces',
          Icons.campaign,
          Colors.red,
          () => o.annonces.count(),
          () => o.annonces.getAll(),
          (id) => o.annonces.remove(id),
          () => o.annonces.removeAll()),
      _BoxItem(
          'SwipeQueue',
          Icons.swipe,
          Colors.amber,
          () => o.swipeQueueBox.count(),
          () => o.swipeQueueBox.getAll(),
          (id) => o.swipeQueueBox.remove(id),
          () => o.swipeQueueBox.removeAll()),
      _BoxItem(
          'Match',
          Icons.favorite,
          Colors.pink,
          () => o.matchBox.count(),
          () => o.matchBox.getAll(),
          (id) => o.matchBox.remove(id),
          () => o.matchBox.removeAll()),
      _BoxItem(
          'Profile',
          Icons.account_circle,
          Colors.purple,
          () => o.profileBox.count(),
          () => o.profileBox.getAll(),
          (id) => o.profileBox.remove(id),
          () => o.profileBox.removeAll()),
    ];
  }

  List<_BoxHandle> get _filteredBoxes => _search.isEmpty
      ? _boxes
      : _boxes.where((b) {
          if (b is _BoxSection) return false;
          return b.name.toLowerCase().contains(_search.toLowerCase());
        }).toList();

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ObjectBox Data Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Vider toute la base',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une table...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: isDesktop ? _buildDesktopGrid() : _buildMobileList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopGrid() {
    final items = _filteredBoxes.whereType<_BoxItem>().toList();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _BoxCard(items[i]),
    );
  }

  Widget _buildMobileList() {
    final items = _filteredBoxes;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is _BoxSection) return _SectionHeader(item.name);
        return _BoxTile(item as _BoxItem);
      },
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Vider toute la base'),
        content: const Text(
          'ATTENTION : Cette action va supprimer TOUTES les données '
          'de toutes les tables ObjectBox.\n\n'
          'Cette opération est irréversible.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tout vider'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final objectBox = context.read<ObjectBox>();
    try {
      for (final item in _boxes) {
        if (item is _BoxItem) item.removeAll();
      }
      setState(() => _boxes = _buildBoxHandles(objectBox));
      messenger.showSnackBar(const SnackBar(content: Text('✅ Base vidée')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('❌ Erreur: ')));
    }
  }
}

// ─── Box Handle types ────────────────────────────────────────────────────────

abstract class _BoxHandle {
  String get name;
}

class _BoxSection extends _BoxHandle {
  @override
  final String name;
  _BoxSection(this.name);
}

class _BoxItem extends _BoxHandle {
  @override
  final String name;
  final IconData icon;
  final MaterialColor color;
  final int Function() count;
  final List<dynamic> Function() getAll;
  final bool Function(int) remove;
  final int Function() removeAll;

  _BoxItem(this.name, this.icon, this.color, this.count, this.getAll,
      this.remove, this.removeAll);
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1)),
    );
  }
}

class _BoxCard extends StatelessWidget {
  final _BoxItem item;
  const _BoxCard(this.item);
  @override
  Widget build(BuildContext context) {
    final count = item.count();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => _BoxDetailPage(item))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 20, color: item.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const Spacer(),
              Text('$count entité(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxTile extends StatelessWidget {
  final _BoxItem item;
  const _BoxTile(this.item);
  @override
  Widget build(BuildContext context) {
    final count = item.count();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(item.icon, color: item.color),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(count.toString(),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: count > 0 ? Colors.black87 : Colors.grey)),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => _BoxDetailPage(item))),
      ),
    );
  }
}

class _FieldEntry {
  final String name;
  final String value;
  const _FieldEntry(this.name, this.value);
}

// ─── Detail Page ─────────────────────────────────────────────────────────────

class _BoxDetailPage extends StatefulWidget {
  final _BoxItem item;
  const _BoxDetailPage(this.item);
  @override
  State<_BoxDetailPage> createState() => _BoxDetailPageState();
}

class _BoxDetailPageState extends State<_BoxDetailPage> {
  late List<dynamic> _items;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _items = widget.item.getAll();
  }

  void _refresh() {
    setState(() => _items = widget.item.getAll());
  }

  Future<void> _deleteItem(int index) async {
    final obj = _items[index];
    final id = _getId(obj);
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer #$id'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.item.remove(id);
    _refresh();
  }

  int? _getId(dynamic obj) {
    // ObjectBox entities always have an 'id' field accessible via reflection or direct property
    try {
      return (obj as dynamic).id as int?;
    } catch (_) {}
    return null;
  }

  static const _allFieldNames = <String>[
    'id',
    'nom',
    'name',
    'code',
    'title',
    'prenom',
    'shift',
    'team',
    'grade',
    'motif',
    'note',
    'status',
    'mois',
    'annee',
    'from',
    'to',
    'total',
    'username',
    'password',
    'email',
    'phone',
    'role',
    'photo',
    'qr',
    'image',
    'description',
    'prixVente',
    'tax',
    'qtyPartiel',
    'pricePartielVente',
    'minimStock',
    'alertPeremption',
    'quantite',
    'prixAchat',
    'datePeremption',
    'adresse',
    'type',
    'qrReference',
    'impayer',
    'date',
    'montantVerse',
    'prixUnitaire',
    'titre',
    'prix',
    'lien',
    'categorie',
    'floors',
    'roomsPerFloor',
    'avoidedNumbers',
    'photosJson',
    'capacity',
    'bedType',
    'standing',
    'viewType',
    'amenities',
    'basePrice',
    'seasonMultiplier',
    'weekendMultiplier',
    'allowsExtraBed',
    'extraBedPrice',
    'isActive',
    'sortOrder',
    'includesBreakfast',
    'includesLunch',
    'includesDinner',
    'includesSnacks',
    'includesDrinks',
    'includesAlcoholicDrinks',
    'includesRoomService',
    'includesMinibar',
    'pricePerPerson',
    'childDiscount',
    'notes',
    'category',
    'price',
    'pricingUnit',
    'isPercentage',
    'requiresAdvanceBooking',
    'advanceHours',
    'maxQuantity',
    'isPackage',
    'packageIncludes',
    'scheduledDate',
    'unitPrice',
    'totalPrice',
    'quantity',
    'startDate',
    'endDate',
    'multiplier',
    'applicationType',
    'targetIds',
    'priority',
    'fullName',
    'phoneNumber',
    'idCardNumber',
    'nationality',
    'discountPercent',
    'discountAmount',
    'discountType',
    'discountAppliedTo',
    'selectedDiscountItems',
    'cachedBoardBasisPrice',
    'cachedExtrasTotal',
    'seasonalMultiplier',
    'pricePerNight',
    'groupe',
    'equipe',
    'ordre',
    'jour',
    'statut',
    'branchNom',
    'debut',
    'fin',
    'dateDebut',
    'dateFin',
    'dimanche',
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'libelle',
    'couleurHex',
    'ordreEquipes',
    'activitesJson',
    'messageId',
    'conversationId',
    'fromNodeId',
    'toNodeId',
    'typeValue',
    'content',
    'mediaPath',
    'mediaSize',
    'mediaMimeType',
    'mediaDuration',
    'sentTimestamp',
    'receivedTimestamp',
    'readTimestamp',
    'statusValue',
    'replyToMessageId',
    'replyToContent',
    'replyToFromNodeId',
    'isFavorite',
    'isDeleted',
    'encryptionKeyId',
    'contentHash',
    'sendAttempts',
    'lastErrorMessage',
    'avatarPath',
    'participantNodeIds',
    'creatorNodeId',
    'createdTimestamp',
    'lastActivityTimestamp',
    'lastMessageId',
    'lastMessagePreview',
    'unreadCount',
    'messageCount',
    'isArchived',
    'isPinned',
    'isMuted',
    'lastSyncTimestamp',
    'metadata',
    'displayName',
    'nodeId',
    'joinedTimestamp',
    'leftTimestamp',
    'notificationsEnabled',
    'lastReadMessageId',
    'lastAccessTimestamp',
    'recipientNodeId',
    'confirmedTimestamp',
    'messageHash',
    'operation',
    'targetNodeIds',
    'attemptCount',
    'nextRetryTimestamp',
    'errorMessage',
    'searchContent',
    'messageTimestamp',
    'swipedId',
    'action',
    'createdAt',
    'otherUserName',
    'otherUserPhoto',
    'lastMessageAt',
    'matchedAt',
    'localId',
    'age',
    'bio',
    'photos',
    'city',
    'distanceKm',
    'branchId',
    'year',
    'month',
    'revision',
    'remoteId',
    'dateEpochMs',
    'configurationId',
    'configurationVersion',
    'phaseIndex',
    'teamPhaseByTeamJson',
    'syncState',
    'lastSyncedAtEpochMs',
    'syncError',
    'version',
    'teamOrderJson',
    'cycleJson',
    'policy',
    'referenceDateEpochMs',
    'referencePhaseIndex',
    'startDateEpochMs',
    'endDateEpochMs',
    'snapshotId',
    'staffId',
    'dateEpochMs',
    'engineVersion',
    'createdAtEpochMs',
    'publishedAtEpochMs',
    'revisionId',
    'baseSnapshotId',
    'effectiveSnapshotId',
    'modifiedAtEpochMs',
    'modifiedBy',
    'changedFieldsJson',
    'validated',
    'derniereModification',
    'isSynced',
    'syncedAt',
    'dateCreation',
    'createdBy',
    'updatedBy',
    'deletedBy',
    'dateDeleting',
    'delaisPeremption',
  ];

  static const _labelFields = <String>[
    'nom',
    'name',
    'code',
    'title',
    'prenom',
    'fullName',
    'libelle',
    'username',
    'titre',
    'branchNom',
  ];

  String _objectToString(dynamic obj) {
    final type = obj.runtimeType;
    final id = _getId(obj);
    final parts = <String>['$type#$id'];
    for (final f in _labelFields) {
      try {
        final val = _getFieldValue(obj, f);
        if (val != null && val.toString().isNotEmpty) {
          final s = val.toString();
          if (s.length > 60) break;
          parts.add('$f: $s');
          if (parts.length >= 4) break;
        }
      } catch (_) {}
    }
    for (final f in ['groupe', 'status', 'shift', 'team', 'role', 'statut']) {
      if (parts.length >= 5) break;
      try {
        final val = _getFieldValue(obj, f);
        if (val != null && val.toString().isNotEmpty) {
          parts.add(
              '$f: ${val.toString().length > 40 ? val.toString().substring(0, 40) : val}');
        }
      } catch (_) {}
    }
    return parts.join(' | ');
  }

  dynamic _getFieldValue(dynamic obj, String name) {
    try {
      final val = (obj as dynamic).$name;
      if (val == null) return null;
      // Check if it's a ToOne relation
      try {
        final targetId = (val as dynamic).targetId;
        final target = (val as dynamic).target;
        if (target != null) {
          final label = _firstLabel(target);
          return label.isNotEmpty
              ? '$name: $label (#$targetId)'
              : '$name: #$targetId';
        }
        if (targetId is int && targetId > 0) return '#$targetId';
        return null;
      } catch (_) {
        // Check if it's a ToMany
        try {
          final list = (val as dynamic).toList();
          return '[${list.length}]';
        } catch (_2) {
          return val;
        }
      }
    } catch (_) {
      return null;
    }
  }

  String _firstLabel(dynamic target) {
    for (final f in _labelFields) {
      try {
        final val = _getFieldValue(target, f);
        if (val != null && val.toString().isNotEmpty) return val.toString();
      } catch (_) {}
    }
    return '';
  }

  List<_FieldEntry> _allFields(dynamic obj) {
    final entries = <_FieldEntry>[];
    for (final f in _allFieldNames) {
      try {
        final val = _getFieldValue(obj, f);
        if (val != null && val.toString().isNotEmpty) {
          entries.add(_FieldEntry(f, val.toString()));
        }
      } catch (_) {}
    }
    return entries;
  }

  Future<void> _clearBox() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vider ${widget.item.name}'),
        content: Text('Supprimer les ${_items.length} entité(s) ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.item.removeAll();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final count = _items.length;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.item.icon, color: widget.item.color, size: 20),
            const SizedBox(width: 6),
            Flexible(
                child: Text('${widget.item.name} ($count)',
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (widget.item.name == 'Staff')
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Nouveau Staff',
              onPressed: _createStaff,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vider cette table',
            onPressed: count > 0 ? _clearBox : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: count == 0
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Table vide',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16)),
                  ],
                ),
              )
            : isDesktop
                ? _buildDesktopGrid()
                : _buildMobileList(),
      ),
    );
  }

  Widget _buildDesktopGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (_, i) => _buildItemCard(i),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (_, i) => _buildItemCard(i),
    );
  }

  // ─── Staff CRUD ──────────────────────────────────────────────────────────

  Future<void> _editStaff(Staff staff) async {
    final nomCtrl = TextEditingController(text: staff.nom);
    final gradeCtrl = TextEditingController(text: staff.grade);
    final groupeCtrl = TextEditingController(text: staff.groupe);
    final equipeCtrl = TextEditingController(text: staff.equipe ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.words),
              const SizedBox(height: 8),
              TextField(
                  controller: gradeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Grade', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: groupeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Groupe', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: equipeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Équipe', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    staff.nom = nomCtrl.text.trim();
    staff.grade = gradeCtrl.text.trim();
    staff.groupe = groupeCtrl.text.trim();
    staff.equipe =
        equipeCtrl.text.trim().isEmpty ? null : equipeCtrl.text.trim();
    context.read<ObjectBox>().staffBox.put(staff);
    _refresh();
  }

  static const _legendMotifs = <String>[
    'GJ',
    'GN',
    'RE',
    'C',
    'CM',
    'M',
    'N',
    'F',
  ];
  static const _legendLabels = <String, String>{
    'GJ': 'Jour',
    'GN': 'Nuit',
    'RE': 'Récupération',
    'C': 'Congé',
    'CM': 'Congé Maladie',
    'M': 'Maternité',
    'N': 'Normal',
    'F': 'Jour Férié',
  };

  Future<void> _addTimeOff(Staff staff) async {
    final debutCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0]);
    final finCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0]);
    String? selectedMotif;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Ajouter un congé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: debutCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Début (AAAA-MM-JJ)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: finCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fin (AAAA-MM-JJ)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedMotif,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.beach_access),
                ),
                items: _legendMotifs
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text('$code — ${_legendLabels[code] ?? code}'),
                        ))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedMotif = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ajouter')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final objectBox = context.read<ObjectBox>();
    final timeOff = TimeOff(
      debut: DateTime.tryParse(debutCtrl.text) ?? DateTime.now(),
      fin: DateTime.tryParse(finCtrl.text) ?? DateTime.now(),
      motif: selectedMotif,
    );
    timeOff.staff.target = staff;
    objectBox.timeOffBox.put(timeOff);
    _loadTimeOff(staff);
  }

  Future<void> _editTimeOff(TimeOff to, Staff staff) async {
    final debutCtrl =
        TextEditingController(text: to.debut.toIso8601String().split('T')[0]);
    final finCtrl =
        TextEditingController(text: to.fin.toIso8601String().split('T')[0]);
    String? selectedMotif = to.motif;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Modifier le congé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: debutCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Début (AAAA-MM-JJ)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: finCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fin (AAAA-MM-JJ)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedMotif,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.beach_access),
                ),
                items: _legendMotifs
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text('$code — ${_legendLabels[code] ?? code}'),
                        ))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedMotif = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enregistrer')),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    to.debut = DateTime.tryParse(debutCtrl.text) ?? to.debut;
    to.fin = DateTime.tryParse(finCtrl.text) ?? to.fin;
    to.motif = selectedMotif;
    context.read<ObjectBox>().timeOffBox.put(to);
    _loadTimeOff(staff);
  }

  Future<void> _deleteTimeOff(TimeOff to, Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer le congé'),
        content: Text(
            'Du ${to.debut.day}/${to.debut.month}/${to.debut.year} au ${to.fin.day}/${to.fin.month}/${to.fin.year}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<ObjectBox>().timeOffBox.remove(to.id);
    _loadTimeOff(staff);
  }

  Future<void> _createStaff() async {
    final nomCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final groupeCtrl = TextEditingController();
    final equipeCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nom', border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.words),
              const SizedBox(height: 8),
              TextField(
                  controller: gradeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Grade', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: groupeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Groupe', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: equipeCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Équipe', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer')),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    final staff = Staff(
      nom: nomCtrl.text.trim(),
      grade: gradeCtrl.text.trim(),
      groupe: groupeCtrl.text.trim(),
      equipe: equipeCtrl.text.trim().isEmpty ? null : equipeCtrl.text.trim(),
    );
    context.read<ObjectBox>().staffBox.put(staff);
    _refresh();
  }

  Widget _buildItemCard(int index) {
    final obj = _items[index];
    final id = _getId(obj);
    final str = _objectToString(obj);
    final isExpanded = _expandedIndex == index;
    final isStaff = widget.item.name == 'Staff' && obj is Staff;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.item.color.withValues(alpha: 0.15),
              child: Text('#$id',
                  style: TextStyle(
                      fontSize: 12,
                      color: widget.item.color,
                      fontWeight: FontWeight.bold)),
            ),
            title: isStaff
                ? Text('${obj.nom}${obj.equipe != null ? ' (${obj.equipe})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))
                : Text(str.length > 80 ? '${str.substring(0, 80)}...' : str,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
            subtitle: isStaff
                ? Text(obj.grade,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStaff)
                  IconButton(
                    icon:
                        Icon(Icons.edit, size: 20, color: Colors.blue.shade400),
                    onPressed: () => _editStaff(obj),
                  ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20),
                  onPressed: () => setState(() {
                    _expandedIndex = isExpanded ? null : index;
                    if (isStaff) _loadTimeOff(obj);
                  }),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.red.shade400),
                  onPressed: () => _deleteItem(index),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            _buildEntityDetails(obj),
            if (isStaff) _buildStaffTimeOff(obj),
          ],
        ],
      ),
    );
  }

  Widget _buildEntityDetails(dynamic obj) {
    final fields = _allFields(obj);
    if (fields.isEmpty) return const SizedBox.shrink();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: fields.map((f) => _buildFieldChip(f)).toList(),
            )
          else
            ...fields.map((f) => _buildFieldRow(f)),
        ],
      ),
    );
  }

  Widget _buildFieldChip(_FieldEntry f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${f.name}: ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800)),
          Flexible(
              child: SelectableText(f.value,
                  style:
                      const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
        ],
      ),
    );
  }

  Widget _buildFieldRow(_FieldEntry f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text('${f.name}:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800)),
          ),
          Expanded(
              child: SelectableText(f.value,
                  style:
                      const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        ],
      ),
    );
  }

  List<TimeOff>? _staffTimeOff;

  void _loadTimeOff(Staff staff) {
    final timeOffs = context
        .read<ObjectBox>()
        .timeOffBox
        .query(TimeOff_.staff.equals(staff.id))
        .build()
        .find();
    setState(() => _staffTimeOff = timeOffs);
  }

  Widget _buildStaffTimeOff(Staff staff) {
    final timeOffs = _staffTimeOff ?? <TimeOff>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.beach_access, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Text('Congés (${timeOffs.length})',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.orange.shade800)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
                onPressed: () => _addTimeOff(staff),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
          if (timeOffs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucun congé',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            )
          else
            ...timeOffs.map((to) => _buildTimeOffTile(to, staff)),
        ],
      ),
    );
  }

  Widget _buildTimeOffTile(TimeOff to, Staff staff) {
    final from =
        '${to.debut.day.toString().padLeft(2, '0')}/${to.debut.month.toString().padLeft(2, '0')}/${to.debut.year}';
    final until =
        '${to.fin.day.toString().padLeft(2, '0')}/${to.fin.month.toString().padLeft(2, '0')}/${to.fin.year}';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$from → $until',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                if (to.motif != null && to.motif!.isNotEmpty)
                  Text(to.motif!,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade300),
            onPressed: () => _editTimeOff(to, staff),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                size: 16, color: Colors.red.shade300),
            onPressed: () => _deleteTimeOff(to, staff),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
