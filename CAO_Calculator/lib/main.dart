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
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 0, 0)),
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
  final otherStudentsController = TextEditingController();
  final yearBornController = TextEditingController();

  bool livesFar = false;
  String result = '';
  Color resultColor = Colors.transparent;
  bool? isEligible;

  String nationality = 'Irish';
  String residencyStatus = 'Yes';
  String highestQualification = '';
  String courseYear = '';
  String applicantClass = 'Dependent';
  double courseLevel = 1;
  String selectedInstitution = '';
  String selectedCourse = '';

  final approvedInstitutions = [
    'Trinity College Dublin',
    'UCD',
    'CIT',
    'TU Dublin'
  ];
  final approvedCourses = [
    'Computer Science',
    'Engineering',
    'Nursing',
    'Teaching'
  ];

  void calculateGrant() {
    final income = double.tryParse(incomeController.text) ?? 0;
    final dependents = int.tryParse(dependentsController.text) ?? 0;

    // Residency and Nationality Validation
    if (residencyStatus != 'Yes' || (nationality == 'Other')) {
      setState(() {
        result = 'Not eligible due to residency or nationality restrictions.';
        resultColor = Colors.red.shade100;
        isEligible = false;
      });
      return;
    }

    // Progression Check
    int previousLevel =
        int.tryParse(highestQualification.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
    if (courseLevel <= previousLevel) {
      setState(() {
        result =
            'Not eligible: Course level must be higher than your previous qualification.';
        resultColor = Colors.red.shade100;
        isEligible = false;
      });
      return;
    }

    double threshold = 46060;
    threshold += (dependents - 1) * 4960;

    if (income <= threshold) {
      double grant = livesFar ? 6795 : 2750;
      String rateType = livesFar ? "non-adjacent" : "adjacent";

      setState(() {
        result =
            "May be eligible for SUSI\nEstimated grant: €${grant.toStringAsFixed(2)} (${rateType} rate)";

        resultColor = Colors.green.shade100;
        isEligible = true;
      });
    } else {
      setState(() {
        result =
            "May not eligible\nYour income (€${income.toStringAsFixed(2)}) exceeds the limit (€${threshold.toStringAsFixed(2)}).";
        resultColor = Colors.red.shade100;
        isEligible = false;
      });
    }
  }

  @override
  void dispose() {
    incomeController.dispose();
    dependentsController.dispose();
    otherStudentsController.dispose();
    yearBornController.dispose();
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
              _buildDropdown<String>(
                title:
                    'Have you been resident in Ireland or an EU/EEA member state or the UK or Switzerland for 3 of the last 5 years?',
                value: residencyStatus,
                items: ['Yes', 'No'],
                onChanged: (val) => setState(() => residencyStatus = val!),
              ),
              _buildDropdown<String>(
                title:
                    'Are you an Irish citizen or an EU, EEA, UK or Swiss National?',
                value: nationality,
                items: ['Irish', 'EU/EEA', 'UK', 'Swiss', 'Other'],
                onChanged: (val) => setState(() => nationality = val!),
              ),
              _buildCard(
                icon: Icons.calendar_today,
                title: 'In what year were you born?',
                controller: yearBornController,
                keyboardType: TextInputType.number,
              ),
              _buildSlider(
                title:
                    'What level of approved course will you be attending in 2025/26?',
                value: courseLevel,
                divisions: 3,
                labels: ['5', '6', '7-8', '9-10'],
                onChanged: (val) => setState(() => courseLevel = val),
              ),
              _buildDropdown<String>(
                title:
                    'What is the highest level of qualification you have been awarded?',
                value:
                    highestQualification.isEmpty ? null : highestQualification,
                items: [
                  'None',
                  'Level 5',
                  'Level 6',
                  'Level 7',
                  'Level 8',
                  'Level 9',
                  'Level 10'
                ],
                onChanged: (val) => setState(() => highestQualification = val!),
              ),
              _buildDropdown<String>(
                title: 'What year of this course will you be attending?',
                value: courseYear.isEmpty ? null : courseYear,
                items: ['1', '2', '3', '4', '5+'],
                onChanged: (val) => setState(() => courseYear = val!),
              ),
              _buildDropdown<String>(
                title:
                    'Select the class of applicant under which you will apply',
                value: applicantClass,
                items: ['Dependent', 'Independent', 'Mature'],
                onChanged: (val) => setState(() => applicantClass = val!),
              ),
              _buildCard(
                icon: Icons.family_restroom,
                title:
                    'How many people in the household (excluding you) will be attending full-time further or higher education in 2025/26?',
                controller: otherStudentsController,
                keyboardType: TextInputType.number,
              ),
              _buildCard(
                icon: Icons.euro,
                title: 'Household Income (€)',
                controller: incomeController,
                keyboardType: TextInputType.number,
              ),
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
                  onChanged: (val) => setState(() => livesFar = val),
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
                        isEligible == true ? Icons.check_circle : Icons.error,
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

  Widget _buildDropdown<T>({
    required String title,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items
                .map((e) =>
                    DropdownMenuItem<T>(value: e, child: Text(e.toString())))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            validator: (val) => val == null ? 'Please select an option' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required int divisions,
    required List<String> labels,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16)),
        Slider(
          value: value,
          min: 0,
          max: divisions.toDouble(),
          divisions: divisions,
          label: labels[value.toInt()],
          onChanged: onChanged,
        ),
        Center(
            child: Text(labels[value.toInt()], style: TextStyle(fontSize: 16))),
      ],
    );
  }
}
