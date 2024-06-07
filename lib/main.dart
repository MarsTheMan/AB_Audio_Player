import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'controllers/audio_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AB Audio Player',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ABPlayerScreen(),
    );
  }
}

class ABPlayerScreen extends StatelessWidget {
  final AudioController audioController = Get.put(AudioController());

  ABPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AB Audio Player'),
        actions: [
          IconButton(onPressed: () async {
            await Get.defaultDialog(title: "Info", content: const Text("Made by MarsMan", style: TextStyle(fontWeight: FontWeight.w600),));
        }, icon: const Icon(Icons.info_outline))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAudioCard('A', audioController.fileNameA, audioController.volumeA, audioController.setVolumeA),
                  const SizedBox(width: 20),
                  _buildAudioCard('B', audioController.fileNameB, audioController.volumeB, audioController.setVolumeB),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                final position = audioController.position.value;
                final duration = audioController.duration.value;
                final remaining = duration - position;
                return Column(
                  children: [
                    Slider(
                      value: position.inSeconds.toDouble(),
                      max: duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        final newPosition = Duration(seconds: value.toInt());
                        audioController.playerA.seek(newPosition);
                        audioController.playerB.seek(newPosition);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(audioController.formatDuration(position)),
                        Text('-${audioController.formatDuration(remaining)}'),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.play_arrow, size: 42,),
                    onPressed: audioController.play,
                  ),
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.pause, size: 42,),
                    onPressed: audioController.pause,
                  ),
                  IconButton(
                    iconSize: 42,
                    icon: const Icon(Icons.stop, size: 42,),
                    onPressed: audioController.stop,
                  ),
                  const SizedBox(width: 20),
                  Obx(() {
                      return Slider(
                          value: audioController.masterVolume.value,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            audioController.setMasterVolume(value);
                          },
                        );
                    }
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioCard(String label, RxString fileName, RxDouble volume, void Function(double) setVolume) {
    return GestureDetector(
      onTap: () async {
        await audioController.instantSwitch();
      },
      child: Obx(() {
        final isPlaying = (label == 'A' && audioController.isPlayingA.value) || (label == 'B' && !audioController.isPlayingA.value);
        return Card(
          color: isPlaying ? Colors.green : Colors.white,
          child: SizedBox(
            width: 200,
            height: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(fileName.value),
                const SizedBox(height: 10),
                Ink(
                  decoration: const ShapeDecoration(
                    color: Colors.blue,
                    shape: CircleBorder(),),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

                      if (result != null && result.files.isNotEmpty) {
                        if (label == 'A') {
                          audioController.filePathA.value = result.files.first.path!;
                          audioController.fileNameA.value = result.files.first.name;
                        } else {
                          audioController.filePathB.value = result.files.first.path!;
                          audioController.fileNameB.value = result.files.first.name;
                        }
                        audioController.init();
                      } else {
                        Get.snackbar("Error", "Please select an audio file.");
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    Text('${volume.value}'),
                    SfSlider(
                      min: -10.0,
                      max: 10.0,
                      value: volume.value,
                      interval: 1,
                      showTicks: true,
                      showLabels: false,
                      stepSize: 0.5,
                      minorTicksPerInterval: 1,
                      onChanged: (dynamic value) {
                        setVolume(value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
