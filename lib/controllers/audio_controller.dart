import 'dart:io';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class AudioController extends GetxController {
  final AudioPlayer playerA = AudioPlayer();
  final AudioPlayer playerB = AudioPlayer();
  var isPlayingA = true.obs;
  var filePathA = ''.obs;
  var filePathB = ''.obs;
  var fileNameA = 'File A'.obs;
  var fileNameB = 'File B'.obs;
  var position = Duration.zero.obs;
  var duration = Duration.zero.obs;
  var volumeA = 0.0.obs;
  var volumeB = 0.0.obs;
  var masterVolume = 1.0.obs;

  Future<void> init() async {
    if (filePathA.value.isNotEmpty && filePathB.value.isNotEmpty) {
      await playerA.setFilePath(filePathA.value);
      await playerB.setFilePath(filePathB.value);

      playerA.positionStream.listen((position) {
        if (isPlayingA.value) {
          this.position.value = position;
        }
      });

      playerB.positionStream.listen((position) {
        if (!isPlayingA.value) {
          this.position.value = position;
        }
      });

      playerA.durationStream.listen((duration) {
        if (isPlayingA.value) {
          this.duration.value = duration ?? Duration.zero;
        }
      });

      playerB.durationStream.listen((duration) {
        if (!isPlayingA.value) {
          this.duration.value = duration ?? Duration.zero;
        }
      });
    }
  }

  void togglePlay() {
    if (isPlayingA.value) {
      playerA.pause();
      playerB.play();
    } else {
      playerB.pause();
      playerA.play();
    }
    isPlayingA.value = !isPlayingA.value;
  }

  void play() {
    if (isPlayingA.value) {
      playerA.play();
    } else {
      playerB.play();
    }
  }

  void pause() {
    playerA.pause();
    playerB.pause();
  }

  void stop() {
    playerA.stop();
    playerB.stop();
    playerA.seek(Duration.zero);
    playerB.seek(Duration.zero);
    position.value = Duration.zero;
  }

  void setVolumeA(double volume) {
    volumeA.value = volume;
    playerA.setVolume(_calculateVolumeGain(volume));
  }

  void setVolumeB(double volume) {
    volumeB.value = volume;
    playerB.setVolume(_calculateVolumeGain(volume));
  }

  double _calculateVolumeGain(double volume) {
    return (volume + 10) / 10;  // Centered at 0, adjusted by a step of 0.5
  }

  void setMasterVolume(double volume) {
    masterVolume.value = volume;
    playerA.setVolume(volume);
    playerB.setVolume(volume);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (hours > 0) hours, minutes, seconds].join(':');
  }

  Future<void> instantSwitch() async {
    final currentPosition = position.value;
    if (isPlayingA.value) {
      await playerB.seek(currentPosition);
      await playerB.play();
      await playerA.pause();
    } else {
      await playerA.seek(currentPosition);
      await playerA.play();
      await playerB.pause();
    }
    isPlayingA.value = !isPlayingA.value;
  }

  @override
  void onClose() {
    playerA.dispose();
    playerB.dispose();
    super.onClose();
  }
}
