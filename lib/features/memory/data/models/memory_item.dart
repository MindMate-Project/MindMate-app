enum MemoryType { photo, video, text }

class MemoryItem {
  final String? id;
  final String title;
  final String? subtitle;
  final String? date;
  final String? imageUrl;
  final String? videoUrl;
  final String? description;
  final MemoryType type;

  const MemoryItem({
    this.id,
    required this.title,
    this.subtitle,
    this.date,
    this.imageUrl,
    this.videoUrl,
    this.description,
    required this.type,
  });

  /// Parse a memory type string from the API into the enum
  static MemoryType _parseType(String? typeStr) {
    switch (typeStr?.toLowerCase()) {
      case 'photo':
      case 'image':
        return MemoryType.photo;
      case 'video':
        return MemoryType.video;
      case 'text':
      case 'note':
        return MemoryType.text;
      default:
        return MemoryType.text;
    }
  }

  /// Create a MemoryItem from a JSON map returned by the API.
  ///
  /// Backend (MindMate-Project/Backend, src/models/MemoryItem.ts) stores the
  /// Cloudinary URL under `file_url` for both photo and video types — the
  /// distinction comes from the `type` field. We parse `type` first, then
  /// route the URL into the right slot so the existing PhotoTab / VideoTab
  /// widgets pick it up. The text body lives under `caption` on the backend
  /// (we keep `description` / `content` / `text` as fallbacks).
  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    final parsedType = _parseType(json['type'] ?? json['memoryType']);
    final fileUrl = (json['file_url'] ??
            json['imageUrl'] ??
            json['image'] ??
            json['photoUrl'] ??
            json['videoUrl'] ??
            json['video'])
        ?.toString();
    return MemoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title'] ?? json['name'] ?? 'Untitled',
      subtitle: json['subtitle'] ?? json['relation'],
      date: json['date'] ?? json['createdAt']?.toString().substring(0, 10),
      imageUrl: parsedType == MemoryType.photo ? fileUrl : null,
      videoUrl: parsedType == MemoryType.video ? fileUrl : null,
      description: json['description'] ??
          json['content'] ??
          json['caption'] ??
          json['text'],
      type: parsedType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (date != null) 'date': date,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (description != null) 'description': description,
      'type': type.name,
    };
  }
}
