import 'dart:io';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';

/// Circular avatar with NetworkImage and initials fallback.
///
/// `photoUrl` may be an https URL (sample avatars, Supabase storage) or a
/// local file path (a photo just picked on signup in demo mode) — the latter
/// must use FileImage, not NetworkImage, or it renders as a blank circle.
class HopAvatar extends StatelessWidget {
  const HopAvatar(
      {super.key, required this.photoUrl, required this.name, this.radius = 24});

  final String photoUrl;
  final String name;
  final double radius;

  /// True for a local file path such as `/storage/.../image.jpg` or a
  /// `file://` URI, as returned by image_picker.
  static bool isLocalPath(String value) =>
      value.startsWith('/') || value.startsWith('file://');

  ImageProvider? get _image {
    if (photoUrl.isEmpty) return null;
    if (isLocalPath(photoUrl)) {
      final path = photoUrl.startsWith('file://')
          ? Uri.parse(photoUrl).toFilePath()
          : photoUrl;
      final file = File(path);
      if (!file.existsSync()) return null;
      return FileImage(file);
    }
    return NetworkImage(photoUrl);
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return CircleAvatar(
      radius: radius,
      backgroundColor: HopColors.sageSoft,
      backgroundImage: image,
      onBackgroundImageError: image != null ? (_, __) {} : null,
      child: image == null
          ? Text(_initials,
              style: TextStyle(
                  color: HopColors.sage,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.7))
          : null,
    );
  }
}

/// Dashed vertical line painter used for the From → To journey graphic.
class DottedLinePainter extends CustomPainter {
  DottedLinePainter({this.color = HopColors.sage, this.vertical = true});

  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 5.0;
    if (vertical) {
      var y = 0.0;
      while (y < size.height) {
        canvas.drawLine(Offset(size.width / 2, y),
            Offset(size.width / 2, (y + dash).clamp(0, size.height)), paint);
        y += dash + gap;
      }
    } else {
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, size.height / 2),
            Offset((x + dash).clamp(0, size.width), size.height / 2), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DottedLinePainter old) =>
      old.color != color || old.vertical != vertical;
}

/// From → To journey graphic: two dots joined by a dotted line, no map.
class JourneyGraphic extends StatelessWidget {
  const JourneyGraphic(
      {super.key, required this.from, required this.to, this.compact = false});

  final String from;
  final String to;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: HopColors.sage, shape: BoxShape.circle),
            ),
            SizedBox(
              height: compact ? 18 : 26,
              width: 12,
              child: CustomPaint(painter: DottedLinePainter()),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: HopColors.peachDeep,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: compact ? 18 : 26),
              Text(to,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

/// Status chip: Available / Filling Fast / Full.
class RideStatusChip extends StatelessWidget {
  const RideStatusChip({super.key, required this.status});

  final RideStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String label;
    switch (status) {
      case RideStatus.available:
        bg = HopColors.sageSoft;
        fg = HopColors.sage;
        label = 'Available';
      case RideStatus.fillingFast:
        bg = const Color(0xFFFDF3D7);
        fg = HopColors.amber;
        label = 'Filling Fast';
      case RideStatus.full:
        bg = const Color(0xFFEEEAE4);
        fg = HopColors.inkSoft;
        label = 'Full';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

/// Simple success animation: a sage circle with a drawing check mark.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({super.key, this.size = 84});

  final double size;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    _check = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _c, curve: const Interval(0.35, 1)));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _check,
          builder: (context, _) => CustomPaint(
            painter: _CheckPainter(_check.value),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Paint()..color = HopColors.sage;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, circle);
    final check = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final p1 = Offset(size.width * 0.28, size.height * 0.54);
    final p2 = Offset(size.width * 0.45, size.height * 0.70);
    final p3 = Offset(size.width * 0.74, size.height * 0.32);
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);
    final metrics = path.computeMetrics().first;
    final extract = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extract, check);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) =>
      old.progress != progress;
}

/// Friendly empty state.
class HopEmptyState extends StatelessWidget {
  const HopEmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                  color: HopColors.peachSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: HopColors.peachDeep),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with a retry button.
class HopErrorState extends StatelessWidget {
  const HopErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 40, color: HopColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small section heading used across screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 17)),
        ),
        if (action != null) action!,
      ],
    );
  }
}
