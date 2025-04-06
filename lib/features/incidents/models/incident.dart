class Incident {
  final int id;
  final String title;
  final String description;
  final String? photoPath;
  final String? photoUrl;
  final String? voiceNotePath;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String status;
  final String incidentType;
  final String syncStatus;
  final int userId;

  Incident({
    required this.id,
    required this.title,
    required this.description,
    this.photoPath,
    this.photoUrl,
    this.voiceNotePath,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.status = 'pending',
    this.incidentType = 'general',
    required this.syncStatus,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'photo_path': photoPath,
      'voice_note_path': voiceNotePath,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'incident_type': incidentType,
      'sync_status': syncStatus,
      'user_id': userId,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      photoPath: map['photo_path'] as String?,
      photoUrl: map['photo_url'] as String?,
      voiceNotePath: map['voice_note_path'] as String?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: map['status'] ?? 'pending',
      incidentType: map['incident_type'] ?? 'general',
      syncStatus: map['sync_status'] as String,
      userId: map['user_id'] as int,
    );
  }
}
