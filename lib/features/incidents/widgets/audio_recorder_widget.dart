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
  bool _hasConfirmedRecording = false;

  @override
  void initState() {
    super.initState();
    _currentRecordingPath = widget.initialRecordingPath;
    _hasConfirmedRecording = widget.initialRecordingPath != null;
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_hasConfirmedRecording) {
      final shouldRerecord = await _showRerecordConfirmationDialog();
      if (!shouldRerecord) return;
    }
    
    final success = await _audioService.startRecording();
    if (success) {
      setState(() => _isRecording = true);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<bool> _showRerecordConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remplacer l\'enregistrement?'),
        content: const Text('Voulez-vous remplacer l\'enregistrement vocal existant par un nouveau?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remplacer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _stopRecording() async {
    final path = await _audioService.stopRecording();
    setState(() {
      _isRecording = false;
      _currentRecordingPath = path;
      _hasConfirmedRecording = false;
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
        'Erreur',
        'Impossible de lire l\'enregistrement',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopPlaying() async {
    await _audioService.stopPlaying();
    setState(() => _isPlaying = false);
  }

  void _confirmRecording() {
    setState(() {
      _hasConfirmedRecording = true;
    });
    Get.snackbar(
      'Enregistrement confirmé',
      'La note vocale a été confirmée',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _deleteRecording() {
    setState(() {
      _currentRecordingPath = null;
      _hasConfirmedRecording = false;
    });
    widget.onRecordingComplete(null);
    Get.snackbar(
      'Enregistrement supprimé',
      'La note vocale a été supprimée',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
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
              tooltip: _isRecording ? 'Arrêter l\'enregistrement' : 'Commencer l\'enregistrement',
            ),
            if (_currentRecordingPath != null) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                onPressed: _isPlaying ? _stopPlaying : _playRecording,
                color: Colors.blue,
                tooltip: _isPlaying ? 'Arrêter la lecture' : 'Écouter l\'enregistrement',
              ),
              if (!_hasConfirmedRecording) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _confirmRecording,
                  color: Colors.green,
                  tooltip: 'Confirmer cet enregistrement',
                ),
              ],
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteRecording,
                color: Colors.red,
                tooltip: 'Supprimer l\'enregistrement',
              ),
            ],
          ],
        ),
        if (_isRecording)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Enregistrement en cours...',
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (_currentRecordingPath != null && !_isRecording)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _hasConfirmedRecording 
                ? 'Note vocale enregistrée ✓' 
                : 'Note vocale en attente de confirmation',
              style: TextStyle(
                color: _hasConfirmedRecording ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
} 