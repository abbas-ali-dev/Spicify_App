import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  AudioPlayer audioPlayer = AudioPlayer();
  final ValueNotifier<String?> currentAudioUrlNotifier = ValueNotifier(null);

  String? get _currentAudioUrl => currentAudioUrlNotifier.value;

  factory AudioManager() => _instance;

  AudioManager._internal() {
    _initListeners();
  }

  void _initListeners() {
    audioPlayer.onPlayerComplete.listen((_) {
      currentAudioUrlNotifier.value = null;
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        currentAudioUrlNotifier.value = null;
      }
    });
  }

  Future<void> toggleAudio(String audioUrl) async {
    if (_currentAudioUrl == audioUrl &&
        audioPlayer.state == PlayerState.playing) {
      await stopAudio();
    } else {
      await playAudio(audioUrl);
    }
  }

  Future<void> playAudio(String audioUrl) async {
    try {
      if (_currentAudioUrl != null) {
        await stopAudio();
      }

      await audioPlayer.play(UrlSource(audioUrl));
      currentAudioUrlNotifier.value = audioUrl;
    } catch (e) {
      audioPlayer.dispose();
      audioPlayer = AudioPlayer();
      _initListeners();

      await audioPlayer.play(UrlSource(audioUrl));
      currentAudioUrlNotifier.value = audioUrl;
    }
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    currentAudioUrlNotifier.value = null;
  }

  bool isPlaying(String audioUrl) =>
      _currentAudioUrl == audioUrl && audioPlayer.state == PlayerState.playing;

  void dispose() {
    audioPlayer.dispose();
    //currentAudioUrlNotifier.dispose();
  }
}
