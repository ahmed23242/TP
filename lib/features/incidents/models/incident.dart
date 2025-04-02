class Incident {
  final int? id;
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
    this.id,
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
    this.syncStatus = 'pending',
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'photo_path': photoPath,
      'photo_url': photoUrl,
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
      id: map['id'],
      title: map['title'],
      description: map['description'],
      photoPath: map['photo_path'],
      photoUrl: map['photo_url'],
      voiceNotePath: map['voice_note_path'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      createdAt: DateTime.parse(map['created_at']),
      status: map['status'] ?? 'pending',
      incidentType: map['incident_type'] ?? 'general',
      syncStatus: map['sync_status'] ?? 'pending',
      userId: map['user_id'],
    );
  }
}
