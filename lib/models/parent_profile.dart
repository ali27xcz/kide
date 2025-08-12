class ParentProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final List<String> childrenIds;
  final Map<String, dynamic> settings;
  
  ParentProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? childrenIds,
    Map<String, dynamic>? settings,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastLoginAt = lastLoginAt ?? DateTime.now(),
       childrenIds = childrenIds ?? [],
       settings = settings ?? {};
  
  // Copy with method for updating profile
  ParentProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? childrenIds,
    Map<String, dynamic>? settings,
  }) {
    return ParentProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      childrenIds: childrenIds ?? this.childrenIds,
      settings: settings ?? this.settings,
    );
  }
  
  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'childrenIds': childrenIds,
      'settings': settings,
    };
  }
  
  // Create from JSON
  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] ?? DateTime.now().toIso8601String()),
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }
  
  // Helper methods
  bool hasChildren() {
    return childrenIds.isNotEmpty;
  }
  
  void addChild(String childId) {
    if (!childrenIds.contains(childId)) {
      childrenIds.add(childId);
    }
  }
  
  void removeChild(String childId) {
    childrenIds.remove(childId);
  }
  
  bool getNotificationSettings(String type) {
    return settings['notifications']?[type] ?? true;
  }
  
  void setNotificationSettings(String type, bool enabled) {
    if (settings['notifications'] == null) {
      settings['notifications'] = {};
    }
    settings['notifications'][type] = enabled;
  }
  
  @override
  String toString() {
    return 'ParentProfile(id: $id, email: $email, name: $name, childrenCount: ${childrenIds.length})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParentProfile && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
