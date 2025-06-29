import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_model.dart';

const Color kPrimaryBlue = Color(0xFF1976D2);
const Color kLightBlue = Color(0xFFe3f0fc);

class StudentDealsPage extends StatefulWidget {
  final String? adminId;
  const StudentDealsPage({super.key, this.adminId});

  @override
  State<StudentDealsPage> createState() => _StudentDealsPageState();
}

class _StudentDealsPageState extends State<StudentDealsPage> {
  Set<String> selectedSectors = {};
  Set<String> selectedLocations = {};
  Set<String> selectedModes = {};
  final Map<Product, int> cart = {};

  final List<String> sectors = [
    'All Sectors', 'Tech', 'Food & Drink', 'Fitness & Wellness', 'Fashion & Style',
    'Education & Courses', 'Entertainment', 'Travel', 'Beauty & Skincare',
    'Books & Stationery', 'Health Services', 'Music & Events',
    'Gaming & E-sports', 'Home & Living', 'Finance & Banking',
    'Student Essentials', 'Streaming & Subscriptions', 'Careers & Internships',
    'Gyms & Sports Clubs', 'Transport & Bikes'
  ];

  final List<String> locations = [
    'All Locations', 'Carlow', 'Cavan', 'Clare', 'Cork', 'Donegal', 'Dublin', 'Galway',
    'Kerry', 'Kildare', 'Kilkenny', 'Laois', 'Leitrim', 'Limerick',
    'Longford', 'Louth', 'Mayo', 'Meath', 'Monaghan', 'Offaly', 'Roscommon',
    'Sligo', 'Tipperary', 'Waterford', 'Westmeath', 'Wexford', 'Wicklow', 'Online'
  ];

  final List<String> modes = ['All Modes', 'Online', 'In-store'];

  void toggleFilter(Set<String> filterSet, String value, String allValue) {
    setState(() {
      if (value == allValue) {
        filterSet.clear();
        filterSet.add(value);
      } else {
        filterSet.remove(allValue);
        if (!filterSet.add(value)) {
          filterSet.remove(value);
        }
      }
    });
  }

  void addToCart(Product product) {
    setState(() {
      if (!cart.containsKey(product)) {
        cart[product] = 1;
      } else if (cart[product]! < product.supply) {
        cart[product] = cart[product]! + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add more than available supply.')),
        );
      }
    });
  }

  Future<void> checkoutCart(BuildContext context) async {
    if (cart.isEmpty) return;
    final items = cart.entries.map((e) => {'id': e.key.id, 'qty': e.value}).toList();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createStripeCheckoutSession');
      final result = await callable.call({'items': items});
      final url = result.data['url'] as String;
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        setState(() => cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout launched. Complete payment to secure your items!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch payment.'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        elevation: 2,
        title: const Text('Student Deals', style: TextStyle(color: Colors.white)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => _buildCartSheet(context),
                ),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 6, top: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 4)],
                    ),
                    child: Center(
                      child: Text('${cart.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                child: Text('Student Deals Menu',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: Icon(Icons.local_offer, color: kPrimaryBlue),
              title: const Text('Student Deals', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/student-deals') {
                  Navigator.pushReplacementNamed(context, '/student-deals');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: kPrimaryBlue),
              title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != '/admin') {
                  Navigator.pushReplacementNamed(context, '/admin');
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter section with modern chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChipSet('Sector', sectors, selectedSectors, 'All Sectors'),
                      const SizedBox(width: 12),
                      _buildFilterChipSet('Location', locations, selectedLocations, 'All Locations'),
                      const SizedBox(width: 12),
                      _buildFilterChipSet('Mode', modes, selectedModes, 'All Modes'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text('No student deals available.',
                          style: TextStyle(fontSize: 18, color: kPrimaryBlue.withOpacity(0.7))),
                      );
                    }
                    final products = snapshot.data!.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
                    final filtered = products.where((p) {
                      return (selectedSectors.isEmpty || selectedSectors.any((s) => p.sector.contains(s))) &&
                             (selectedLocations.isEmpty || selectedLocations.any((l) => p.location.contains(l))) &&
                             (selectedModes.isEmpty || selectedModes.any((m) => p.mode.contains(m)));
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text('No results match your filters.',
                          style: TextStyle(fontSize: 17, color: kPrimaryBlue.withOpacity(0.5))),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        return _buildProductCard(p);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Modern UI widgets ----

  Widget _buildFilterChipSet(String label, List<String> options, Set<String> selected, String allValue) {
    return Row(
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
        const SizedBox(width: 6),
        Wrap(
          spacing: 4,
          children: options.take(4).map((option) => _buildFilterChip(option, selected, allValue)).toList() +
            [if (options.length > 4) ...[
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 20, color: kPrimaryBlue),
                onSelected: (option) => toggleFilter(selected, option, allValue),
                itemBuilder: (context) => options.skip(4).map((option) => PopupMenuItem(value: option, child: Text(option))).toList(),
              )
            ]]
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, Set<String> selected, String allValue) {
    final bool isSelected = selected.contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          color: isSelected ? Colors.white : kPrimaryBlue,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        )),
        backgroundColor: isSelected ? kPrimaryBlue : kLightBlue,
        selectedColor: kPrimaryBlue,
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onSelected: (_) => toggleFilter(selected, label, allValue),
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 18),
      color: kLightBlue,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: kPrimaryBlue.withOpacity(0.08),
              backgroundImage: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                ? NetworkImage(p.imageUrl!)
                : null,
              child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                  ? Icon(Icons.card_giftcard, color: kPrimaryBlue, size: 34)
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                  const SizedBox(height: 2),
                  Text(p.description, style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: -8,
                    children: [
                      Chip(
                        label: Text('€${p.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                        backgroundColor: kPrimaryBlue,
                        padding: EdgeInsets.zero,
                      ),
                      if (p.supply > 0)
                        Chip(
                          label: Text('${p.supply} left', style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.zero,
                        )
                      else
                        Chip(
                          label: const Text('Sold Out', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedScale(
              scale: p.supply > 0 ? 1 : 0.9,
              duration: const Duration(milliseconds: 300),
              child: IconButton(
                icon: Icon(Icons.add_shopping_cart,
                  color: p.supply > 0 ? kPrimaryBlue : Colors.grey[400], size: 30),
                tooltip: p.supply > 0 ? "Add to Cart" : "Out of Stock",
                onPressed: p.supply > 0 ? () => addToCart(p) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 5, width: 42, decoration: BoxDecoration(color: kPrimaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 10),
          Text('Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21, color: kPrimaryBlue)),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Your cart is empty.", style: TextStyle(color: kPrimaryBlue.withOpacity(0.7))),
            )
          else ...[
            ...cart.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(child: Text(e.key.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text('x${e.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                    onPressed: () {
                      setState(() {
                        if (cart[e.key]! > 1) {
                          cart[e.key] = cart[e.key]! - 1;
                        } else {
                          cart.remove(e.key);
                        }
                      });
                    },
                  )
                ],
              ),
            )),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                ),
                onPressed: () {
                  Navigator.pop(context);
                  checkoutCart(context);
                },
                label: const Text('Checkout'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
