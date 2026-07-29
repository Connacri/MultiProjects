import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../objectBox/classeObjectBox.dart';

class ObjectBoxDataViewerPage extends StatefulWidget {
  const ObjectBoxDataViewerPage({super.key});

  @override
  State<ObjectBoxDataViewerPage> createState() => _ObjectBoxDataViewerPageState();
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
      _BoxItem('Staff', Icons.people, Colors.blue, () => o.staffBox.count(), () => o.staffBox.getAll(), (id) => o.staffBox.remove(id), () => o.staffBox.removeAll()),
      _BoxItem('ActiviteJour', Icons.event, Colors.indigo, () => o.activiteBox.count(), () => o.activiteBox.getAll(), (id) => o.activiteBox.remove(id), () => o.activiteBox.removeAll()),
      _BoxItem('Branch', Icons.business, Colors.brown, () => o.branchBox.count(), () => o.branchBox.getAll(), (id) => o.branchBox.remove(id), () => o.branchBox.removeAll()),
      _BoxItem('TimeOff', Icons.beach_access, Colors.orange, () => o.timeOffBox.count(), () => o.timeOffBox.getAll(), (id) => o.timeOffBox.remove(id), () => o.timeOffBox.removeAll()),
      _BoxItem('Planification', Icons.calendar_month, Colors.red, () => o.planificationBox.count(), () => o.planificationBox.getAll(), (id) => o.planificationBox.remove(id), () => o.planificationBox.removeAll()),
      _BoxItem('PlanningHebdo', Icons.calendar_view_week, Colors.purple, () => o.planningHebdoBox.count(), () => o.planningHebdoBox.getAll(), (id) => o.planningHebdoBox.remove(id), () => o.planningHebdoBox.removeAll()),
      _BoxItem('TypeActivite', Icons.category, Colors.teal, () => o.typeActiviteBox.count(), () => o.typeActiviteBox.getAll(), (id) => o.typeActiviteBox.remove(id), () => o.typeActiviteBox.removeAll()),

      _BoxSection('Planning (nouvelle archi)'),
      _BoxItem('PlanningSnapshot', Icons.camera, Colors.deepPurple, () => o.planningSnapshotBox.count(), () => o.planningSnapshotBox.getAll(), (id) => o.planningSnapshotBox.remove(id), () => o.planningSnapshotBox.removeAll()),
      _BoxItem('PlanningAssignment', Icons.assignment, Colors.deepOrange, () => o.planningAssignmentBox.count(), () => o.planningAssignmentBox.getAll(), (id) => o.planningAssignmentBox.remove(id), () => o.planningAssignmentBox.removeAll()),
      _BoxItem('RotationState', Icons.rotate_right, Colors.cyan, () => o.rotationStateSnapshotBox.count(), () => o.rotationStateSnapshotBox.getAll(), (id) => o.rotationStateSnapshotBox.remove(id), () => o.rotationStateSnapshotBox.removeAll()),

      _BoxSection('POS / Commerce'),
      _BoxItem('Usero', Icons.person, Colors.grey, () => o.userBox.count(), () => o.userBox.getAll(), (id) => o.userBox.remove(id), () => o.userBox.removeAll()),
      _BoxItem('Crud', Icons.shopping_cart, Colors.amber, () => o.crudBox.count(), () => o.crudBox.getAll(), (id) => o.crudBox.remove(id), () => o.crudBox.removeAll()),
      _BoxItem('Produit', Icons.inventory_2, Colors.green, () => o.produitBox.count(), () => o.produitBox.getAll(), (id) => o.produitBox.remove(id), () => o.produitBox.removeAll()),
      _BoxItem('Approvisionnement', Icons.local_shipping, Colors.brown, () => o.approvisionnementBox.count(), () => o.approvisionnementBox.getAll(), (id) => o.approvisionnementBox.remove(id), () => o.approvisionnementBox.removeAll()),
      _BoxItem('Fournisseur', Icons.store, Colors.orange, () => o.fournisseurBox.count(), () => o.fournisseurBox.getAll(), (id) => o.fournisseurBox.remove(id), () => o.fournisseurBox.removeAll()),
      _BoxItem('Facture', Icons.receipt_long, Colors.red, () => o.factureBox.count(), () => o.factureBox.getAll(), (id) => o.factureBox.remove(id), () => o.factureBox.removeAll()),
      _BoxItem('LigneFacture', Icons.receipt, Colors.deepOrange, () => o.ligneFacture.count(), () => o.ligneFacture.getAll(), (id) => o.ligneFacture.remove(id), () => o.ligneFacture.removeAll()),
      _BoxItem('Client', Icons.people_outline, Colors.indigo, () => o.clientBox.count(), () => o.clientBox.getAll(), (id) => o.clientBox.remove(id), () => o.clientBox.removeAll()),
      _BoxItem('DeletedProduct', Icons.delete_outline, Colors.grey, () => o.deletedProduct.count(), () => o.deletedProduct.getAll(), (id) => o.deletedProduct.remove(id), () => o.deletedProduct.removeAll()),

