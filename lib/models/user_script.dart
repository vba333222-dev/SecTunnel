class UserScript {
  final String id;
  final String profileId;
  final String name;
  final String urlPattern;
  final String jsPayload;
  final bool isActive;
  final String runAt; // 'document_start' or 'document_idle'
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserScript({
    required this.id,
    required this.profileId,
    required this.name,
    required this.urlPattern,
    required this.jsPayload,
    this.isActive = true,
    this.runAt = 'document_idle',
    required this.createdAt,
    required this.updatedAt,
  });

  UserScript copyWith({
    String? id,
    String? profileId,
    String? name,
    String? urlPattern,
    String? jsPayload,
    bool? isActive,
    String? runAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserScript(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      urlPattern: urlPattern ?? this.urlPattern,
      jsPayload: jsPayload ?? this.jsPayload,
      isActive: isActive ?? this.isActive,
      runAt: runAt ?? this.runAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
