import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../utils/logger.dart';

class ShareHandler {
  static final ShareHandler _instance = ShareHandler._internal();
  static const _log = Logger('ShareHandler');

  factory ShareHandler() => _instance;
  ShareHandler._internal();

  StreamSubscription? _subscription;
  void Function(String imagePath)? onImageReceived;

  Future<void> init() async {
    _log.info('Inisialisasi ShareHandler...');

    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      for (final shared in initial) {
        final path = await _saveFile(shared);
        if (path != null) onImageReceived?.call(path);
      }
      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      _log.warn('Initial share error: $e');
    }

    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) async {
        for (final shared in files) {
          final path = await _saveFile(shared);
          if (path != null) onImageReceived?.call(path);
        }
        ReceiveSharingIntent.instance.reset();
      },
      onError: (e) => _log.error('Stream error: $e'),
    );
  }

  Future<String?> _saveFile(SharedMediaFile shared) async {
    try {
      final file = File(shared.path);
      if (!await file.exists()) return null;
      final dir = await getTemporaryDirectory();
      final dest = '${dir.path}/shared_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saved = await file.copy(dest);
      return saved.path;
    } catch (e) {
      _log.error('Save error: $e');
      return null;
    }
  }

  void dispose() => _subscription?.cancel();
}