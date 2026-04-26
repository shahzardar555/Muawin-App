import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSearchOverlay extends StatefulWidget {
  final SpeechToText speechToText;
  final Function(String) onResult;
  final Function(bool) onListeningStateChanged;
  final Function() onCancel;

  const VoiceSearchOverlay({
    super.key,
    required this.speechToText,
    required this.onResult,
    required this.onListeningStateChanged,
    required this.onCancel,
  });

  @override
  State<VoiceSearchOverlay> createState() => _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends State<VoiceSearchOverlay>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _recognizedWords = '';
  double _confidence = 0.0;
  double _soundLevel = 0.0;
  String _selectedLocale = 'en_US';
  final List<double> _soundWaveBars = List.filled(5, 4.0);
  Timer? _soundWaveTimer;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _soundWaveTimer?.cancel();
    super.dispose();
  }

  void _startListening() async {
    if (!mounted) return;

    setState(() => _isListening = true);
    widget.onListeningStateChanged(true);

    await widget.speechToText.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognizedWords = result.recognizedWords;
          _confidence = result.confidence;
        });
        if (result.finalResult) {
          widget.onResult(_recognizedWords);
        }
      },
      localeId: _selectedLocale,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        onDevice: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        autoPunctuation: true,
      ),
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _soundLevel = level);
        _updateSoundWaves();
      },
    );

    // Start sound wave animation
    _soundWaveTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isListening) {
        _updateSoundWaves();
      }
    });
  }

  void _updateSoundWaves() {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _soundWaveBars.length; i++) {
        _soundWaveBars[i] = 4.0 + (_soundLevel * 26.0) + (i * 2.0);
        _soundWaveBars[i] = _soundWaveBars[i].clamp(4.0, 30.0);
      }
    });
  }

  void _stopListening() async {
    await widget.speechToText.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
    widget.onListeningStateChanged(false);
    _soundWaveTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Language toggle chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLanguageChip('🇬🇧 English', 'en_US'),
                const SizedBox(width: 12),
                _buildLanguageChip('🇵🇰 اردو', 'ur_PK'),
              ],
            ),
            const SizedBox(height: 32),

            // Avatar glow with mic
            AvatarGlow(
              glowColor: const Color(0xFF047A62),
              endRadius: 50.0,
              animate: _isListening,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF047A62),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status text
            Text(
              _isListening ? 'Listening...' : 'Tap to speak',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Live transcription
            if (_recognizedWords.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"$_recognizedWords"',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              ),
            const SizedBox(height: 16),

            // Sound wave bars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 4,
                  height: _soundWaveBars[index],
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047A62),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Confidence level
            if (_confidence > 0.0)
              Column(
                children: [
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _confidence,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF047A62)),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start/Stop button
                ElevatedButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isListening ? Colors.red : const Color(0xFF047A62),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    _isListening ? '⏹ Stop' : '🎤 Start Speaking',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Cancel button
                TextButton(
                  onPressed: () {
                    _stopListening();
                    widget.onCancel();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String label, String locale) {
    final isSelected = _selectedLocale == locale;
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _selectedLocale = locale;
        });
        if (_isListening) {
          _stopListening();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _startListening();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF047A62) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF047A62) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
