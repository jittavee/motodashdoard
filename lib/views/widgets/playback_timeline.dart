import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/ecu_data_controller.dart';

class PlaybackTimeline extends StatelessWidget {
  const PlaybackTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();

    return Obx(() {
      if (!ecuController.isPlaybackMode.value) {
        return const SizedBox.shrink();
      }

      final logs = ecuController.playbackLogs;
      if (logs.isEmpty) return const SizedBox.shrink();

      final currentIndex = ecuController.playbackIndex.value;
      final isPlaying = ecuController.isPlaying.value;
      final speed = ecuController.playbackSpeed.value;

      final startTime = logs.first.timestamp;
      final endTime = logs.last.timestamp;
      final currentTime = logs[currentIndex].timestamp;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(color: Colors.cyan.withValues(alpha: 0.5), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Play/Pause Button
              IconButton(
                onPressed: () {
                  if (isPlaying) {
                    ecuController.pausePlayback();
                  } else {
                    ecuController.playPlayback();
                  }
                },
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.cyan,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),

              // Start Time
              Text(
                DateFormat('HH:mm:ss').format(startTime),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),

              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.cyan,
                    inactiveTrackColor: Colors.grey[700],
                    thumbColor: Colors.cyan,
                    overlayColor: Colors.cyan.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: currentIndex.toDouble(),
                    min: 0,
                    max: (logs.length - 1).toDouble(),
                    onChanged: (value) {
                      ecuController.seekPlayback(value.toInt());
                    },
                  ),
                ),
              ),

              // End Time
              Text(
                DateFormat('HH:mm:ss').format(endTime),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),

              const SizedBox(width: 8),

              // Current Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
                ),
                child: Text(
                  DateFormat('HH:mm:ss').format(currentTime),
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Speed Button
              GestureDetector(
                onTap: () => _showSpeedMenu(context, ecuController),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${speed}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Exit Button
              IconButton(
                onPressed: () => ecuController.exitPlayback(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Exit Playback',
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showSpeedMenu(BuildContext context, ECUDataController controller) {
    final speeds = [0.5, 1.0, 2.0, 4.0];

    showMenu<double>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: speeds.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Text('${speed}x'),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        controller.setPlaybackSpeed(value);
      }
    });
  }
}
