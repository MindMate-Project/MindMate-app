import 'package:flutter/material.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';

class VideoTab extends StatelessWidget {
  final List<MemoryItem> items;

  const VideoTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No videos found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _VideoCard(item: item);
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final MemoryItem item;

  const _VideoCard({required this.item});

  /// Cloudinary serves a JPEG poster for any video by swapping the extension.
  /// Returns null for non-Cloudinary URLs so the caller falls back to the
  /// grey placeholder.
  static String? _posterUrl(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return null;
    if (!videoUrl.contains('res.cloudinary.com')) return null;
    return videoUrl.replaceAllMapped(
      RegExp(r'\.(mp4|mov|webm|avi|mkv|m4v)(\?.*)?$', caseSensitive: false),
      (m) => '.jpg${m.group(2) ?? ''}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final poster = _posterUrl(item.videoUrl);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/memory/drill',
          arguments: {'memoryId': item.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 160,
                width: double.infinity,
                color: const Color(0xFFE0E0E0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (poster != null)
                      Image.network(
                        poster,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox.shrink();
                        },
                      ),
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            if (item.date != null)
              Text(
                'Date: ${item.date}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
