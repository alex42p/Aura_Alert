class BiometricReading {
  final int id;
  final DateTime timestamp;
  final double value;
  final String type; // 'hr', 'temp', 'o2'

  BiometricReading({required this.id, required this.timestamp, required this.value, required this.type});

  Map<String, Object?> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'value': value,
        'type': type,
      };

  factory BiometricReading.fromMap(Map<String, Object?> m) => BiometricReading(
        id: m['id'] as int,
        timestamp: DateTime.parse(m['timestamp'] as String),
        value: (m['value'] as num).toDouble(),
        type: m['type'] as String,
      );
}
