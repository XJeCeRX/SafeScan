import '../models/obd_data.dart';

class ObdResponseParser {
  static List<int> extractBytes(String response) {
    final cleaned = response
        .toUpperCase()
        .replaceAll(RegExp(r'SEARCHING\.{0,3}'), ' ')
        .replaceAll(RegExp(r'NO DATA'), ' ')
        .replaceAll(RegExp(r'UNABLE TO CONNECT'), ' ')
        .replaceAll(RegExp(r'BUS INIT|BUS ERROR|CAN ERROR|DATA ERROR'), ' ')
        .replaceAll(RegExp(r'BUFFER FULL|STOPPED|OK'), ' ')
        .replaceAll(RegExp(r'ELM327[^\r\n]*'), ' ')
        .replaceAll('?', ' ');

    return RegExp(r'[0-9A-F]{2}')
        .allMatches(cleaned)
        .map((match) => int.parse(match.group(0)!, radix: 16))
        .toList();
  }

  static List<int>? pidPayload(String response, int pid) {
    final bytes = extractBytes(response);
    for (var i = 0; i < bytes.length - 1; i++) {
      if (bytes[i] == 0x41 && bytes[i + 1] == pid) {
        return bytes.sublist(i + 2);
      }
    }
    return null;
  }

  static int? singleBytePayload(String response, int pid) {
    final payload = pidPayload(response, pid);
    if (payload == null || payload.isEmpty) return null;
    return payload.first;
  }

  static (int, int)? twoBytePayload(String response, int pid) {
    final payload = pidPayload(response, pid);
    if (payload == null || payload.length < 2) return null;
    return (payload[0], payload[1]);
  }

  static int dtcCount(String response) {
    final payload = pidPayload(response, 0x01);
    if (payload == null || payload.isEmpty) return 0;
    return payload.first & 0x7F;
  }

  static List<DtcCode> dtcCodes(String response) {
    final bytes = extractBytes(response);
    final codesByValue = <String, DtcCode>{};

    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] != 0x43) continue;

      for (var j = i + 1; j + 1 < bytes.length; j += 2) {
        final byte1 = bytes[j];
        final byte2 = bytes[j + 1];
        if (byte1 == 0x00 && byte2 == 0x00) {
          break;
        }

        final code = DtcCode.fromRawBytes(byte1, byte2);
        codesByValue[code.code] = code;
      }
    }

    return codesByValue.values.toList();
  }

  static bool hasPositivePidResponse(String response, int pid) {
    return pidPayload(response, pid) != null;
  }

  static bool hasObdError(String response) {
    final normalized = response.toUpperCase();
    return normalized.contains('NO DATA') ||
        normalized.contains('UNABLE TO CONNECT') ||
        normalized.contains('BUS ERROR') ||
        normalized.contains('CAN ERROR') ||
        normalized.contains('DATA ERROR') ||
        normalized.contains('STOPPED') ||
        normalized.trim() == '?';
  }
}
