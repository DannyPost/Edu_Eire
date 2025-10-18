import 'package:flutter/material.dart';

class DareCalculatorPage extends StatefulWidget {
  const DareCalculatorPage({super.key});

  @override
  State<DareCalculatorPage> createState() => _DareCalculatorPageState();
}

class _DareCalculatorPageState extends State<DareCalculatorPage> {
  final _formKey = GlobalKey<FormState>();

  List<String> selectedDisabilities = [];
  String? educationalImpact;
  String? documentation;
  String? schoolStatement;
  String? timeFrame;
  String result = '';

  final List<String> disabilityOptions = [
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

      setState(() {
        result = eligible
            ? '✅ You are likely eligible for DARE. Submit all required documentation before 15 March 2025.'
            : '❌ Not eligible: Please review the requirements carefully.';
      });
    }
  }

  Widget _buildYesNoQuestion(String label, String? value, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Step 1: Select your disability/disabilities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: disabilityOptions.map((dis) {
                  return FilterChip(
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
                  );
                }).toList(),
              ),
              if (selectedDisabilities.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('⚠️ Please select at least one disability.', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),

              _buildYesNoQuestion(
                'Step 2: Has your disability negatively impacted your education?',
                educationalImpact,
                (val) => setState(() => educationalImpact = val),
              ),
              _buildYesNoQuestion(
                'Step 3: Do you have professional documentation for your disability?',
                documentation,
                (val) => setState(() => documentation = val),
              ),
              _buildYesNoQuestion(
                'Step 4: Will your school complete the Educational Impact Statement form?',
                schoolStatement,
                (val) => setState(() => schoolStatement = val),
              ),
              _buildYesNoQuestion(
                'Step 5: Was your diagnosis or report made within the required timeframe?',
                timeFrame,
                (val) => setState(() => timeFrame = val),
              ),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Check Eligibility'),
              ),
              const SizedBox(height: 20),
              if (result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
