import 'package:flutter/material.dart';

void main() => runApp(const HearEligibilityApp());

class HearEligibilityApp extends StatelessWidget {
  const HearEligibilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEAR Eligibility Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF3ab6ff),
        scaffoldBackgroundColor: const Color(0xFFf5faff),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3ab6ff),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3ab6ff),
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const HearFormPage(),
    );
  }
}

class HearFormPage extends StatefulWidget {
  const HearFormPage({super.key});

  @override
  State<HearFormPage> createState() => _HearFormPageState();
}

class _HearFormPageState extends State<HearFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _incomeController = TextEditingController();
  int dependentChildren = 0;
  String? medicalCardAnswer;
  String? welfareAnswer;
  String? socioEconomicAnswer;
  String? deisAnswer;
  String? areaAnswer;
  String result = '';

  double getIncomeLimit() {
    if (dependentChildren < 4) return 46790;
    if (dependentChildren <= 7) return 51325;
    return 55630;
  }

  void checkEligibility() {
    double? income = double.tryParse(_incomeController.text);
    if (income == null) {
      setState(() {
        result = '⚠️ Please enter a valid household income.';
      });
      return;
    }

    double incomeLimit = getIncomeLimit();
    bool incomeEligible = income <= incomeLimit;

    if (!incomeEligible) {
      setState(() {
        result = '❌ Not eligible: Your income exceeds the HEAR income limit (€${incomeLimit.toStringAsFixed(0)}).';
      });
      return;
    }

    int indicators = 0;
    if (medicalCardAnswer == 'Yes') indicators++;
    if (welfareAnswer == 'Yes') indicators++;
    if (socioEconomicAnswer == 'Yes') indicators++;
    if (deisAnswer == 'Yes') indicators++;
    if (areaAnswer == 'Yes') indicators++;

    if (indicators >= 2) {
      setState(() {
        result = '✅ You are likely eligible for the HEAR Scheme.';
      });
    } else {
      setState(() {
        result = '❌ Not eligible: You must meet two other criteria in addition to the income limit.';
      });
    }
  }

  Widget labeledDropdown(String label, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(),
          items: ['Yes', 'No']
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HEAR Eligibility Calculator')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Answer the following questions to see if you may be eligible:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('What was your total household income in 2023? (€)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _incomeController,
                decoration: const InputDecoration(),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              const Text('How many dependent children are in your family?'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: dependentChildren,
                decoration: const InputDecoration(),
                items: List.generate(10, (index) => index)
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(),
                onChanged: (val) => setState(() => dependentChildren = val ?? 0),
              ),
              labeledDropdown('Do you or your parent/guardian have a valid medical card or GP visit card?', medicalCardAnswer, (val) => setState(() => medicalCardAnswer = val)),
              labeledDropdown('Do you or your family receive a means-tested social welfare payment?', welfareAnswer, (val) => setState(() => welfareAnswer = val)),
              labeledDropdown('Is your parent’s/guardian’s employment considered part of a low socio-economic group?', socioEconomicAnswer, (val) => setState(() => socioEconomicAnswer = val)),
              labeledDropdown('Have you completed 5 years in a DEIS secondary school?', deisAnswer, (val) => setState(() => deisAnswer = val)),
              labeledDropdown('Do you live in a disadvantaged area according to the Pobal index?', areaAnswer, (val) => setState(() => areaAnswer = val)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: checkEligibility,
                child: const Text('Check Eligibility'),
              ),
              const SizedBox(height: 20),
              if (result.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Text(
                        result,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("📝 Summary of Your Answers:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("• Income: €${_incomeController.text}"),
                          Text("• Dependent Children: $dependentChildren"),
                          Text("• Medical Card: ${medicalCardAnswer ?? 'Not Answered'}"),
                          Text("• Social Welfare: ${welfareAnswer ?? 'Not Answered'}"),
                          Text("• Socio-Economic Group: ${socioEconomicAnswer ?? 'Not Answered'}"),
                          Text("• DEIS School: ${deisAnswer ?? 'Not Answered'}"),
                          Text("• Disadvantaged Area: ${areaAnswer ?? 'Not Answered'}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _incomeController.clear();
                          dependentChildren = 0;
                          medicalCardAnswer = null;
                          welfareAnswer = null;
                          socioEconomicAnswer = null;
                          deisAnswer = null;
                          areaAnswer = null;
                          result = '';
                        });
                      },
                      child: const Text('Reset Form'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
