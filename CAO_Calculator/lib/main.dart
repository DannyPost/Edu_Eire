import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(SusiGrantApp());
}

class SusiGrantApp extends StatelessWidget {
  const SusiGrantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUSI Grant Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 0, 0)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Color(0xFFF5F9FA),
      ),
      home: GrantCalculatorPage(),
    );
  }
}

class GrantCalculatorPage extends StatefulWidget {
  const GrantCalculatorPage({super.key});

  @override
  _GrantCalculatorPageState createState() => _GrantCalculatorPageState();
}

class _GrantCalculatorPageState extends State<GrantCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final incomeController = TextEditingController();
  final dependentsController = TextEditingController();

  bool livesFar = false;
  String result = '';
  Color resultColor = Colors.transparent;
  bool? isEligible; // New flag to track result status

  void calculateGrant() {
    final income = double.tryParse(incomeController.text) ?? 0;
    final dependents = int.tryParse(dependentsController.text) ?? 0;

    double threshold = 46060;
    threshold += (dependents - 1) * 4960;

    if (income <= threshold) {
      double grant = livesFar ? 6795 : 2750;
      String rateType = livesFar ? "non-adjacent" : "adjacent";

      setState(() {
        result =
            "Eligible for SUSI\nEstimated grant: €${grant.toStringAsFixed(2)} ($rateType rate)";
        resultColor = Colors.green.shade100;
        isEligible = true;
      });
    } else {
      setState(() {
        result =
            "Not eligible\nYour income (€${income.toStringAsFixed(2)}) exceeds the limit (€${threshold.toStringAsFixed(2)}).";
        resultColor = Colors.red.shade100;
        isEligible = false;
      });
    }
  }

  @override
  void dispose() {
    incomeController.dispose();
    dependentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SUSI Grant Estimator'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                icon: Icons.euro,
                title: 'Household Income (€)',
                controller: incomeController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildCard(
                icon: Icons.family_restroom,
                title: 'Dependent Children',
                controller: dependentsController,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: SwitchListTile(
                  title: Text("Live more than 45km from college?"),
                  value: livesFar,
                  onChanged: (val) {
                    setState(() {
                      livesFar = val;
                    });
                  },
                  secondary: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    calculateGrant();
                  }
                },
                icon: Icon(Icons.calculate),
                label: Text("Check Eligibility"),
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.0, vertical: 14.0),
                  textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 30),
              if (result.isNotEmpty)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: resultColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isEligible == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: isEligible == true
                            ? Colors.green
                            : Colors.redAccent,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) =>
              value == null || value.isEmpty ? 'This field is required' : null,
          decoration: InputDecoration(
            icon: Icon(icon),
            labelText: title,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
