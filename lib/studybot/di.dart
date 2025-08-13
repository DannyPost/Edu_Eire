// lib/studybot/di.dart
//
// StudyBot dependency graph (Flutter-side).
// Wires services ➜ repositories ➜ use-cases ➜ state notifiers.
// Uses FirebaseAuth for real ID tokens in dev (and prod later).

import 'package:firebase_auth/firebase_auth.dart';

import 'services/api_client.dart';
import 'services/auth_service.dart'; // must contain FirebaseAuthService (see note below)

import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/grade_repository_impl.dart';

import 'domain/usecases/send_chat_message.dart';
import 'domain/usecases/grade_answer.dart';
import 'domain/usecases/get_exemplar.dart';

import 'state/chat/chat_notifier.dart';
import 'state/grade/grade_notifier.dart';
import 'state/exemplar/exemplar_notifier.dart';

class StudyBotDI {
  // ── Low-level services ──────────────────────────────────────────
  late final AuthService _auth;
  late final ApiClient _api;

  // ── Data layer (repositories) ───────────────────────────────────
  late final ChatRepositoryImpl _chatRepo;
  late final GradeRepositoryImpl _gradeRepo;

  // ── Domain layer (use cases) ────────────────────────────────────
  late final SendChatMessage sendChatMessage;
  late final GradeAnswer gradeAnswer;
  late final GetExemplar getExemplar;

  // ── State layer (notifiers) ─────────────────────────────────────
  late final ChatNotifier chatNotifier;
  late final GradeNotifier gradeNotifier;
  late final ExemplarNotifier exemplarNotifier;

  StudyBotDI._();

  /// Dev graph using **FirebaseAuth** so API calls include a real JWT.
  /// You can still override `auth`/`api` in tests.
  factory StudyBotDI.dev({AuthService? auth, ApiClient? api}) {
    final di = StudyBotDI._();

    // Use FirebaseAuth-backed AuthService by default.
    di._auth = auth ?? FirebaseAuthService(firebaseAuth: FirebaseAuth.instance);

    // Single HTTP client reused everywhere.
    di._api = api ?? ApiClient(di._auth);

    // Repositories
    di._chatRepo = ChatRepositoryImpl(di._api);
    di._gradeRepo = GradeRepositoryImpl(di._api);

    // Use cases
    di.sendChatMessage = SendChatMessage(di._chatRepo);
    di.gradeAnswer     = GradeAnswer(di._gradeRepo);
    di.getExemplar     = GetExemplar(di._gradeRepo);

    // Notifiers
    di.chatNotifier     = ChatNotifier(di.sendChatMessage);
    di.gradeNotifier    = GradeNotifier(di.gradeAnswer);
    di.exemplarNotifier = ExemplarNotifier(di.getExemplar);

    return di;
  }

  /// No-op when using FirebaseAuthService (token is fetched per-call).
  /// Kept for compatibility if you ever inject a DevAuthService in tests.
  void setAuthToken(String? _token) {}

  /// Clean up network resources (call from your root widget's dispose()).
  void dispose() {
    _api.close();
  }
}
