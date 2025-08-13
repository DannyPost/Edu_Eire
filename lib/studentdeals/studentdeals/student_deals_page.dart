import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import 'product_model.dart';

// ── colours ─────────────────────────────────────────────────────────
const Color kPrimaryBlue = Color(0xFF1976D2);
const Color kLightBlue   = Color(0xFFE3F0FC);

class StudentDealsPage extends StatefulWidget {
  final String? adminId;                    // stays for deep-link support
  const StudentDealsPage({super.key, this.adminId});

  @override
  State<StudentDealsPage> createState() => _StudentDealsPageState();
}

class _StudentDealsPageState extends State<StudentDealsPage> {
  // ── filters – selections ──────────────────────────────────────────
  final Set<String> _selSector   = {};
  final Set<String> _selLocation = {};
  final Set<String> _selMode     = {};

  final Map<Product, int> _cart = {};

  // master lists (first entry = “All …”)
  final List<String> _sectors   = const [
    'All Sectors','Tech','Food & Drink','Fitness & Wellness','Fashion & Style',
    'Education & Courses','Entertainment','Travel','Beauty & Skincare','Books & Stationery',
    'Health Services','Music & Events','Gaming & E-sports','Home & Living','Finance & Banking',
    'Student Essentials','Streaming & Subscriptions','Careers & Internships',
    'Gyms & Sports Clubs','Transport & Bikes'
  ];
  final List<String> _locations = const [
    'All Locations','Carlow','Cavan','Clare','Cork','Donegal','Dublin','Galway','Kerry',
    'Kildare','Kilkenny','Laois','Leitrim','Limerick','Longford','Louth','Mayo','Meath',
    'Monaghan','Offaly','Roscommon','Sligo','Tipperary','Waterford','Westmeath',
    'Wexford','Wicklow','Online'
  ];
  final List<String> _modes     = const ['All Modes','Online','In-store'];

  // ── helpers ───────────────────────────────────────────────────────
  void _toggle(Set<String> bucket, String value, String allValue) {
    setState(() {
      if (value == allValue) {
        bucket
          ..clear()
          ..add(value);
      } else {
        bucket.remove(allValue);
        if (!bucket.add(value)) {
          bucket.remove(value);
        }
      }
    });
  }

