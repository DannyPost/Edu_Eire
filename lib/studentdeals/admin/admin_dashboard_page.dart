// lib/studentdeals/admin/admin_dashboard_page.dart
// -------------------------------------------------
// Business dashboard

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../studentdeals/product_model.dart';

const kPrimaryBlue = Color(0xFF4595e6);
const kLightBlue   = Color(0xFFe7f2fb);

class AdminDashboardPage extends StatefulWidget {
  final String adminEmail;
  const AdminDashboardPage({super.key, required this.adminEmail});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final List<String> _sectors = const [
    'Tech','Food & Drink','Fitness & Wellness','Fashion & Style','Education & Courses',
    'Entertainment','Travel','Beauty & Skincare','Books & Stationery','Health Services',
    'Music & Events','Gaming & E-sports','Home & Living','Finance & Banking',
    'Student Essentials','Streaming & Subscriptions','Careers & Internships',
    'Gyms & Sports Clubs','Transport & Bikes'
  ];
  final List<String> _locations = const [
    'Carlow','Cavan','Clare','Cork','Donegal','Dublin','Galway','Kerry','Kildare','Kilkenny',
    'Laois','Leitrim','Limerick','Longford','Louth','Mayo','Meath','Monaghan','Offaly',
    'Roscommon','Sligo','Tipperary','Waterford','Westmeath','Wexford','Wicklow','Online'
  ];
  final List<String> _modes = const ['Online','In-store'];

  late final String _emailKey;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream;

  @override
  void initState() {
    super.initState();
    _emailKey = widget.adminEmail.toLowerCase();
    _productsStream = FirebaseFirestore.instance
        .collection('products')
        .where('adminIdLower', isEqualTo: _emailKey)
        .snapshots();
  }

  // ───────── add / edit sheet ──────────────────────────────────────────────
  Future<void> _openSheet({Product? edit}) async {
    final isEdit   = edit != null;
    final titleCtl = TextEditingController(text: edit?.title ?? '');
    final descCtl  = TextEditingController(text: edit?.description ?? '');
    final priceCtl = TextEditingController(text: edit?.price.toString() ?? '');
    final qtyCtl   = TextEditingController(text: edit?.supply.toString() ?? '');

    final selSec = <String>{...?(edit?.sector.split(', '))};
    final selLoc = <String>{...?(edit?.location.split(', '))};
    final selMod = <String>{...?(edit?.mode.split(', '))};

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kLightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, refresh) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isEdit ? 'Edit product' : 'Add product',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                _text(titleCtl, 'Title'),
                _text(descCtl,  'Description', maxLines: 3),
                Row(children: [
                  Expanded(child: _text(priceCtl, 'Price (€)', number: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _text(qtyCtl, 'Quantity', number: true)),
                ]),
                const SizedBox(height: 12),
                _chips('Sector',   _sectors,   selSec, refresh),
                _chips('Location', _locations, selLoc, refresh),
                _chips('Mode',     _modes,     selMod, refresh),
                const SizedBox(height: 18),

                saving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (titleCtl.text.isEmpty || descCtl.text.isEmpty ||
                              priceCtl.text.isEmpty || qtyCtl.text.isEmpty ||
                              selSec.isEmpty || selLoc.isEmpty || selMod.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all fields')),
                            );
                            return;
                          }
                          refresh(() => saving = true);

                          final data = {
                            'title'       : titleCtl.text.trim(),
                            'description' : descCtl.text.trim(),
                            'price'       : double.tryParse(priceCtl.text) ?? 0,
                            'supply'      : int.tryParse(qtyCtl.text) ?? 0,
                            'sector'      : selSec.join(', '),
                            'location'    : selLoc.join(', '),
                            'mode'        : selMod.join(', '),
                            'adminId'     : widget.adminEmail,
                            'adminIdLower': _emailKey,
                            if (!isEdit) 'created': FieldValue.serverTimestamp(),
                          };

                          final col = FirebaseFirestore.instance.collection('products');
                          try {
                            if (isEdit) {
                              await col.doc(edit!.id).set(data, SetOptions(merge: true));
                            } else {
                              final doc = await col.add(data);
                              await doc.update({'id': doc.id});   // NEW ➊ write ID back
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            refresh(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Save failed: $e')),
                            );
                          }
                        },
                        child: Text(isEdit ? 'Save changes' : 'Add product',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id) =>
      FirebaseFirestore.instance.collection('products').doc(id).delete();

  // ───────── main UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Business Dashboard'),
          backgroundColor: kPrimaryBlue,
          centerTitle: true,
        ),
        backgroundColor: kLightBlue,
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimaryBlue,
          onPressed: () => _openSheet(),
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _productsStream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return const Center(child: Text('No products yet'));

            final products = docs.map((d) => Product.fromMap(d.data())).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    title: Text(p.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: kPrimaryBlue)),
                    subtitle: Text('${p.sector} • ${p.location} • ${p.mode}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('€${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _openSheet(edit: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _delete(p.id),
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

  // ───────── helpers ───────────────────────────────────────────────────────
  Widget _text(TextEditingController ctl, String lbl,
      {bool number = false, int maxLines = 1}) =>
      TextField(
        controller: ctl,
        keyboardType:
            number ? const TextInputType.numberWithOptions(decimal: true) : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: lbl,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
          ),
        ),
      );

  Widget _chips(String label, List<String> opts, Set<String> sel,
          StateSetter refresh) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: opts.map((o) {
              final on = sel.contains(o);
              return FilterChip(
                label: Text(o),
                selected: on,
                backgroundColor: Colors.white,
                selectedColor: kPrimaryBlue,
                labelStyle: TextStyle(color: on ? Colors.white : kPrimaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (_) => refresh(() => on ? sel.remove(o) : sel.add(o)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      );
}
