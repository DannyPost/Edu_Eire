class Course {
  final String level;
  final String code;
  final String title;
  final String location;
  final String university;
  final String jobField;

  Course({
    required this.level,
    required this.code,
    required this.title,
    required this.location,
    required this.university,
    required this.jobField,
  });

  factory Course.fromCsv(List<dynamic> row) {
    String clean(dynamic v) =>
        v.toString().replaceAll('"', '').trim();

    return Course(
      level: clean(row[0]),
      code: clean(row[1]),
      title: clean(row[2]),
      location: clean(row[3]),
      university: clean(row[4]).toUpperCase(),
      jobField: clean(row[5]),
    );
  }
}
