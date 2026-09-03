import 'package:audioplayers/audioplayers.dart';

/// Thin seam over [AudioPlayer] for the alert sound.
///
/// `AudioPlayer` แตะ platform channel ตั้งแต่ constructor จึงสร้างใน unit test
/// ไม่ได้เลย — interface นี้ทำให้ test ยัด fake เข้ามาแทนได้
abstract class AlertSoundPlayer {
  Future<void> playAlert();
  Future<void> dispose();
}

/// Production implementation — เล่นไฟล์เสียงจริงผ่าน audioplayers
class AudioPlayerAlertSound implements AlertSoundPlayer {
  AudioPlayer? _player;

  @override
  Future<void> playAlert() async {
    _player ??= AudioPlayer();
    await _player!.play(AssetSource('sounds/alert.wav'));
  }

  @override
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