  void _addToCart(Product p) {
    setState(() {
      if (!_cart.containsKey(p)) {
        _cart[p] = 1;
      } else if (_cart[p]! < p.supply) {
        _cart[p] = _cart[p]! + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot add more than available supply.')),
        );
      }
    });
  }

  // ───────────────────────── checkout via Cloud Functions ──────────
  Future<void> _checkout() async {                                   // 👈 NEW
    if (_cart.isEmpty) return;

    final items = _cart.entries
        .map((e) => {'id': e.key.id, 'qty': e.value})
        .toList();

    try {
      // If your Cloud Function lives in a non-default region, set it here
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable  = functions.httpsCallable('createStripeCheckoutSession');

      final res  = await callable.call(<String, dynamic>{'items': items});

      final data = res.data as Map<String, dynamic>?;
      if (data == null || data['url'] == null) {
        throw const FormatException('Cloud Function returned no url');
      }

      final url = Uri.parse(data['url'] as String);

      // launchUrl is null-safe and returns a bool – no extra canLaunch needed
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw 'Could not open checkout link';

      setState(_cart.clear);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout opened – complete payment to secure items.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      _showError('🛑 ${e.code}: ${e.message}');
    } on FormatException catch (e) {
      _showError('Bad response: ${e.message}');
    } catch (e) {
      _showError('Unexpected error: $e');
    }
  }

  void _showError(String msg) {                                      // 👈 NEW
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // ── UI ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: kPrimaryBlue,
          title: const Text('Student Deals', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          elevation: 2,
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 28),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => _cartSheet(),
                  ),
                ),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 6, top: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 4)
                        ],
                      ),
                      child: Center(
                        child: Text('${_cart.length}',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // ❌ no drawer – master navigation handled in HomePage
        body: Column(
          children: [
            _filtersRow(),
            Expanded(child: _productsList()),
          ],
        ),
      );

  // ── filters row ───────────────────────────────────────────────────
  Widget _filtersRow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chipSet('Sector', _sectors, _selSector, 'All Sectors'),
            const SizedBox(width: 12),
            _chipSet('Location', _locations, _selLocation, 'All Locations'),
            const SizedBox(width: 12),
            _chipSet('Mode', _modes, _selMode, 'All Modes'),
          ]),
        ),
      );

  // ── product list ─────────────────────────────────────────────────-
  Widget _productsList() => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {                                       // 👈 NEW
            return _empty('⚠️ ${snap.error}');
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _empty('No student deals available.');
          }

          final all = snap.data!.docs
              .map((d) => Product.fromMap(d.data() as Map<String, dynamic>))
              .toList();

          final filtered = all.where((p) {
            final sec = _selSector.isEmpty   || _selSector.any((s) => p.sector.contains(s));
            final loc = _selLocation.isEmpty || _selLocation.any((l) => p.location.contains(l));
            final mod = _selMode.isEmpty     || _selMode.any((m) => p.mode.contains(m));
            return sec && loc && mod;
          }).toList();

          if (filtered.isEmpty) {
            return _empty('No results match your filters.');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _productCard(filtered[i]),
          );
        },
      );

  // ── widgets: filter chips, product card, cart sheet ───────────────
  Widget _chipSet(String label, List<String> opts, Set<String> sel, String allVal) =>
      Row(children: [
        Text('$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue)),
        const SizedBox(width: 6),
        Wrap(
          spacing: 4,
          children: [
            ...opts.take(4).map((opt) => _chip(opt, sel, allVal)),
            if (opts.length > 4)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 20, color: kPrimaryBlue),
                onSelected: (v) => _toggle(sel, v, allVal),
                itemBuilder: (_) =>
                    opts.skip(4).map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
              ),
          ],
        ),
      ]);

  Widget _chip(String lbl, Set<String> sel, String allVal) {
    final on = sel.contains(lbl);
    return FilterChip(
      label: Text(lbl,
          style: TextStyle(
              color: on ? Colors.white : kPrimaryBlue,
              fontWeight: on ? FontWeight.w600 : FontWeight.normal)),
      backgroundColor: on ? kPrimaryBlue : kLightBlue,
      selectedColor: kPrimaryBlue,
      selected: on,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (_) => _toggle(sel, lbl, allVal),
    );
  }

  Widget _productCard(Product p) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 18),
        color: kLightBlue,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
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
                  Text(p.title,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
                  const SizedBox(height: 2),
                  Text(p.description,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: -8,
                    children: [
                      Chip(
                        label: Text('€${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white)),
                        backgroundColor: kPrimaryBlue,
                        padding: EdgeInsets.zero,
                      ),
                      if (p.supply > 0)
                        Chip(
                          label: Text('${p.supply} left',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.zero,
                        )
                      else
                        Chip(
                          label: const Text('Sold Out',
                              style: TextStyle(color: Colors.white)),
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
                tooltip: p.supply > 0 ? 'Add to cart' : 'Out of stock',
                onPressed: p.supply > 0 ? () => _addToCart(p) : null,
              ),
            ),
          ]),
        ),
      );

  Widget _cartSheet() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              height: 5,
              width: 42,
              decoration: BoxDecoration(
                  color: kPrimaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 10),
          Text('Cart',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 21, color: kPrimaryBlue)),
          const SizedBox(height: 8),
          if (_cart.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Your cart is empty.',
                  style: TextStyle(color: kPrimaryBlue.withOpacity(0.7))),
            )
          else ...[
            ..._cart.entries.map((e) => Row(children: [
                  Expanded(child: Text(e.key.title)),
                  Text('x${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
                    onPressed: () {
                      setState(() {
                        if (_cart[e.key]! > 1) {
                          _cart[e.key] = _cart[e.key]! - 1;
                        } else {
                          _cart.remove(e.key);
                        }
                      });
                    },
                  ),
                ])),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _checkout();
                },
              ),
            ),
          ],
        ]),
      );

  Widget _empty(String txt) => Center(
        child: Text(txt,
            style:
                TextStyle(fontSize: 17, color: kPrimaryBlue.withOpacity(0.6))),
      );
}