      _BoxSection('Hôtel'),
      _BoxItem('Hotel', Icons.hotel, Colors.amber, () => o.hotelBox.count(), () => o.hotelBox.getAll(), (id) => o.hotelBox.remove(id), () => o.hotelBox.removeAll()),
      _BoxItem('Room', Icons.room, Colors.blue, () => o.roomBox.count(), () => o.roomBox.getAll(), (id) => o.roomBox.remove(id), () => o.roomBox.removeAll()),
      _BoxItem('Guest', Icons.people, Colors.teal, () => o.guestBox.count(), () => o.guestBox.getAll(), (id) => o.guestBox.remove(id), () => o.guestBox.removeAll()),
      _BoxItem('Employee', Icons.badge, Colors.brown, () => o.employeeBox.count(), () => o.employeeBox.getAll(), (id) => o.employeeBox.remove(id), () => o.employeeBox.removeAll()),
      _BoxItem('RoomCategory', Icons.category, Colors.purple, () => o.roomCategory.count(), () => o.roomCategory.getAll(), (id) => o.roomCategory.remove(id), () => o.roomCategory.removeAll()),
      _BoxItem('BoardBasis', Icons.restaurant, Colors.orange, () => o.boardBasis.count(), () => o.boardBasis.getAll(), (id) => o.boardBasis.remove(id), () => o.boardBasis.removeAll()),
      _BoxItem('ExtraService', Icons.miscellaneous_services, Colors.cyan, () => o.extraService.count(), () => o.extraService.getAll(), (id) => o.extraService.remove(id), () => o.extraService.removeAll()),
      _BoxItem('ReservationExtra', Icons.topic, Colors.lightGreen, () => o.reservationExtra.count(), () => o.reservationExtra.getAll(), (id) => o.reservationExtra.remove(id), () => o.reservationExtra.removeAll()),
      _BoxItem('SeasonalPricing', Icons.attractions, Colors.pink, () => o.seasonalPricing.count(), () => o.seasonalPricing.getAll(), (id) => o.seasonalPricing.remove(id), () => o.seasonalPricing.removeAll()),

      _BoxSection('Messagerie'),
      _BoxItem('Message', Icons.message, Colors.blue, () => o.messageBox.count(), () => o.messageBox.getAll(), (id) => o.messageBox.remove(id), () => o.messageBox.removeAll()),
      _BoxItem('Conversation', Icons.chat, Colors.green, () => o.conversationBox.count(), () => o.conversationBox.getAll(), (id) => o.conversationBox.remove(id), () => o.conversationBox.removeAll()),
      _BoxItem('MessageReceipt', Icons.done_all, Colors.cyan, () => o.messageReceiptBox.count(), () => o.messageReceiptBox.getAll(), (id) => o.messageReceiptBox.remove(id), () => o.messageReceiptBox.removeAll()),
      _BoxItem('ConversationParticipant', Icons.group, Colors.teal, () => o.conversationParticipantBox.count(), () => o.conversationParticipantBox.getAll(), (id) => o.conversationParticipantBox.remove(id), () => o.conversationParticipantBox.removeAll()),
      _BoxItem('MessageSyncQueue', Icons.sync, Colors.orange, () => o.messageSyncQueueBox.count(), () => o.messageSyncQueueBox.getAll(), (id) => o.messageSyncQueueBox.remove(id), () => o.messageSyncQueueBox.removeAll()),
      _BoxItem('MessageSearchIndex', Icons.search, Colors.indigo, () => o.messageSearchIndexBox.count(), () => o.messageSearchIndexBox.getAll(), (id) => o.messageSearchIndexBox.remove(id), () => o.messageSearchIndexBox.removeAll()),

