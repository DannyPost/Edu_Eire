// main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const DareEligibilityApp());
}

class DareEligibilityApp extends StatelessWidget {
  const DareEligibilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DARE Eligibility Checker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF49baf2),
        scaffoldBackgroundColor: const Color(0xFFe6f4f9),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF49baf2),
          foregroundColor: Colors.white,
        ),
      ),
      home: const DareFormPage(),
    );
  }
}

class DareFormPage extends StatefulWidget {
  const DareFormPage({super.key});

  @override
  State<DareFormPage> createState() => _DareFormPageState();
}

class _DareFormPageState extends State<DareFormPage> {
  final _formKey = GlobalKey<FormState>();

  List<String> selectedDisabilities = [];
  String? educationalImpact;
  String? documentation;
  String? schoolStatement;
  String? timeFrame;

  List<String> disabilityOptions = [
    'ADD/ADHD',
    'Autistic Spectrum Disorder',
    'Blind/Vision Impaired',
    'Deaf/Hard of Hearing',
    'DCD/Dyspraxia',
    'Dyscalculia',
    'Dyslexia',
    'Mental Health Condition',
    'Neurological Condition',
    'Physical Disability',
    'Significant Ongoing Illness',
    'Speech & Language Disorder',
  ];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      bool eligible = selectedDisabilities.isNotEmpty &&
          educationalImpact == 'Yes' &&
          documentation == 'Yes' &&
          schoolStatement == 'Yes' &&
          timeFrame == 'Yes';

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(eligible ? 'Likely Eligible' : 'Not Eligible'),
          content: Text(eligible
              ? 'You are likely eligible for DARE. Submit all required documentation before 15 March 2025.'
              : 'You do not meet all the eligibility criteria for DARE. Please review the requirements.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  Widget _buildYesNoQuestion(String label, String? value, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: ['Yes', 'No'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? 'Please answer this question' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DARE Eligibility Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step 1: Select your disability/disabilities:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: disabilityOptions.map((dis) => FilterChip(
                    label: Text(dis),
                    selected: selectedDisabilities.contains(dis),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedDisabilities.add(dis);
                        } else {
                          selectedDisabilities.remove(dis);
                        }
                      });
                    },
                  )).toList(),
                ),
                if (selectedDisabilities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Please select at least one disability.', style: TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 16),

                _buildYesNoQuestion('Step 2: Has your disability negatively impacted your education?', educationalImpact, (val) => setState(() => educationalImpact = val)),
                _buildYesNoQuestion('Step 3: Do you have professional documentation for your disability?', documentation, (val) => setState(() => documentation = val)),
                _buildYesNoQuestion('Step 4: Will your school complete the Educational Impact Statement form?', schoolStatement, (val) => setState(() => schoolStatement = val)),
                _buildYesNoQuestion('Step 5: Was your diagnosis or report made within the required timeframe?', timeFrame, (val) => setState(() => timeFrame = val)),

                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Check Eligibility'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
