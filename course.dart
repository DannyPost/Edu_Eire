// models/course.dart
class Course {
  final String level, code, title, location, university, jobField;

  Course(this.level, this.code, this.title, this.location, this.university, this.jobField);

  factory Course.fromList(List<String> values) {
    return Course(values[0], values[1], values[2], values[3], values[4], values[5]);
  }
}
