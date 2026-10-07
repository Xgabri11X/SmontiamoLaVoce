import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playWav(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes, mimeType: 'audio/wav'));
  }

  Future<void> stop() => _player.stop();
  Future<void> dispose() => _player.dispose();
}
