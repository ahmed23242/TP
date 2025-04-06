import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/audio_service.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String?) onRecordingComplete;
  final String? initialRecordingPath;

  const AudioRecorderWidget({
    Key? key,
    required this.onRecordingComplete,
    this.initialRecordingPath,
  }) : super(key: key);

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final _audioService = AudioService();
  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentRecordingPath = widget.initialRecordingPath;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final success = await _audioService.startRecording();
    if (success) {
      setState(() => _isRecording = true);
    } else {
      Get.snackbar(
        'Error',
        'Failed to start recording',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioService.stopRecording();
    setState(() {
      _isRecording = false;
      _currentRecordingPath = path;
    });
    widget.onRecordingComplete(path);
  }

  Future<void> _playRecording() async {
    if (_currentRecordingPath == null) return;
    
    final success = await _audioService.playRecording(_currentRecordingPath!);
    if (success) {
      setState(() => _isPlaying = true);
    } else {
      Get.snackbar(
        'Error',
        'Failed to play recording',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopPlaying() async {
    await _audioService.stopPlaying();
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              color: _isRecording ? Colors.red : Colors.blue,
            ),
            if (_currentRecordingPath != null) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                onPressed: _isPlaying ? _stopPlaying : _playRecording,
                color: Colors.blue,
              ),
            ],
          ],
        ),
        if (_isRecording)
          const Text(
            'Recording...',
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }
} 