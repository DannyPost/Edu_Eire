import 'package:flutter/foundation.dart';

import '../../domain/entities/grade_result.dart';
import '../../domain/usecases/grade_answer.dart';
import '../common/status.dart';
import 'grade_state.dart';

class GradeNotifier extends ChangeNotifier {
  final GradeAnswer _gradeAnswer;

  GradeNotifier(this._gradeAnswer);

  GradeState _state = const GradeState();
  GradeState get state => _state;

  Future<void> submit({
    required String answer,
    required Map<String, dynamic> meta,
  }) async {
    _state = _state.copyWith(status: Status.loading, errorMessage: null, result: null);
    notifyListeners();

    try {
      final GradeResult res = await _gradeAnswer(answer: answer, meta: meta);
      _state = _state.copyWith(status: Status.success, result: res);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(status: Status.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  void reset() {
    _state = const GradeState();
    notifyListeners();
  }
}
