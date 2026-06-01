// FuelIQ — OCR Service (Google ML Kit)
// On-device receipt text extraction and parsing

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../shared/models/models.dart';

part 'ocr_service.g.dart';

@riverpod
OcrService ocrService(OcrServiceRef ref) => OcrService();

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Main entry point: process an image file and return parsed fuel data.
  Future<ParsedReceiptData> processReceiptImage(File imageFile) async {
    // 1. Preprocess image for better OCR accuracy
    final processedFile = await _preprocessImage(imageFile);

    // 2. Run ML Kit OCR
    final inputImage = InputImage.fromFile(processedFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    // 3. Parse extracted text
    final parsed = _parseReceiptText(recognizedText);

    return parsed;
  }

  /// Image preprocessing: enhance contrast, correct perspective.
  Future<File> _preprocessImage(File original) async {
    final bytes = await original.readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) return original;

    // Normalize size (max 1080px for OCR)
    if (image.width > 1080 || image.height > 1080) {
      image = img.copyResize(image, width: 1080);
    }

    // Increase contrast for better text recognition
    image = img.adjustColor(image, contrast: 1.2);

    // Convert to grayscale
    image = img.grayscale(image);

    final processedBytes = img.encodeJpg(image, quality: 90);
    final tempPath = '${original.parent.path}/ocr_processed.jpg';
    final processedFile = File(tempPath)..writeAsBytesSync(processedBytes);

    return processedFile;
  }

  /// Parse ML Kit text blocks to extract fuel receipt fields.
  ParsedReceiptData _parseReceiptText(RecognizedText recognizedText) {
    final fullText = recognizedText.text;
    final lines = fullText.split('\n').map((l) => l.trim()).toList();

    double? volume;
    double? pricePerLiter;
    double? totalAmount;
    DateTime? date;
    String? stationName;

    double volumeConf = 0.0;
    double priceConf = 0.0;
    double totalConf = 0.0;
    double dateConf = 0.0;

    for (final line in lines) {
      final lower = line.toLowerCase();

      // ── Volume ──────────────────────────────────────────────────────────────
      // Patterns: "35.5 L", "35.50 Ltrs", "Volume: 35.5"
      if (volume == null) {
        final volumeMatch = RegExp(
          r'(\d{1,3}\.?\d{0,3})\s*(?:l(?:itre?s?)?|ltr)',
          caseSensitive: false,
        ).firstMatch(line);
        if (volumeMatch != null) {
          final val = double.tryParse(volumeMatch.group(1)!);
          if (val != null && val > 0.5 && val < 500) {
            volume = val;
            volumeConf = 0.85;
          }
        }
      }

      // ── Price Per Liter ───────────────────────────────────────────────────
      // Patterns: "₹96.72/L", "Rate: 96.72", "Price/Litre 96.72"
      if (pricePerLiter == null) {
        final priceMatch = RegExp(
          r'(?:rate|price|₹|rs\.?)\s*:?\s*(\d{2,3}\.?\d{0,2})\s*(?:\/\s*l|per\s*l)?',
          caseSensitive: false,
        ).firstMatch(line);
        if (priceMatch != null) {
          final val = double.tryParse(priceMatch.group(1)!);
          if (val != null && val > 50 && val < 300) {
            // Sanity check: fuel price range
            pricePerLiter = val;
            priceConf = 0.80;
          }
        }
      }

      // ── Total Amount ──────────────────────────────────────────────────────
      // Patterns: "Total: ₹3457.60", "Amount: 3457.60", "Net Amount 3457"
      if (totalAmount == null) {
        final totalMatch = RegExp(
          r'(?:total|amount|net|grand\s*total)\s*:?\s*₹?\s*(\d+\.?\d{0,2})',
          caseSensitive: false,
        ).firstMatch(line);
        if (totalMatch != null) {
          final val = double.tryParse(totalMatch.group(1)!);
          if (val != null && val > 50) {
            totalAmount = val;
            totalConf = 0.85;
          }
        }
      }

      // ── Date ──────────────────────────────────────────────────────────────
      // Patterns: "12/05/2026", "12-05-2026", "12 May 2026"
      if (date == null) {
        final dateMatch = RegExp(
          r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})',
        ).firstMatch(line);
        if (dateMatch != null) {
          try {
            final day = int.parse(dateMatch.group(1)!);
            final month = int.parse(dateMatch.group(2)!);
            var year = int.parse(dateMatch.group(3)!);
            if (year < 100) year += 2000;
            date = DateTime(year, month, day);
            if (date.isAfter(DateTime.now())) date = null; // Future dates invalid
            dateConf = date != null ? 0.90 : 0.0;
          } catch (_) {
            // Parse failed
          }
        }
      }
    }

    // Cross-validate: if volume and total known, derive/verify price
    if (volume != null && totalAmount != null && pricePerLiter == null) {
      final derived = totalAmount / volume;
      if (derived > 50 && derived < 300) {
        pricePerLiter = derived;
        priceConf = 0.70; // Lower confidence (derived)
      }
    }

    return ParsedReceiptData(
      volumeLiters: volume,
      pricePerLiter: pricePerLiter,
      totalAmount: totalAmount,
      date: date,
      volumeConfidence: volumeConf,
      priceConfidence: priceConf,
      totalConfidence: totalConf,
      dateConfidence: dateConf,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Confidence level interpretation for UI display
extension ParsedReceiptDataX on ParsedReceiptData {
  bool get isVolumeConfident => volumeConfidence >= 0.75;
  bool get isPriceConfident => priceConfidence >= 0.75;
  bool get isTotalConfident => totalConfidence >= 0.75;
  bool get isDateConfident => dateConfidence >= 0.75;
  
  /// Overall confidence as a percentage string
  String get overallConfidenceText {
    final avg = (volumeConfidence + priceConfidence + totalConfidence + dateConfidence) / 4;
    if (avg >= 0.85) return 'High confidence';
    if (avg >= 0.65) return 'Medium confidence';
    return 'Low confidence — please verify';
  }
  
  /// Fields count that were successfully extracted
  int get extractedFieldCount {
    int count = 0;
    if (volumeLiters != null) count++;
    if (pricePerLiter != null) count++;
    if (totalAmount != null) count++;
    if (date != null) count++;
    return count;
  }
}
