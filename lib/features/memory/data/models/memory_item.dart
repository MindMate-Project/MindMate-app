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

  /// Create a MemoryItem from a JSON map returned by the API
  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title'] ?? json['name'] ?? 'Untitled',
      subtitle: json['subtitle'] ?? json['relation'],
      date: json['date'] ?? json['createdAt']?.toString().substring(0, 10),
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['photoUrl'],
      videoUrl: json['videoUrl'] ?? json['video'],
      description: json['description'] ?? json['content'] ?? json['text'],
      type: _parseType(json['type'] ?? json['memoryType']),
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
