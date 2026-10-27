import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The line drawing of a campaign (`assets/storefront/glyphs/<glyph>.svg`,
/// 24 x 24, `currentColor`), tinted [color]. When the file is not in the
/// bundle or cannot be read, a plain sparkle stands in: the page never breaks
/// over a drawing.
class CampaignGlyph extends StatefulWidget {
  const CampaignGlyph({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 32,
    this.bundle,
  });

  final String glyph;
  final Color color;
  final double size;

  /// Where the drawing is read; the app's by default.
  final AssetBundle? bundle;

  static String assetPath(String glyph) =>
      'assets/storefront/glyphs/$glyph.svg';

  @override
  State<CampaignGlyph> createState() => _CampaignGlyphState();
}

class _CampaignGlyphState extends State<CampaignGlyph> {
  Future<String?>? _drawing;
  AssetBundle? _loadedFrom;
  String? _loadedGlyph;

  Future<String?> _load(AssetBundle bundle, String glyph) async {
    try {
      final svg = await bundle.loadString(CampaignGlyph.assetPath(glyph));
      return svg.contains('<svg') ? svg : null;
    } on FlutterError catch (error) {
      debugPrint('Campaign glyph $glyph: ${error.message}');
      return null;
    } on Exception catch (error) {
      debugPrint('Campaign glyph $glyph: $error');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = widget.bundle ?? DefaultAssetBundle.of(context);
    if (_drawing == null ||
        _loadedFrom != bundle ||
        _loadedGlyph != widget.glyph) {
      _loadedFrom = bundle;
      _loadedGlyph = widget.glyph;
      _drawing = _load(bundle, widget.glyph);
    }
    final fallback = Icon(
      LucideIcons.sparkles,
      size: widget.size,
      color: widget.color,
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: FutureBuilder<String?>(
          future: _drawing,
          builder: (context, snapshot) {
            final svg = snapshot.data;
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            if (svg == null) return fallback;
            return SvgPicture.string(
              svg,
              width: widget.size,
              height: widget.size,
              colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
            );
          },
        ),
      ),
    );
  }
}
