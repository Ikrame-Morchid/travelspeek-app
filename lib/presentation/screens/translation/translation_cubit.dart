import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/voice_translation_repository.dart';
import '../../../data/repositories/image_translation_repository.dart';

abstract class TranslationState {}

class TranslationInitial   extends TranslationState {}
class TranslationRecording extends TranslationState {}
class TranslationLoading   extends TranslationState {}

class TranslationSuccess extends TranslationState {
  final VoiceTranslationResult result;
  TranslationSuccess(this.result);
}

class ImageTranslationSuccess extends TranslationState {
  final String       extractedText;
  final String       translatedText;
  final String       sourceLang;
  final String       targetLang;
  final bool         hasOffensiveContent;
  final String       hateSpeechMessage;
  final List<String> offensiveWords;
  final String       censoredText;
  final int          totalBlocks;

  ImageTranslationSuccess({
    required this.extractedText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.hasOffensiveContent,
    required this.hateSpeechMessage,
    required this.offensiveWords,
    required this.censoredText,
    required this.totalBlocks,
  });
}

class TranslationError extends TranslationState {
  // ✅ errorKey = clé de traduction, errorDetail = détail technique ($e)
  final String errorKey;
  final String errorDetail;
  TranslationError(this.errorKey, this.errorDetail);
}

class TranslationCubit extends Cubit<TranslationState> {
  final VoiceTranslationRepository _voiceRepo = VoiceTranslationRepository();
  final ImageTranslationRepository _imageRepo = ImageTranslationRepository();

  TranslationCubit() : super(TranslationInitial());

  Future<void> startRecording() async {
    try {
      await _voiceRepo.startRecording();
      emit(TranslationRecording());
    } catch (e) {
      emit(TranslationError('error_cannot_start', '$e')); // ✅ CORRIGÉ
    }
  }

  Future<void> stopAndTranslate(
    String targetLang, {
    bool checkHateSpeech = false,
    bool censorOutput    = false,
  }) async {
    try {
      emit(TranslationLoading());
      final result = await _voiceRepo.stopAndTranslate(
        targetLang,
        checkHateSpeech: checkHateSpeech,
        censorOutput:    censorOutput,
      );
      emit(TranslationSuccess(result));
    } catch (e) {
      emit(TranslationError('error_voice_translation', '$e')); // ✅ CORRIGÉ
    }
  }

  Future<void> playAudio(String audioUrl) async {
    try {
      await _voiceRepo.playAudio(audioUrl);
    } catch (e) {
      emit(TranslationError('error_audio_playback', '$e')); // ✅ CORRIGÉ
    }
  }

  Future<void> translateImage({
    required File   imageFile,
    required String sourceLang,
    required String targetLang,
    bool enhance = true,
  }) async {
    try {
      emit(TranslationLoading());
      final result = await _imageRepo.translateImage(
        imageFile:  imageFile,
        sourceLang: sourceLang,
        targetLang: targetLang,
        enhance:    enhance,
      );
      emit(ImageTranslationSuccess(
        extractedText:       result.extractedText,
        translatedText:      result.translatedText,
        sourceLang:          result.sourceLang,
        targetLang:          result.targetLang,
        hasOffensiveContent: result.hasOffensiveContent,
        hateSpeechMessage:   result.hateSpeechMessage,
        offensiveWords:      result.offensiveWords,
        censoredText:        result.censoredText,
        totalBlocks:         result.totalBlocks,
      ));
    } catch (e) {
      emit(TranslationError('error_image_translation', '$e')); // ✅ CORRIGÉ
    }
  }

  void reset() => emit(TranslationInitial());
}