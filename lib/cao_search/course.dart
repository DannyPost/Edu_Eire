// course.dart
class Course {
  final String level, code, title, location, university, jobField;

  Course(this.level, this.code, this.title, this.location, this.university, this.jobField);

  // This factory constructor is useful if you are specifically converting
  // a List<String> where the order directly matches your constructor.
  // Your CourseProvider is doing the mapping manually by index, which is fine too.
  factory Course.fromList(List<String> values) {
    // Ensure values[0] maps to level, values[1] to code, etc.
    // based on your CSV structure and how you parse it in CourseProvider.
    return Course(
      values[0], // level
      values[1], // code
      values[2], // title
      values[3], // location
      values[4], // university
      values[5], // jobField
    );
  }
}