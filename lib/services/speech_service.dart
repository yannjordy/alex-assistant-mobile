class SpeechService {
  bool _available = false;
  bool get isListening => false;

  Future<bool> init({void Function(String status)? onStatus, void Function(String error)? onError}) async {
    _available = false;
    return false;
  }

  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    return false;
  }

  Future<void> stopListening() async {}
  Future<void> cancel() async {}
}
