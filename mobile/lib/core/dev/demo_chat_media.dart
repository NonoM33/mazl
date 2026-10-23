import 'dart:convert';
import 'dart:typed_data';

/// Média déposé dans une conversation de démo. Les octets restent en mémoire ;
/// l'`url` servie est une URI `data:` (docs/chat/CONTRAT.md §4bis).
class DemoChatMedia {
  DemoChatMedia({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.mime,
    required this.bytes,
    required this.createdAt,
    this.width,
    this.height,
    this.durationMs,
    this.waveform,
  });

  final int id;
  final int conversationId;

  /// `photo` ou `voice`.
  final String kind;
  final String mime;
  final Uint8List bytes;
  final DateTime createdAt;
  final int? width;
  final int? height;
  final int? durationMs;
  final List<int>? waveform;

  /// Message qui utilise ce média ; `null` tant qu'il est orphelin.
  int? attachedTo;

  late final String url = 'data:$mime;base64,${base64Encode(bytes)}';

  bool get isPhoto => kind == 'photo';

  /// Orphelin depuis plus de 24 h : le serveur l'a purgé.
  bool isPurged(DateTime now) =>
      attachedTo == null &&
      now.difference(createdAt) > const Duration(hours: 24);

  Map<String, dynamic> toJson() => isPhoto
      ? {'id': id, 'kind': kind, 'url': url, 'width': width, 'height': height}
      : {
          'id': id,
          'kind': kind,
          'url': url,
          'duration_ms': durationMs,
          'waveform': waveform,
        };
}

/// Ce que les octets d'une photo disent d'elle-même, jamais son extension.
class SniffedImage {
  const SniffedImage(this.mime, {this.width, this.height});

  final String mime;
  final int? width;
  final int? height;
}

abstract final class DemoChatMediaSniffer {
  static const _heicBrands = {
    'heic',
    'heix',
    'hevc',
    'hevx',
    'heim',
    'heis',
    'mif1',
    'msf1',
  };

  static String? _brand(Uint8List b) {
    if (b.length < 12) return null;
    if (String.fromCharCodes(b.sublist(4, 8)) != 'ftyp') return null;
    return String.fromCharCodes(b.sublist(8, 12));
  }

  /// JPEG, PNG ou HEIC reconnus à leurs octets ; `null` sinon. Les dimensions
  /// sont lues quand l'en-tête les donne (JPEG, PNG).
  static SniffedImage? image(Uint8List b) {
    if (b.length >= 24 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[4] == 0x0D &&
        b[5] == 0x0A &&
        b[6] == 0x1A &&
        b[7] == 0x0A) {
      final data = ByteData.sublistView(b);
      return SniffedImage(
        'image/png',
        width: data.getUint32(16),
        height: data.getUint32(20),
      );
    }
    if (b.length >= 4 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return _jpeg(b);
    }
    final brand = _brand(b);
    if (brand != null && _heicBrands.contains(brand)) {
      return const SniffedImage('image/heic');
    }
    return null;
  }

  static SniffedImage _jpeg(Uint8List b) {
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xFF) {
        i++;
        continue;
      }
      final marker = b[i + 1];
      if (marker == 0xFF) {
        i++;
        continue;
      }
      if (marker == 0xD8 ||
          (marker >= 0xD0 && marker <= 0xD7) ||
          marker == 0x01) {
        i += 2;
        continue;
      }
      final length = (b[i + 2] << 8) | b[i + 3];
      final isFrame =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isFrame) {
        return SniffedImage(
          'image/jpeg',
          height: (b[i + 5] << 8) | b[i + 6],
          width: (b[i + 7] << 8) | b[i + 8],
        );
      }
      i += 2 + length;
    }
    return const SniffedImage('image/jpeg');
  }

  /// Conteneur MP4/M4A (`ftyp`) : le seul format de vocal accepté.
  static bool isM4a(Uint8List b) {
    final brand = _brand(b);
    return brand != null && !_heicBrands.contains(brand);
  }
}
