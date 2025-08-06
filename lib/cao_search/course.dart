// lib/cao_search/course.dart
class Course {
  final String level, code, title, location, university, jobField;

  Course(this.level, this.code, this.title, this.location, this.university, this.jobField);

  factory Course.fromList(List<String> values) {
    // Make sure the indices match your CSV column order and the number of fields
    if (values.length < 6) {
      throw Exception("Insufficient data for Course.fromList. Expected 6 values.");
    }
    // Corrected to match the order expected by the constructor
    return Course(values[0], values[1], values[2], values[3], values[4], values[5]);
  }
}