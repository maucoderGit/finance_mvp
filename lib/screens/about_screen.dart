import 'dart:convert';
import 'dart:io';

import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _avatarUrl = 'https://unavatar.io/x/Maucoder';
  static const _bioUrl =
      'https://cdn.syndication.twimg.com/widgets/followbutton/info.json?screen_names=Maucoder';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About Me',
          style: TextStyle(
            color: colors.primary,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _RetroBackground(
        colors: colors,
        dark: Theme.of(context).brightness == Brightness.dark,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AvatarBox(colors: colors),
                const SizedBox(height: 16),
                Text(
                  '✦ ✦ ✦',
                  style: TextStyle(
                    color: colors.primary,
                    letterSpacing: 6,
                  ),
                ),
                Text(
                  'MAUCODER',
                  style: TextStyle(
                    color: colors.textDark,
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  'Software dev \u2661 8-bit dreams',
                  style: TextStyle(
                    color: colors.primaryLight,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                _PixelBorder(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _BioBox(colors: colors),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SOCIAL LINKS \u2661',
                  style: TextStyle(
                    color: colors.primary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                _PixelLink(
                  icon: Icons.code,
                  label: 'github.com/maucodergit',
                  color: colors.primaryLight,
                  onTap: () async {
                    await _openUrl(
                        context, Uri.parse('https://github.com/maucodergit'));
                  },
                ),
                const SizedBox(height: 12),
                _PixelLink(
                  icon: Icons.alternate_email,
                  label: 'x.com/Maucoder',
                  color: colors.primary,
                  onTap: () async {
                    await _openUrl(
                        context, Uri.parse('https://x.com/Maucoder'));
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  '\\ (\u30c8) / thanks for playing!',
                  style: TextStyle(
                    color: colors.textLight,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Open a URL without crashing when no browser is reachable — on failure,
  /// surface the URL so the user can still use it.
  Future<void> _openUrl(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not open browser. URL: ${uri.toString()}')));
  }
}

class _PixelLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PixelLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.fieldsBackground,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '>',
              style: TextStyle(
                color: colors.textLight,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelBorder extends StatelessWidget {
  final Widget child;
  const _PixelBorder({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.stackCardBackground[1],
        border: Border.all(color: colors.primary, width: 3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

/// Retro 16-bit pixel-art background: blocky sun, scattered stars and layered
/// pixel hills, all tinted from the active palette.
class _RetroBackground extends StatelessWidget {
  final Palette colors;
  final bool dark;
  final Widget child;
  const _RetroBackground({
    required this.colors,
    required this.dark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _PixelBGPainter(colors, dark)),
        child,
      ],
    );
  }
}

class _PixelBGPainter extends CustomPainter {
  _PixelBGPainter(this.c, this.dark);
  final Palette c;
  final bool dark;
  static const _tile = 5.0;

  int _hash(int x, int y) => (x * 73856093 ^ y * 19349663) & 0xffff;

  @override
  void paint(Canvas cv, Size s) {
    final w = s.width, h = s.height;

    // Faint 8-bit dot matrix over the plain background so the area behind the
    // buttons never feels empty.
    final grid = Paint()..color = c.textLight.withValues(alpha: 0.18);
    for (var y = _tile; y < h; y += _tile * 4) {
      for (var x = _tile; x < w; x += _tile * 4) {
        cv.drawCircle(Offset(x, y), 1.0, grid);
      }
    }

    // Scattered stars. White in dark mode, dark in light mode, and never
    // painted where the centered content (card/links/footer) lives.
    final star = Paint()
      ..color = dark ? Colors.white : c.textDark.withValues(alpha: 0.45);
    final (clearA, clearB) = (w / 2 - 180.0, w / 2 + 180.0);
    for (var y = 60.0; y < h * 0.95; y += _tile * 3) {
      for (var x = 15.0; x < w; x += _tile * 3) {
        if (x > clearA && x < clearB) continue;

        if (_hash(x ~/ _tile, y ~/ _tile) % 13 == 0) {
          cv.drawRect(Rect.fromLTWH(x, y, _tile, _tile), star);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelBGPainter old) => old.c != c || old.dark != dark;
}

/// Retro pixel-framed box that shows the developer's real X/Twitter avatar.
class _AvatarBox extends StatelessWidget {
  final Palette colors;
  const _AvatarBox({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: colors.fieldsBackground,
            border: Border.all(color: colors.primary, width: 3),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            AboutScreen._avatarUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const SizedBox.shrink(),
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person_outline,
              color: colors.primary,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'x.com/MAUCODER',
          style: TextStyle(
            color: colors.textLight,
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

/// Fetches the developer's real X/Twitter bio; falls back to the static
/// blurb when the network fails.
class _BioBox extends StatefulWidget {
  final Palette colors;
  const _BioBox({required this.colors});

  @override
  State<_BioBox> createState() => _BioBoxState();
}

class _BioBoxState extends State<_BioBox> {
  static const _fallback =
      'hi~ i\u2019m maucoder. i like anime,\ncute things and programming. '
      'i build\nsmall flutter apps like this one \u2661';

  String? _bio;

  @override
  void initState() {
    super.initState();
    _fetchBio();
  }

  Future<void> _fetchBio() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(AboutScreen._bioUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      final data = jsonDecode(body) as List;
      final bio = (data.first['description'] as String?)?.trim();
      if (bio == null || bio.isEmpty) return;
      if (!mounted) return;
      setState(() => _bio = bio);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Text(
      _bio ?? _fallback,
      style: TextStyle(
        color: colors.textDark,
        fontFamily: 'monospace',
        height: 1.6,
      ),
    );
  }
}
