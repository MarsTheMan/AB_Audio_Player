import 'dart:io';
import 'dart:math';
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
  var volumeA = 0.5.obs;
  var volumeB = 0.5.obs;
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
    // Use a logarithmic scale for volume control
    if (volume < 0) {
      return pow(10, volume / 20).toDouble(); // Negative volumes get reduced logarithmically
    } else {
      return 1 + volume * 2; // Positive volumes get boosted
    }
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

  double calculateRMS(List<int> samples) {
    double squares = samples.fold(0, (sum, sample) => sum + pow(sample / 32768, 2));
    return sqrt(squares / samples.length);
  }

  Future<List<int>> _getAudioSamples(String filePath) async {
    // You will need a method to decode the audio file and extract samples.
    // This implementation assumes you have a way to do this.
    // For example, you might use an audio decoding library.
    return [];
  }

  Future<double> getRMS(String filePath) async {
    List<int> samples = await _getAudioSamples(filePath);
    return calculateRMS(samples);
  }

  Future<void> matchGain() async {
    double rmsA = await getRMS(filePathA.value);
    double rmsB = await getRMS(filePathB.value);
    double targetRMS = (rmsA + rmsB) / 2;

    double gainA = targetRMS / rmsA;
    double gainB = targetRMS / rmsB;

    playerA.setVolume(gainA);
    playerB.setVolume(gainB);

    volumeA.value = log(gainA) * 20; // Update UI volume to match gain
    volumeB.value = log(gainB) * 20; // Update UI volume to match gain
  }

  @override
  void onClose() {
    playerA.dispose();
    playerB.dispose();
    super.onClose();
  }
}
