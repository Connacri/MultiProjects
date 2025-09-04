import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Entity.dart';
import 'claude.dart';
import 'provider_hotel.dart';

class RoomCategoryListScreen extends StatelessWidget {
  const RoomCategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories de Chambres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoomCategoryFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final categories = provider.roomCategories;
          if (categories.isEmpty) {
            return const Center(
              child: Text('Aucune catégorie de chambre trouvée.'),
            );
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RoomCategoryDetailScreen(category: category),
                      ),
                    );
                  },
                  title: Text(category.name),
                  subtitle:
                      Text('${category.standing} • ${category.basePrice} DA'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RoomCategoryFormScreen(category: category),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer'),
                              content: const Text(
                                  'Voulez-vous vraiment supprimer cette catégorie ?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await provider.deleteRoomCategory(category.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Catégorie supprimée avec succès.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RoomCategoryDetailScreen extends StatelessWidget {
  final RoomCategory category;

  const RoomCategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // ⚡ Relation ObjectBox
    final rooms = category.rooms;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(category.name),
              background: Container(
                color: Colors.blueGrey.shade200,
                child: const Icon(Icons.hotel, size: 100, color: Colors.white),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: const Text("Standing"),
                subtitle: Text(category.standing),
              ),
              ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.green),
                title: const Text("Prix de base"),
                subtitle: Text("${category.basePrice} DA"),
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text("Description"),
                subtitle: Text(category.description ?? "Pas de description"),
              ),
              ListTile(
                leading: const Icon(Icons.chair, color: Colors.brown),
                title: const Text("Nombre de lits"),
                subtitle: Text("${category.capacity ?? 0} lits"),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Chambres assignées",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (rooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Aucune chambre assignée à cette catégorie."),
                )
              else
                ...rooms.map((room) => Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.meeting_room,
                            color: Colors.indigo),
                        title: Text("Chambre ${room.code}"),
                        subtitle: Text("ID interne: ${room.id}"),
                        trailing: Text(
                          room.status ?? "Libre",
                          style: TextStyle(
                            color: (room.status ?? "Libre") == "Occupée"
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        onTap: () {
                          // ⚡ si tu veux afficher un détail de la chambre
                        },
                      ),
                    )),
            ]),
          ),
        ],
      ),
    );
  }
}

class RoomCategoryFormScreen extends StatefulWidget {
  final RoomCategory? category;

  const RoomCategoryFormScreen({super.key, this.category});

  @override
  State<RoomCategoryFormScreen> createState() => _RoomCategoryFormScreenState();
}