      _BoxSection('Autres'),
      _BoxItem('Annonces', Icons.campaign, Colors.red, () => o.annonces.count(), () => o.annonces.getAll(), (id) => o.annonces.remove(id), () => o.annonces.removeAll()),
      _BoxItem('SwipeQueue', Icons.swipe, Colors.amber, () => o.swipeQueueBox.count(), () => o.swipeQueueBox.getAll(), (id) => o.swipeQueueBox.remove(id), () => o.swipeQueueBox.removeAll()),
      _BoxItem('Match', Icons.favorite, Colors.pink, () => o.matchBox.count(), () => o.matchBox.getAll(), (id) => o.matchBox.remove(id), () => o.matchBox.removeAll()),
      _BoxItem('Profile', Icons.account_circle, Colors.purple, () => o.profileBox.count(), () => o.profileBox.getAll(), (id) => o.profileBox.remove(id), () => o.profileBox.removeAll()),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
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

  _BoxItem(this.name, this.icon, this.color, this.count, this.getAll, this.remove, this.removeAll);
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
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
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _BoxDetailPage(item))),
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
                    child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const Spacer(),
              Text('$count entité(s)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text('', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: count > 0 ? Colors.black87 : Colors.grey)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _BoxDetailPage(item))),
      ),
    );
  }
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
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

  String _objectToString(dynamic obj) {
    final type = obj.runtimeType;
    final id = _getId(obj);
    final parts = <String>['$type#$id'];
    for (final f in ['nom', 'name', 'code', 'title', 'prenom', 'shift',
        'team', 'grade', 'motif', 'note', 'status', 'mois', 'annee',
        'room', 'from', 'to', 'total']) {
      try {
        final val = _getField(obj, f);
        if (val != null && val.toString().isNotEmpty) {
          parts.add('$f: $val');
          if (parts.length >= 4) break;
        }
      } catch (_) {}
    }
    return parts.join(' | ');
  }

  dynamic _getField(dynamic obj, String name) {
    switch (name) {
      case 'nom': return (obj).nom;
      case 'name': return (obj).name;
      case 'code': return (obj).code;
      case 'title': return (obj).title;
      case 'prenom': return (obj).prenom;
      case 'shift': return (obj).shift;
      case 'team': return (obj).team;
      case 'grade': return (obj).grade;
      case 'motif': return (obj).motif;
      case 'note': return (obj).note;
      case 'status': return (obj).status;
      case 'mois': return (obj).mois;
      case 'annee': return (obj).annee;
      case 'room': return (obj).room;
      case 'from': return (obj).from;
      case 'to': return (obj).to;
      case 'total': return (obj).total;
    }
    return null;
  }

  Future<void> _clearBox() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vider ${widget.item.name}'),
        content: Text('Supprimer les ${_items.length} entité(s) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
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
            Icon(widget.item.icon, color: widget.item.color),
            const SizedBox(width: 8),
            Text(' ()'),
          ],
        ),
        actions: [
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
                    Text('Table vide', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
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

  Widget _buildItemCard(int index) {
    final obj = _items[index];
    final id = _getId(obj);
    final str = _objectToString(obj);
    final isExpanded = _expandedIndex == index;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.item.color.withValues(alpha: 0.15),
              child: Text('#$id', style: TextStyle(fontSize: 12, color: widget.item.color, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              str.length > 80 ? '${str.substring(0, 80)}...' : str,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                  onPressed: () => setState(() => _expandedIndex = isExpanded ? null : index),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                  onPressed: () => _deleteItem(index),
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SelectableText(
                str,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }
}
