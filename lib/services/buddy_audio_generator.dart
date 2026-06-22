import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';

class BuddyAudioGenerator {
  // Generates sound if not exists and returns the file path.
  static Future<String> generateSound(String type) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/buddy_$type.wav');
      if (await file.exists()) {
        return file.path;
      }

      final sampleRate = 16000;
      List<int> pcmData = [];

      if (type == 'pop') {
        // Sweep frequency up: 300Hz to 1400Hz (cute bubble pop)
        final durationSec = 0.12;
        final totalSamples = (sampleRate * durationSec).toInt();
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final progress = i / totalSamples;
          final freq = 300 + 1100 * progress;
          final amplitude = 120 * (1.0 - progress);
          final val = 128 + (amplitude * math.sin(2 * math.pi * freq * t)).toInt();
          pcmData.add(val.clamp(0, 255));
        }
      } else if (type == 'chime') {
        // Two high-pitched cute chime notes (giggle/chime)
        final note1Duration = 0.06;
        final note2Duration = 0.14;
        final samples1 = (sampleRate * note1Duration).toInt();
        final samples2 = (sampleRate * note2Duration).toInt();
        
        // Note 1 (900 Hz)
        for (int i = 0; i < samples1; i++) {
          final t = i / sampleRate;
          final progress = i / samples1;
          final amplitude = 100 * (1.0 - progress);
          final val = 128 + (amplitude * math.sin(2 * math.pi * 900 * t)).toInt();
          pcmData.add(val.clamp(0, 255));
        }
        // Note 2 (1350 Hz)
        for (int i = 0; i < samples2; i++) {
          final t = i / sampleRate;
          final progress = i / samples2;
          final amplitude = 120 * (1.0 - progress);
          final val = 128 + (amplitude * math.sin(2 * math.pi * 1350 * t)).toInt();
          pcmData.add(val.clamp(0, 255));
        }
      } else if (type == 'jump') {
        // Cartoonish spring/jump sound (sweeps up then down)
        final durationSec = 0.22;
        final totalSamples = (sampleRate * durationSec).toInt();
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final progress = i / totalSamples;
          final freq = 400 + 700 * math.sin(math.pi * progress);
          final amplitude = 110 * (1.0 - progress);
          final val = 128 + (amplitude * math.sin(2 * math.pi * freq * t)).toInt();
          pcmData.add(val.clamp(0, 255));
        }
      } else if (type == 'gift') {
        // Celebratory magic chime sound: sweep up and down quickly, with high frequency
        final durationSec = 0.45;
        final totalSamples = (sampleRate * durationSec).toInt();
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final progress = i / totalSamples;
          // Arpeggio-like frequency pattern: beautiful magic chime
          final freq = 600 + 1200 * math.sin(2 * math.pi * 3.0 * progress); 
          final amplitude = 120 * (1.0 - progress);
          final val = 128 + (amplitude * math.sin(2 * math.pi * freq * t)).toInt();
          pcmData.add(val.clamp(0, 255));
        }
      } else {
        // Default simple beep
        final durationSec = 0.1;
        final totalSamples = (sampleRate * durationSec).toInt();
        for (int i = 0; i < totalSamples; i++) {
          final t = i / sampleRate;
          final progress = i / totalSamples;
          final val = 128 + (100 * math.sin(2 * math.pi * 1000 * t) * (1.0 - progress)).toInt();
          pcmData.add(val.clamp(0, 255));
        }
      }

      final header = _createWavHeader(pcmData.length, sampleRate);
      final fileBytes = <int>[...header, ...pcmData];
      await file.writeAsBytes(fileBytes);
      return file.path;
    } catch (e) {
      // In case of any error, return an empty string
      return '';
    }
  }

  static List<int> _createWavHeader(int numBytes, int sampleRate) {
    final header = List<int>.filled(44, 0);
    // "RIFF"
    header[0] = 0x52; header[1] = 0x49; header[2] = 0x46; header[3] = 0x46;
    // Size of the entire file minus 8
    final fileSize = numBytes + 36;
    header[4] = fileSize & 0xff;
    header[5] = (fileSize >> 8) & 0xff;
    header[6] = (fileSize >> 16) & 0xff;
    header[7] = (fileSize >> 24) & 0xff;
    // "WAVE"
    header[8] = 0x57; header[9] = 0x41; header[10] = 0x56; header[11] = 0x45;
    // "fmt "
    header[12] = 0x66; header[13] = 0x6d; header[14] = 0x74; header[15] = 0x20;
    // Chunk size (16)
    header[16] = 16; header[17] = 0; header[18] = 0; header[19] = 0;
    // Audio format (1 for PCM)
    header[20] = 1; header[21] = 0;
    // Number of channels (1 for Mono)
    header[22] = 1; header[23] = 0;
    // Sample rate
    header[24] = sampleRate & 0xff;
    header[25] = (sampleRate >> 8) & 0xff;
    header[26] = (sampleRate >> 16) & 0xff;
    header[27] = (sampleRate >> 24) & 0xff;
    // Byte rate (sampleRate * channels * bytesPerSample)
    final byteRate = sampleRate * 1 * 1;
    header[28] = byteRate & 0xff;
    header[29] = (byteRate >> 8) & 0xff;
    header[30] = (byteRate >> 16) & 0xff;
    header[31] = (byteRate >> 24) & 0xff;
    // Block align (channels * bytesPerSample)
    header[32] = 1; header[33] = 0;
    // Bits per sample (8 bits)
    header[34] = 8; header[35] = 0;
    // "data"
    header[36] = 0x64; header[37] = 0x61; header[38] = 0x74; header[39] = 0x61;
    // Subchunk2Size (data size)
    header[40] = numBytes & 0xff;
    header[41] = (numBytes >> 8) & 0xff;
    header[42] = (numBytes >> 16) & 0xff;
    header[43] = (numBytes >> 24) & 0xff;
    return header;
  }
}
