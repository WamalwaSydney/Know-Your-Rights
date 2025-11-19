// lib/core/models/legal_resource.dart

class LegalResource {
  final String title;
  final String description;
  final String type; // Template, Definition, Guide
  final String? url; // external URL or template key (e.g., 'dynamic:nda')
  final String? content; // template text for templates

  LegalResource({
    required this.title,
    required this.description,
    required this.type,
    this.url,
    this.content,
  });

  // Check if this is a dynamic template
  bool get isDynamicTemplate => url?.startsWith('dynamic:') ?? false;

  // Get the template key (e.g., 'nda' from 'dynamic:nda')
  String? get templateKey =>
      isDynamicTemplate ? url?.substring('dynamic:'.length) : null;

  // Factory constructor from JSON
  factory LegalResource.fromJson(Map<String, dynamic> json) {
    return LegalResource(
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      url: json['url'] as String?,
      content: json['content'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'content': content,
    };
  }

  // Copy with method for updating properties
  LegalResource copyWith({
    String? title,
    String? description,
    String? type,
    String? url,
    String? content,
  }) {
    return LegalResource(
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      url: url ?? this.url,
      content: content ?? this.content,
    );
  }
}