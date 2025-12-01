class BiometricReading {
  final int id;
  final DateTime timestamp;
  final double value;
  final String type; // 'hr', 'temp', 'o2'
  final String? activity; // optional user-provided activity label attached to this reading

  BiometricReading({required this.id, required this.timestamp, required this.value, required this.type, this.activity});

  Map<String, Object?> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'value': value,
        'type': type,
        'activity': activity,
      };

  factory BiometricReading.fromMap(Map<String, Object?> m) => BiometricReading(
        id: m['id'] as int,
        timestamp: DateTime.parse(m['timestamp'] as String),
        value: (m['value'] as num).toDouble(),
        type: m['type'] as String,
        activity: m.containsKey('activity') ? (m['activity'] as String?) : null,
      );
}
