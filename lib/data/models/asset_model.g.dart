// // GENERATED CODE - DO NOT MODIFY BY HAND

// part of 'asset_model.dart';

// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************

// class AssetModelAdapter extends TypeAdapter<AssetModel> {
//   @override
//   final int typeId = 0;

//   @override
//   AssetModel read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//     return AssetModel(
//       id: fields[0] as String,
//       assetName: fields[1] as String,
//       category: fields[2] as String,
//       latitude: fields[3] as double,
//       longitude: fields[4] as double,
//       timestamp: fields[5] as DateTime,
//       status: fields[6] as String,
//       syncStatusStr: fields[7] as String,
//     );
//   }

//   @override
//   void write(BinaryWriter writer, AssetModel obj) {
//     writer
//       ..writeByte(8)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.assetName)
//       ..writeByte(2)
//       ..write(obj.category)
//       ..writeByte(3)
//       ..write(obj.latitude)
//       ..writeByte(4)
//       ..write(obj.longitude)
//       ..writeByte(5)
//       ..write(obj.timestamp)
//       ..writeByte(6)
//       ..write(obj.status)
//       ..writeByte(7)
//       ..write(obj.syncStatusStr);
//   }
// }