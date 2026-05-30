class CycleEntry {
  final String? id;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLength;
  final int? periodLength;
  final String? notes;
  final List<String> symptoms;
  final String? mood;
  final DateTime createdAt;

  CycleEntry({
    this.id,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.cycleLength,
    this.periodLength,
    this.notes,
    this.symptoms = const [],
    this.mood,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CycleEntry.fromMap(Map<String, dynamic> map) {
    return CycleEntry(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      cycleLength: map['cycle_length'],
      periodLength: map['period_length'],
      notes: map['notes'],
      symptoms: map['symptoms'] != null
          ? List<String>.from(map['symptoms'])
          : [],
      mood: map['mood'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'notes': notes,
      'symptoms': symptoms,
      'mood': mood,
    };
  }

  CycleEntry copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLength,
    int? periodLength,
    String? notes,
    List<String>? symptoms,
    String? mood,
  }) {
    return CycleEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      notes: notes ?? this.notes,
      symptoms: symptoms ?? this.symptoms,
      mood: mood ?? this.mood,
      createdAt: createdAt,
    );
  }
}
