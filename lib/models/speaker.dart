import 'package:hive/hive.dart';

part 'speaker.g.dart';

/// Data model representing a speaker identified in a transcription
@HiveType(typeId: 10)
class Speaker {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final String? color;

  Speaker({
    required this.label,
    this.color,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'color': color,
      };

  factory Speaker.fromJson(Map<String, dynamic> json) => Speaker(
        label: json['label'] as String,
        color: json['color'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Speaker &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}
