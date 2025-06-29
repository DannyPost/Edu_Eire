import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../studentdeals/product_model.dart';
import '../studentdeals/student_deals_page.dart';

const Color kPrimaryBlue = Color(0xFF4595e6);
const Color kLightBlue = Color(0xFFe7f2fb);

class AdminDashboard extends StatefulWidget {
  final String adminEmail;
  const AdminDashboard({Key? key, required this.adminEmail}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _supplyController = TextEditingController();

  final List<String> sectors = [
    'Tech', 'Food & Drink', 'Fitness & Wellness', 'Fashion & Style',
    'Education & Courses', 'Entertainment', 'Travel', 'Beauty & Skincare',
    'Books & Stationery', 'Health Services', 'Music & Events',
    'Gaming & E-sports', 'Home & Living', 'Finance & Banking',
    'Student Essentials', 'Streaming & Subscriptions', 'Careers & Internships',
    'Gyms & Sports Clubs', 'Transport & Bikes'
  ];

  final List<String> locations = [
    'Carlow', 'Cavan', 'Clare', 'Cork', 'Donegal', 'Dublin', 'Galway',
    'Kerry', 'Kildare', 'Kilkenny', 'Laois', 'Leitrim', 'Limerick',
    'Longford', 'Louth', 'Mayo', 'Meath', 'Monaghan', 'Offaly', 'Roscommon',
    'Sligo', 'Tipperary', 'Waterford', 'Westmeath', 'Wexford', 'Wicklow', 'Online'
  ];

  final List<String> modes = ['Online', 'In-store'];
  List<String> selectedSectors = [];
  List<String> selectedLocations = [];
  List<String> selectedModes = [];

  void _deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
  }

  void _showEditDialog(Product p) {
    final titleController = TextEditingController(text: p.title);
    final descController = TextEditingController(text: p.description);
    final priceController = TextEditingController(text: p.price.toString());
    final supplyController = TextEditingController(text: p.supply.toString());
    List<String> editedSectors = p.sector.split(', ');
    List<String> editedLocations = p.location.split(', ');
    List<String> editedModes = p.mode.split(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kLightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [],
              ),
              TextField(
                controller: supplyController,
                decoration: const InputDecoration(labelText: 'Supply'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [],
              ),
              const SizedBox(height: 10),
              _buildDialogFilterChips('Sectors', sectors, editedSectors),
              _buildDialogFilterChips('Locations', locations, editedLocations),
              _buildDialogFilterChips('Modes', modes, editedModes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(p.id).update({
                'title': titleController.text,
                'description': descController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'supply': int.tryParse(supplyController.text) ?? 0,
                'sector': editedSectors.join(', '),
                'location': editedLocations.join(', '),
                'mode': editedModes.join(', '),
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Widget _buildDialogFilterChips(String label, List<String> options, List<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Wrap(
          spacing: 6,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              backgroundColor: kLightBlue,
              selectedColor: kPrimaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              labelStyle: TextStyle(color: isSelected ? Colors.white : kPrimaryBlue),
              onSelected: (_) {
                setState(() {
                  isSelected ? selected.remove(option) : selected.add(option);
                });
              },
            );
          }).toList(),
        )
      ],
    );
  }

  void _addProduct() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty || _priceController.text.isEmpty ||
        _supplyController.text.isEmpty || selectedSectors.isEmpty || selectedLocations.isEmpty || selectedModes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields.')));
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance.collection('products').doc(id).set({
      'id': id,
      'adminId': widget.adminEmail, // adminId is now the email!
      'title': _titleController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'supply': int.tryParse(_supplyController.text) ?? 0,
      'sector': selectedSectors.join(', '),
      'location': selectedLocations.join(', '),
      'mode': selectedModes.join(', '),
    });

    setState(() {
      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _supplyController.clear();
      selectedSectors.clear();
      selectedLocations.clear();
      selectedModes.clear();
    });
  }

  Widget _buildFilterChips(List<String> options, List<String> selected) {
    return Wrap(
      spacing: 6,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          backgroundColor: kLightBlue,
          selectedColor: kPrimaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          labelStyle: TextStyle(color: isSelected ? Colors.white : kPrimaryBlue),
          onSelected: (_) {
            setState(() {
              isSelected ? selected.remove(option) : selected.add(option);
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBlue,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 2,
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(28), bottomRight: Radius.circular(28))),
        backgroundColor: kLightBlue,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryBlue, kLightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(36)),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text('Admin Menu',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: kPrimaryBlue),
              title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w500)),
              selected: ModalRoute.of(context)?.settings.name == '/admin',
              selectedTileColor: Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/admin') {
                  Navigator.pushReplacementNamed(context, '/admin');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.local_offer, color: kPrimaryBlue),
              title: const Text('Student Deals', style: TextStyle(fontWeight: FontWeight.w500)),
              selected: ModalRoute.of(context)?.settings.name == '/student-deals',
              selectedTileColor: Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/student-deals') {
                  Navigator.pushReplacementNamed(context, '/student-deals');
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Card(
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: _supplyController,
                      decoration: const InputDecoration(labelText: 'Supply'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 10),
                    _buildFilterChips(sectors, selectedSectors),
                    _buildFilterChips(locations, selectedLocations),
                    _buildFilterChips(modes, selectedModes),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').where('adminId', isEqualTo: widget.adminEmail).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final products = snapshot.data!.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: ListTile(
                          title: Text(p.title, style: TextStyle(fontWeight: FontWeight.w600, color: kPrimaryBlue)),
                          subtitle: Text('${p.sector} • ${p.location} • ${p.mode}',
                              style: TextStyle(color: Colors.grey[700])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('€${p.price.toStringAsFixed(2)}',
                                  style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.edit), color: kPrimaryBlue, onPressed: () => _showEditDialog(p)),
                              IconButton(icon: const Icon(Icons.delete), color: Colors.red, onPressed: () => _deleteProduct(p.id)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
