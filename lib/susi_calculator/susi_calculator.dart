import 'package:flutter/material.dart';



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

void calculateGrant() {
  final income = double.tryParse(incomeController.text) ?? 0;
  final dependents = int.tryParse(dependentsController.text) ?? 0;
  final otherStudents = int.tryParse(otherStudentsController.text) ?? 0;

  if (residencyStatus != 'Yes' || (nationality == 'Other')) {
    setState(() {
      result = 'Not eligible due to residency or nationality restrictions.';
      resultColor = Colors.red.shade100;
      isEligible = false;
    });
    return;
  }

  // Adjust mapping for slider values (0=Level 5, 1=Level 6, 2=Level 7-8, 3=Level 9-10)
  int sliderLevel;
  switch (courseLevel.toInt()) {
    case 0:
      sliderLevel = 5;
      break;
    case 1:
      sliderLevel = 6;
      break;
    case 2:
      sliderLevel = 7;
      break;
    case 3:
      sliderLevel = 9;
      break;
    default:
      sliderLevel = 5;
  }

  int previousLevel =
      int.tryParse(highestQualification.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  if (sliderLevel <= previousLevel) {
    setState(() {
      result =
          'Not eligible: Course level must be higher than your previous qualification.';
      resultColor = Colors.red.shade100;
      isEligible = false;
    });
    return;
  }

  double specialRateThreshold;
  double band1Threshold;
  double band2Threshold;
  double band3Threshold;
  double band4Threshold;

  if (dependents < 4) {
    specialRateThreshold = 27400;
    band1Threshold = 47010;
    band2Threshold = 48270;
    band3Threshold = 51040;
    band4Threshold = 58470;
  } else if (dependents >= 4 && dependents <= 7) {
    specialRateThreshold = 30030;
    band1Threshold = 51520;
    band2Threshold = 52900;
    band3Threshold = 55940;
    band4Threshold = 64080;
  } else {
    specialRateThreshold = 32555;
    band1Threshold = 55850;
    band2Threshold = 57345;
    band3Threshold = 60635;
    band4Threshold = 69465;
  }

  double additionalAllowance = otherStudents * 4950;
  specialRateThreshold += additionalAllowance;
  band1Threshold += additionalAllowance;
  band2Threshold += additionalAllowance;
  band3Threshold += additionalAllowance;
  band4Threshold += additionalAllowance;

  String band;
  double grantAmount;

  if (income <= specialRateThreshold) {
    band = 'Special Rate';
    grantAmount = livesFar ? 7586 : 3230;
  } else if (income <= band1Threshold) {
    band = 'Band 1';
    grantAmount = livesFar ? 4292 : 1774;
  } else if (income <= band2Threshold) {
    band = 'Band 2';
    grantAmount = livesFar ? 3332 : 1343;
  } else if (income <= band3Threshold) {
    band = 'Band 3';
    grantAmount = livesFar ? 2502 : 975;
  } else if (income <= band4Threshold) {
    band = 'Band 4';
    grantAmount = livesFar ? 1666 : 612;
  } else {
    setState(() {
      result =
          "May not be eligible.\nYour income (€${income.toStringAsFixed(2)}) exceeds the maximum threshold (€${band4Threshold.toStringAsFixed(2)}).";
      resultColor = Colors.red.shade100;
      isEligible = false;
    });
    return;
  }

  setState(() {
    result = "You may be eligible for the $band grant!\n\n"
        "The Estimated Grant Amount is: €${grantAmount.toStringAsFixed(2)}"
        "(${livesFar ? 'non-adjacent' : 'adjacent'} rate)\n\n"
        "The Income Threshold for this band is: €${(band == 'Special Rate' ? specialRateThreshold : band == 'Band 1' ? band1Threshold : band == 'Band 2' ? band2Threshold : band == 'Band 3' ? band3Threshold : band4Threshold).toStringAsFixed(2)}";
    resultColor = Colors.green.shade100;
    isEligible = true;
  });
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
        title: Row(
          children: [
            Image.asset('assets/edu_eire_logo.png', height: 28),
            SizedBox(width: 8),
            Text('SUSI Grant Estimator', style: TextStyle(fontSize: 20)),
          ],
        ),
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
                value: highestQualification.isEmpty ? null : highestQualification,
                items: [
                  'None', 'Level 5', 'Level 6', 'Level 7', 'Level 8', 'Level 9', 'Level 10'
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
                title: 'Select the class of applicant under which you will apply',
                value: applicantClass,
                items: ['Dependent', 'Independent', 'Mature'],
                onChanged: (val) => setState(() => applicantClass = val!),
              ),
              _buildSpecialCard(
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
              ),
              SizedBox(height: 30),
              if (result.isNotEmpty)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: resultColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isEligible == true ? Icons.check_circle : Icons.error,
                        color:
                            isEligible == true ? Colors.green : Colors.redAccent,
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

  Widget _buildSpecialCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.black54),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                validator: (value) =>
                    value == null || value.isEmpty ? 'This field is required' : null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(fontSize: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: (value) =>
                value == null || value.isEmpty ? 'This field is required' : null,
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.black54),
              labelText: title,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: InputBorder.none,
            ),
            style: TextStyle(fontSize: 16),
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
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.white,
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
          activeColor: Color(0xFF49baf2),
          inactiveColor: Colors.black26,
          onChanged: onChanged,
        ),
        Center(child: Text(labels[value.toInt()], style: TextStyle(fontSize: 16))),
      ],
    );
  }
}