class _RoomCategoryFormScreenState extends State<RoomCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _code;
  late String _description;
  late String _bedType;
  late int _capacity;
  late String _standing;
  late double _basePrice;
  late bool _allowsExtraBed;
  late double? _extraBedPrice;
  late List<String> _selectedAmenities = [];
  List<Room> _selectedRooms = []; // Chambres sélectionnées pour cette catégorie
  List<Room> _allRooms = []; // Toutes les chambres disponibles

  @override
  void initState() {
    super.initState();
    // ... initialisation des autres variables
    _allRooms = Provider.of<HotelProvider>(context, listen: false).rooms;
    if (widget.category != null) {
      // Charger les chambres déjà assignées à cette catégorie
      _selectedRooms = _allRooms
          .where((room) => room.category.target?.id == widget.category!.id)
          .toList();
    }

    if (widget.category != null) {
      _name = widget.category!.name;
      _code = widget.category!.code;
      _description = widget.category!.description;
      _bedType = widget.category!.bedType;
      _capacity = widget.category!.capacity;
      _standing = widget.category!.standing;
      _basePrice = widget.category!.basePrice;
      _allowsExtraBed = widget.category!.allowsExtraBed;
      _extraBedPrice = widget.category!.extraBedPrice;
      _selectedAmenities = widget.category!.amenitiesList;
    } else {
      _name = '';
      _code = '';
      _description = '';
      _bedType = 'Single';
      _capacity = 1;
      _standing = 'Economy';
      _basePrice = 0;
      _allowsExtraBed = false;
      _extraBedPrice = null;
      _selectedAmenities = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null
            ? 'Ajouter une Catégorie'
            : 'Modifier la Catégorie'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _code,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un code.';
                  }
                  return null;
                },
                onSaved: (value) => _code = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
              ),
              DropdownButtonFormField<String>(
                value: _bedType,
                items: ['Single', 'Double', 'Twin', 'King', 'King + Sofa']
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => _bedType = value!,
                decoration: const InputDecoration(labelText: 'Type de lit'),
              ),
              TextFormField(
                initialValue: _capacity.toString(),
                decoration: const InputDecoration(labelText: 'Capacité'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une capacité.';
                  }
                  return null;
                },
                onSaved: (value) => _capacity = int.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _standing,
                items: ['Economy', 'Standard', 'Superior', 'Deluxe', 'Suite']
                    .map((standing) => DropdownMenuItem(
                        value: standing, child: Text(standing)))
                    .toList(),
                onChanged: (value) => _standing = value!,
                decoration: const InputDecoration(labelText: 'Standing'),
              ),
              TextFormField(
                initialValue: _basePrice.toString(),
                decoration:
                    const InputDecoration(labelText: 'Prix de base (DA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix.';
                  }
                  return null;
                },
                onSaved: (value) => _basePrice = double.parse(value!),
              ),
              SwitchListTile(
                title: const Text('Autoriser lit supplémentaire'),
                value: _allowsExtraBed,
                onChanged: (value) => setState(() => _allowsExtraBed = value),
              ),
              if (_allowsExtraBed)
                TextFormField(
                  initialValue: _extraBedPrice?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Prix du lit supplémentaire (DA)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) =>
                      _extraBedPrice = double.tryParse(value ?? ''),
                ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Équipements (séparés par des virgules)',
                ),
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _selectedAmenities =
                        value.split(',').map((e) => e.trim()).toList();
                  }
                },
              ),
              const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () async {
              //     if (_formKey.currentState!.validate()) {
              //       _formKey.currentState!.save();
              //       final provider =
              //           Provider.of<HotelProvider>(context, listen: false);
              //       final category = RoomCategory(
              //         name: _name,
              //         code: _code,
              //         description: _description,
              //         bedType: _bedType,
              //         capacity: _capacity,
              //         standing: _standing,
              //         basePrice: _basePrice,
              //         allowsExtraBed: _allowsExtraBed,
              //         extraBedPrice: _extraBedPrice ?? 0.0,
              //       )
              //         ..id = widget.category?.id ??
              //             0 // Définir id après la création
              //         // ..amenities = widget.category?.amenities ?? '[]'
              //         ..setAmenities(_selectedAmenities) // Utiliser le helper
              //         ..seasonMultiplier =
              //             widget.category?.seasonMultiplier ?? 1.0
              //         ..weekendMultiplier =
              //             widget.category?.weekendMultiplier ?? 1.0
              //         ..isActive = widget.category?.isActive ?? true
              //         ..sortOrder = widget.category?.sortOrder ?? 0;
              //
              //       if (widget.category == null) {
              //         await provider.addRoomCategory(category);
              //       } else {
              //         await provider.updateRoomCategory(category);
              //       }
              //       if (mounted) {
              //         Navigator.pop(context);
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(
              //             content: Text(
              //               widget.category == null
              //                   ? 'Catégorie ajoutée avec succès.'
              //                   : 'Catégorie mise à jour avec succès.',
              //             ),
              //           ),
              //         );
              //       }
              //     }
              //   },
              //   child: const Text('Enregistrer'),
              // ),
              // ... autres champs du formulaire
              const Divider(),
              const Text(
                'Chambres assignées à cette catégorie',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Liste des chambres sélectionnées
              Wrap(
                spacing: 8,
                children: _selectedRooms
                    .map((room) => Chip(
                          label: Text('${room.code}'),
                          onDeleted: () {
                            setState(() {
                              _selectedRooms.remove(room);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Bouton pour ajouter des chambres
              ElevatedButton(
                onPressed: () async {
                  final selected = await showDialog<List<Room>>(
                    context: context,
                    builder: (context) => RoomSelectionDialog(
                      allRooms: _allRooms,
                      selectedRooms: _selectedRooms,
                    ),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedRooms = selected;
                    });
                  }
                },
                child: const Text('Sélectionner des Chambres'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final provider =
                        Provider.of<HotelProvider>(context, listen: false);
                    final category = RoomCategory(
                      name: _name,
                      code: _code,
                      description: _description,
                      bedType: _bedType,
                      capacity: _capacity,
                      standing: _standing,
                      basePrice: _basePrice,
                      allowsExtraBed: _allowsExtraBed,
                      extraBedPrice: _extraBedPrice ?? 0.0,
                    )
                      ..id = widget.category?.id ?? 0
                      ..setAmenities(_selectedAmenities)
                      ..seasonMultiplier =
                          widget.category?.seasonMultiplier ?? 1.0
                      ..weekendMultiplier =
                          widget.category?.weekendMultiplier ?? 1.0
                      ..isActive = widget.category?.isActive ?? true
                      ..sortOrder = widget.category?.sortOrder ?? 0;

                    // Sauvegarder la catégorie
                    final categoryId = widget.category == null
                        ? await provider.addRoomCategory(category)
                        : await provider.updateRoomCategory(category)
                            ? category.id
                            : 0;

                    // Assigner les chambres sélectionnées à la catégorie
                    for (final room in _selectedRooms) {
                      room.category.target = category;
                      await provider.updateRoom(room);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.category == null
                                ? 'Catégorie ajoutée avec succès.'
                                : 'Catégorie mise à jour avec succès.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoardBasisListScreen extends StatelessWidget {
  const BoardBasisListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans de Pension'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BoardBasisFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final boardBasisList = provider.boardBasis;
          if (boardBasisList.isEmpty) {
            return const Center(
              child: Text('Aucun plan de pension trouvé.'),
            );
          }
          return ListView.builder(
            itemCount: boardBasisList.length,
            itemBuilder: (context, index) {
              final boardBasis = boardBasisList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(boardBasis.name),
                  subtitle: Text('${boardBasis.pricePerPerson} DA/pers.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BoardBasisFormScreen(boardBasis: boardBasis),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer'),
                              content: const Text(
                                  'Voulez-vous vraiment supprimer ce plan ?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await provider.deleteBoardBasis(boardBasis.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Plan supprimé avec succès.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RoomSelectionDialog extends StatefulWidget {
  final List<Room> allRooms;
  final List<Room> selectedRooms;

  const RoomSelectionDialog({
    super.key,
    required this.allRooms,
    required this.selectedRooms,
  });

  @override
  State<RoomSelectionDialog> createState() => _RoomSelectionDialogState();
}

class _RoomSelectionDialogState extends State<RoomSelectionDialog> {
  late List<Room> _selectedRooms;

  @override
  void initState() {
    super.initState();
    _selectedRooms = List.from(widget.selectedRooms);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner des Chambres'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.allRooms.length,
          itemBuilder: (context, index) {
            final room = widget.allRooms[index];
            final isSelected = _selectedRooms.contains(room);

            return CheckboxListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chambre ${room.code}'),
                  room.category.target == null
                      ? const Text('')
                      : Text('Cat : ${room.category.target!.name}'),
                ],
              ),
              subtitle: Text('Capacité: ${room.category.target!.capacity}'),
              value: isSelected,
              onChanged: (value) async {
                if (value == true) {
                  if (room.category.target != null) {
                    // 🔔 Confirmation si déjà assignée
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Chambre déjà assignée'),
                        content: Text(
                          'La chambre ${room.code} est déjà affectée à la catégorie '
                          '${room.category.target!.name}. Voulez-vous la réassigner ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Réassigner'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      setState(() => _selectedRooms.add(room));
                    }
                  } else {
                    setState(() => _selectedRooms.add(room));
                  }
                } else {
                  setState(() => _selectedRooms.remove(room));
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedRooms),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class BoardBasisFormScreen extends StatefulWidget {
  final BoardBasis? boardBasis;

  const BoardBasisFormScreen({super.key, this.boardBasis});

  @override
  State<BoardBasisFormScreen> createState() => _BoardBasisFormScreenState();
}

class _BoardBasisFormScreenState extends State<BoardBasisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _code;
  late String _description;
  late double _pricePerPerson;
  late double _childDiscount;
  late bool _includesBreakfast;
  late bool _includesLunch;
  late bool _includesDinner;

  @override
  void initState() {
    super.initState();
    if (widget.boardBasis != null) {
      _name = widget.boardBasis!.name;
      _code = widget.boardBasis!.code;
      _description = widget.boardBasis!.description;
      _pricePerPerson = widget.boardBasis!.pricePerPerson;
      _childDiscount = widget.boardBasis!.childDiscount;
      _includesBreakfast = widget.boardBasis!.includesBreakfast;
      _includesLunch = widget.boardBasis!.includesLunch;
      _includesDinner = widget.boardBasis!.includesDinner;
    } else {
      _name = '';
      _code = '';
      _description = '';
      _pricePerPerson = 0;
      _childDiscount = 0;
      _includesBreakfast = false;
      _includesLunch = false;
      _includesDinner = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.boardBasis == null ? 'Ajouter un Plan' : 'Modifier le Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _code,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un code.';
                  }
                  return null;
                },
                onSaved: (value) => _code = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: _pricePerPerson.toString(),
                decoration:
                    const InputDecoration(labelText: 'Prix par personne (DA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix.';
                  }
                  return null;
                },
                onSaved: (value) => _pricePerPerson = double.parse(value!),
              ),
              TextFormField(
                initialValue: _childDiscount.toString(),
                decoration: const InputDecoration(
                    labelText: 'Réduction enfant (0.0-1.0)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _childDiscount = double.parse(value!),
              ),
              SwitchListTile(
                title: const Text('Inclut le petit-déjeuner'),
                value: _includesBreakfast,
                onChanged: (value) =>
                    setState(() => _includesBreakfast = value),
              ),
              SwitchListTile(
                title: const Text('Inclut le déjeuner'),
                value: _includesLunch,
                onChanged: (value) => setState(() => _includesLunch = value),
              ),
              SwitchListTile(
                title: const Text('Inclut le dîner'),
                value: _includesDinner,
                onChanged: (value) => setState(() => _includesDinner = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final provider =
                        Provider.of<HotelProvider>(context, listen: false);

                    // Créer l'objet BoardBasis sans id dans le constructeur
                    final boardBasis = BoardBasis(
                      name: _name,
                      code: _code,
                      description: _description,
                      pricePerPerson: _pricePerPerson,
                      childDiscount: _childDiscount,
                      includesBreakfast: _includesBreakfast,
                      includesLunch: _includesLunch,
                      includesDinner: _includesDinner,
                    )..id = widget.boardBasis?.id ??
                        0; // Définir id après la création

                    if (widget.boardBasis == null) {
                      await provider.addBoardBasis(boardBasis);
                    } else {
                      await provider.updateBoardBasis(boardBasis);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.boardBasis == null
                                ? 'Plan ajouté avec succès.'
                                : 'Plan mis à jour avec succès.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtraServiceListScreen extends StatelessWidget {
  const ExtraServiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services Supplémentaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExtraServiceFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final extraServices = provider.extraServices;
          if (extraServices.isEmpty) {
            return const Center(
              child: Text('Aucun service supplémentaire trouvé.'),
            );
          }
          return ListView.builder(
            itemCount: extraServices.length,
            itemBuilder: (context, index) {
              final extraService = extraServices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(extraService.name),
                  subtitle: Text(
                      '${extraService.price} DA • ${extraService.category}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExtraServiceFormScreen(
                                  extraService: extraService),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer'),
                              content: const Text(
                                  'Voulez-vous vraiment supprimer ce service ?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await provider.deleteExtraService(extraService.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Service supprimé avec succès.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ExtraServiceFormScreen extends StatefulWidget {
  final ExtraService? extraService;

  const ExtraServiceFormScreen({super.key, this.extraService});

  @override
  State<ExtraServiceFormScreen> createState() => _ExtraServiceFormScreenState();
}

class _ExtraServiceFormScreenState extends State<ExtraServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _code;
  late String _description;
  late String _category;
  late double _price;
  late String _pricingUnit;
  late bool _requiresAdvanceBooking;
  late int? _advanceHours;
  late int? _maxQuantity;
  late bool _isPackage;
  late String? _packageIncludes;

  @override
  void initState() {
    super.initState();
    if (widget.extraService != null) {
      _name = widget.extraService!.name;
      _code = widget.extraService!.code;
      _description = widget.extraService!.description;
      _category = widget.extraService!.category;
      _price = widget.extraService!.price;
      _pricingUnit = widget.extraService!.pricingUnit;
      _requiresAdvanceBooking = widget.extraService!.requiresAdvanceBooking;
      _advanceHours = widget.extraService!.advanceHours;
      _maxQuantity = widget.extraService!.maxQuantity;
      _isPackage = widget.extraService!.isPackage;
      _packageIncludes = widget.extraService!.packageIncludes;
    } else {
      _name = '';
      _code = '';
      _description = '';
      _category = 'Transport';
      _price = 0;
      _pricingUnit = 'per_item';
      _requiresAdvanceBooking = false;
      _advanceHours = null;
      _maxQuantity = null;
      _isPackage = false;
      _packageIncludes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extraService == null
            ? 'Ajouter un Service'
            : 'Modifier le Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _code,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un code.';
                  }
                  return null;
                },
                onSaved: (value) => _code = value!,
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: [
                  'Transport',
                  'Room',
                  'Food',
                  'Spa',
                  'Activity',
                  'Package'
                ]
                    .map((category) => DropdownMenuItem(
                        value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(labelText: 'Prix (DA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix.';
                  }
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _pricingUnit,
                items: ['per_item', 'per_night', 'per_person', 'per_stay']
                    .map((unit) =>
                        DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) => setState(() => _pricingUnit = value!),
                decoration:
                    const InputDecoration(labelText: 'Unité de tarification'),
              ),
              SwitchListTile(
                title: const Text('Réservation à l\'avance requise'),
                value: _requiresAdvanceBooking,
                onChanged: (value) =>
                    setState(() => _requiresAdvanceBooking = value),
              ),
              if (_requiresAdvanceBooking)
                TextFormField(
                  initialValue: _advanceHours?.toString(),
                  decoration: const InputDecoration(
                      labelText: 'Heures d\'avance requises'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _advanceHours = int.tryParse(value ?? ''),
                ),
              TextFormField(
                initialValue: _maxQuantity?.toString(),
                decoration: const InputDecoration(
                    labelText: 'Quantité maximale (optionnel)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _maxQuantity = int.tryParse(value ?? ''),
              ),
              SwitchListTile(
                title: const Text('Est un package'),
                value: _isPackage,
                onChanged: (value) => setState(() => _isPackage = value),
              ),
              if (_isPackage)
                TextFormField(
                  initialValue: _packageIncludes,
                  decoration: const InputDecoration(
                      labelText: 'Inclus dans le package (JSON)'),
                  onSaved: (value) => _packageIncludes = value,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final provider =
                        Provider.of<HotelProvider>(context, listen: false);

                    final extraService = ExtraService(
                      name: _name,
                      code: _code,
                      description: _description,
                      category: _category,
                      price: _price,
                      pricingUnit: _pricingUnit,
                      requiresAdvanceBooking: _requiresAdvanceBooking,
                      isPackage: _isPackage,
                      packageIncludes: _packageIncludes,
                    )
                      ..id = widget.extraService?.id ?? 0
                      ..advanceHours =
                          _advanceHours ?? 0 // Valeur par défaut si null
                      ..maxQuantity =
                          _maxQuantity!; // Peut rester null si la logique métier le permet

                    if (widget.extraService == null) {
                      await provider.addExtraService(extraService);
                    } else {
                      await provider.updateExtraService(extraService);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.extraService == null
                                ? 'Service ajouté avec succès.'
                                : 'Service mis à jour avec succès.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeasonalPricingListScreen extends StatelessWidget {
  const SeasonalPricingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifications Saisonnières'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SeasonalPricingFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final seasonalPricings = provider.seasonalPricing;
          if (seasonalPricings.isEmpty) {
            return const Center(
              child: Text('Aucune tarification saisonnière trouvée.'),
            );
          }
          return ListView.builder(
            itemCount: seasonalPricings.length,
            itemBuilder: (context, index) {
              final seasonalPricing = seasonalPricings[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(seasonalPricing.name),
                  subtitle: Text(
                      '${seasonalPricing.multiplier}x • ${seasonalPricing.startDate.day}/${seasonalPricing.startDate.month}/${seasonalPricing.startDate.year} → ${seasonalPricing.endDate.day}/${seasonalPricing.endDate.month}/${seasonalPricing.endDate.year}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeasonalPricingFormScreen(
                                  seasonalPricing: seasonalPricing),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer'),
                              content: const Text(
                                  'Voulez-vous vraiment supprimer cette tarification ?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await provider
                                .deleteSeasonalPricing(seasonalPricing.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Tarification supprimée avec succès.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SeasonalPricingFormScreen extends StatefulWidget {
  final SeasonalPricing? seasonalPricing;

  const SeasonalPricingFormScreen({super.key, this.seasonalPricing});

  @override
  State<SeasonalPricingFormScreen> createState() =>
      _SeasonalPricingFormScreenState();
}

class _SeasonalPricingFormScreenState extends State<SeasonalPricingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late DateTime _startDate;
  late DateTime _endDate;
  late double _multiplier;
  late String _applicationType;
  late String _description;
  late int _priority;

  @override
  void initState() {
    super.initState();
    if (widget.seasonalPricing != null) {
      _name = widget.seasonalPricing!.name;
      _startDate = widget.seasonalPricing!.startDate;
      _endDate = widget.seasonalPricing!.endDate;
      _multiplier = widget.seasonalPricing!.multiplier;
      _applicationType = widget.seasonalPricing!.applicationType;
      _description = widget.seasonalPricing!.description!;
      _priority = widget.seasonalPricing!.priority;
    } else {
      final now = DateTime.now();
      _name = '';
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month + 1, now.day);
      _multiplier = 1.0;
      _applicationType = 'all_categories';
      _description = '';
      _priority = 1;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.seasonalPricing == null
            ? 'Ajouter une Tarification'
            : 'Modifier la Tarification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context, true),
                      child: Text(
                          'Du: ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _selectDate(context, false),
                      child: Text(
                          'Au: ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                initialValue: _multiplier.toString(),
                decoration: const InputDecoration(
                    labelText: 'Multiplicateur (ex: 1.2)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un multiplicateur.';
                  }
                  return null;
                },
                onSaved: (value) => _multiplier = double.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: _applicationType,
                items: ['all_categories', 'specific_categories']
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _applicationType = value!),
                decoration:
                    const InputDecoration(labelText: 'Type d\'application'),
              ),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value!,
              ),
              TextFormField(
                initialValue: _priority.toString(),
                decoration: const InputDecoration(labelText: 'Priorité'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une priorité.';
                  }
                  return null;
                },
                onSaved: (value) => _priority = int.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final provider =
                        Provider.of<HotelProvider>(context, listen: false);

                    // Créer l'objet SeasonalPricing
                    final seasonalPricing = SeasonalPricing(
                      name: _name,
                      startDate: _startDate,
                      endDate: _endDate,
                      multiplier: _multiplier,
                      applicationType: _applicationType,
                      description: _description,
                      priority: _priority,
                    )..id = widget.seasonalPricing?.id ??
                        0; // Définir id après la création

                    if (widget.seasonalPricing == null) {
                      await provider.addSeasonalPricing(seasonalPricing);
                    } else {
                      await provider.updateSeasonalPricing(seasonalPricing);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.seasonalPricing == null
                                ? 'Tarification ajoutée avec succès.'
                                : 'Tarification mise à jour avec succès.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentHotel});

  final Hotel? currentHotel;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              children: [
                currentHotel == null
                    ? Text('HÔTEL',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 24))
                    : Text(
                        currentHotel!.name.toUpperCase(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 24),
                      ),
                currentHotel == null
                    ? SizedBox.shrink()
                    : Row(
                        children: [
                          // Icône hôtel stylisée
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple.withOpacity(0.1),
                            radius: 24,
                            child: Icon(Icons.hotel_rounded,
                                color: Theme.of(context).secondaryHeaderColor,
                                size: 28),
                          ),

                          const SizedBox(width: 16),

                          // Infos texte
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.meeting_room_rounded,
                                        size: 18,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${currentHotel!.rooms.length} chambres",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.layers_rounded,
                                      size: 18,
                                      color: Theme.of(context)
                                          .secondaryHeaderColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${currentHotel!.floors} étages",
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .secondaryHeaderColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                SeasonalPricingDropdown(),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.checkroom_outlined),
            title: const Text('Chambres'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoomListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bed),
            title: const Text('Catégories de Chambres'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const RoomCategoryListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Plans de Pension'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BoardBasisListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.room_service),
            title: const Text('Services Supplémentaires'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExtraServiceListScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Tarifications Saisonnières'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SeasonalPricingListScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chambres')),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final rooms = provider.rooms;
          if (rooms.isEmpty) {
            return const Center(child: Text('Aucune chambre trouvée.'));
          }
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final categoryName = room.category.target?.name ?? 'Aucune';
              return Card(
                child: ListTile(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomFormScreen(room: room),
                      ),
                    );
                  },
                  leading: FittedBox(
                    child: Column(
                      children: [
                        Text(
                          'Room\n${room.code}',
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  title: Text('Catégorie: $categoryName'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Capacité: ${room.category.target!.capacity}'),
                    ],
                  ),
                  trailing: Text(
                    '${room.category.target!.basePrice.toStringAsFixed(2)} DA',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoomFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RoomFormScreen extends StatefulWidget {
  final Room? room;

  const RoomFormScreen({super.key, this.room});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _code;
  late String? _type;
  late int _capacity;
  late double _basePrice;
  late String _status;

  int? _selectedCategoryId; // ✅ on stocke uniquement l'id
  RoomCategory? _selectedCategory; // utilisé seulement pour affichage

  final statusItems = [
    'Disponible',
    'Occupée',
    'En maintenance',
    'Hors service'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _code = widget.room!.code;
      _type = widget.room!.category.target!.bedType;
      _capacity = widget.room!.category.target!.capacity ?? 1;
      _basePrice = widget.room!.category.target!.basePrice ?? 0.0;
      _status = widget.room!.status;
      _selectedCategory = widget.room!.category.target;
      _selectedCategoryId = _selectedCategory?.id; // ✅ garder l'id
    } else {
      _code = '';
      _type = 'Single';
      _capacity = 1;
      _basePrice = 0.0;
      _status = 'Disponible';
      _selectedCategory = null;
      _selectedCategoryId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null
            ? 'Ajouter une Chambre'
            : 'Modifier la Chambre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Code de la chambre
              TextFormField(
                initialValue: _code,
                decoration:
                    const InputDecoration(labelText: 'Code de la Chambre'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un code.'
                    : null,
                onSaved: (value) => _code = value!,
              ),

              // Type de chambre
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type de Chambre'),
                items: ['Single', 'Double', 'Twin', 'King', 'Suite']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _type = value),
              ),

              // Capacité
              TextFormField(
                initialValue: _capacity.toString(),
                decoration: const InputDecoration(labelText: 'Capacité'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer une capacité.'
                    : null,
                onSaved: (value) => _capacity = int.parse(value!),
              ),

              // Prix de base
              TextFormField(
                initialValue: _basePrice.toString(),
                decoration:
                    const InputDecoration(labelText: 'Prix de base (DA)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty
                    ? 'Veuillez entrer un prix.'
                    : null,
                onSaved: (value) => _basePrice = double.parse(value!),
              ),

              // Statut
              DropdownButtonFormField<String>(
                value: statusItems.contains(_status) ? _status : null,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: statusItems
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
                validator: (value) =>
                    value == null ? 'Veuillez sélectionner un statut.' : null,
              ),

              // Catégorie
              Consumer<HotelProvider>(
                builder: (context, provider, child) {
                  final categories = provider.roomCategories;

                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    // ✅ on utilise l'id
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: categories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                        _selectedCategory = categories.firstWhere(
                          (c) => c.id == value,
                          orElse: () => categories.first,
                        );
                      });
                    },
                    validator: (value) => value == null
                        ? 'Veuillez sélectionner une catégorie.'
                        : null,
                  );
                },
              ),

              // Détails catégorie
              if (_selectedCategory != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Détails de la Catégorie',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nom: ${_selectedCategory!.name}'),
                        Text('Type de lit: ${_selectedCategory!.bedType}'),
                        Text('Standing: ${_selectedCategory!.standing}'),
                        Text(
                            'Prix de base: ${_selectedCategory!.basePrice} DA'),
                        Text('Capacité: ${_selectedCategory!.capacity}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Équipements:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 4,
                          children: _selectedCategory!.amenitiesList
                              .map((amenity) => Chip(
                                    label: Text(amenity),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Enregistrer
              // Dans RoomFormScreen, remplacez la méthode onPressed du bouton Enregistrer :

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final provider =
                        Provider.of<HotelProvider>(context, listen: false);

                    if (_selectedCategory == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Veuillez sélectionner une catégorie')),
                      );
                      return;
                    }

                    Room room;

                    if (widget.room == null) {
                      // ✅ Création d'une nouvelle chambre
                      room = Room(
                        code: _code,
                        status: _status,
                      );

                      room.category.target = _selectedCategory;
                      room.hotel.target =
                          provider.currentHotel ?? provider.hotels.first;
                      await provider.addRoom(room);
                    } else {
                      // ✅ Modification d'une chambre existante
                      room = widget.room!;

                      // Préserver les relations critiques
                      final existingHotel = room.hotel.target;
                      final existingReservations = room.reservations.toList();

                      // Mettre à jour uniquement les champs de Room
                      room.code = _code;
                      room.status = _status;

                      // Réassigner les relations
                      room.category.target = _selectedCategory;
                      room.hotel.target = existingHotel;

                      // Restaurer les réservations
                      room.reservations.clear();
                      room.reservations.addAll(existingReservations);

                      await provider.updateRoom(room);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.room == null
                                ? 'Chambre ajoutée avec succès.'
                                : 'Chambre mise à jour avec succès.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
