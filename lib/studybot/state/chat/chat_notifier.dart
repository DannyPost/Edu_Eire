import 'package:flutter/foundation.dart';

import '../../domain/usecases/send_chat_message.dart';
import '../common/status.dart';
import 'chat_state.dart';

class ChatNotifier extends ChangeNotifier {
  final SendChatMessage _sendChatMessage;

  ChatNotifier(this._sendChatMessage);

  ChatState _state = const ChatState();
  ChatState get state => _state;

  Future<void> routeMessage({
    required String message,
    Map<String, dynamic>? context,
  }) async {
    _state = _state.copyWith(status: Status.loading, errorMessage: null, route: null);
    notifyListeners();

    try {
      final route = await _sendChatMessage(message: message, context: context);
      _state = _state.copyWith(status: Status.success, route: route);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(status: Status.error, errorMessage: e.toString());
      notifyListeners();
    }
  }

  void reset() {
    _state = const ChatState();
    notifyListeners();
  }
}
