// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetectionHistoryAdapter extends TypeAdapter<DetectionHistory> {
  @override
  final int typeId = 0;

  @override
  DetectionHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectionHistory(
      id: fields[0] as String,
      imagePath: fields[1] as String,
      diseaseName: fields[2] as String,
      confidence: fields[3] as double,
      timestamp: fields[4] as DateTime,
      diseaseDetails: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DetectionHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.diseaseName)
      ..writeByte(3)
      ..write(obj.confidence)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.diseaseDetails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectionHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
