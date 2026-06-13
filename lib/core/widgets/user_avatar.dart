import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

/// Circular user avatar that shows the profile photo when one is available and
/// gracefully falls back to the name's initial, then a person icon.
///
/// A broken or unreachable [photoUrl] also falls back to the initial/icon
/// (via [CircleAvatar.onForegroundImageError]) instead of showing a broken
/// image, so it's safe to pass whatever the backend returns.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double radius;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    final fallback = _fallback();

    if (url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: fallback,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      foregroundImage: CachedNetworkImageProvider(url),
      onForegroundImageError: (_, _) {},
      child: fallback,
    );
  }

  Widget _fallback() {
    final n = name?.trim() ?? '';
    if (n.isEmpty) {
      return Icon(Icons.person, size: radius, color: AppTheme.neutralMedium);
    }
    return Text(
      n[0].toUpperCase(),
      style: TextStyle(
        fontSize: radius * 0.8,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
      ),
    );
  }
}
