import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:avatar_glow/avatar_glow.dart';

// Chat Voice Indicator Widget
class ChatVoiceIndicator extends StatelessWidget {
  final double soundLevel;
  final String locale;
  final Function(String) onLanguageChange;
  final VoidCallback onStop;
  final VoidCallback? onFullScreen; // Added full-screen callback
  final String detectedLanguage;
  final double languageConfidence;

  const ChatVoiceIndicator({
    super.key,
    required this.soundLevel,
    required this.locale,
    required this.onLanguageChange,
    required this.onStop,
    this.onFullScreen, // Optional full-screen callback
    required this.detectedLanguage,
    required this.languageConfidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // Increased from 80 for better visibility
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Animated mic icon
          const AvatarGlow(
            endRadius: 15,
            glowColor: Color(0xFF047A62),
            child: Icon(
              Icons.mic_rounded,
              color: Color(0xFF047A62),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Sound wave bars and text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sound wave bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final barHeight = 3.0 + (soundLevel * 17.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 3,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF047A62),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'Listening...',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF047A62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                // Phase 2: Show detected language and confidence
                if (detectedLanguage != 'unknown')
                  Text(
                    '${detectedLanguage == 'urdu' ? 'اردو' : 'English'} detected (${(languageConfidence * 100).toInt()}%)',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF047A62).withValues(alpha: 0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),

          // Language toggle and stop button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Language toggle - Enhanced
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => onLanguageChange('en_US'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6), // Increased padding
                      decoration: BoxDecoration(
                        color: locale == 'en_US'
                            ? const Color(0xFF047A62)
                            : Colors.transparent,
                        border: locale == 'en_US'
                            ? null
                            : Border.all(color: const Color(0xFF047A62)),
                        borderRadius:
                            BorderRadius.circular(12), // Increased radius
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🇺🇸', // Flag emoji
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'English',
                            style: GoogleFonts.poppins(
                              fontSize: 12, // Increased from 10
                              color: locale == 'en_US'
                                  ? Colors.white
                                  : const Color(0xFF047A62),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4), // Increased spacing
                  GestureDetector(
                    onTap: () => onLanguageChange('ur_PK'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6), // Increased padding
                      decoration: BoxDecoration(
                        color: locale == 'ur_PK'
                            ? const Color(0xFF047A62)
                            : Colors.transparent,
                        border: locale == 'ur_PK'
                            ? null
                            : Border.all(color: const Color(0xFF047A62)),
                        borderRadius:
                            BorderRadius.circular(12), // Increased radius
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🇵🇰', // Flag emoji
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'اردو',
                            style: GoogleFonts.poppins(
                              fontSize: 12, // Increased from 10
                              color: locale == 'ur_PK'
                                  ? Colors.white
                                  : const Color(0xFF047A62),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Phase 2: Full-screen voice toggle
              GestureDetector(
                onTap: onFullScreen ??
                    () {
                      // Default behavior if no callback provided
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Full-screen voice mode coming soon!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: const Color(0xFF047A62),
                        ),
                      );
                    },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: Colors.blue[700], size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Full Screen',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Stop button - Enhanced
              GestureDetector(
                onTap: onStop,
                child: Container(
                  width: 36, // Increased from 30
                  height: 36, // Increased from 30
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 18, // Increased from 16
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Enhanced Chat Mic Button Widget
class ChatMicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const ChatMicButton({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tooltip for discoverability
        Tooltip(
          message: 'Tap to speak 🎤',
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56, // Increased from 42 to match send button
              height: 56, // Increased from 42 to match send button
              decoration: BoxDecoration(
                color: isListening
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isListening)
                    BoxShadow(
                      color: const Color(0xFF047A62).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  if (isListening)
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing animation when idle
                  if (!isListening)
                    TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 2),
                      tween: Tween(begin: 1.0, end: 1.1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                const Color(0xFF047A62).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  // Mic icon
                  Icon(
                    isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: isListening
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF047A62),
                    size: 28, // Increased from 20
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Label for better discoverability
        Text(
          'Voice',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color:
                isListening ? const Color(0xFFD32F2F) : const Color(0xFF047A62),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
