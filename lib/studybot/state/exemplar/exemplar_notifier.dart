import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_exemplar.dart';
import '../common/status.dart';
import 'exemplar_state.dart';

class ExemplarNotifier extends ChangeNotifier {
  final GetExemplar _getExemplar;

  ExemplarNotifier(this._getExemplar);

  ExemplarState _state = const ExemplarState();
  ExemplarState get state => _state;

  Future<void> generate({
    required String question,
    Map<String, dynamic>? meta,
  }) async {
    _state = _state.copyWith(status: Status.loading, errorMessage: null, text: null);
    notifyListeners();

    try {
      final text = await _getExemplar(question: question, meta: meta);
      _state = _state.copyWith(status: Status.success, text: text);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(status: Status.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  void reset() {
    _state = const ExemplarState();
    notifyListeners();
  }
}
