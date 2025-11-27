import 'package:arcgis_maps/arcgis_maps.dart';

class KebutuhanModel {
  String? jenisKebutuhan;
  String? jenisKabel;
  bool? isExisting;
  GeometryType? typeGeometry;
  KebutuhanModel({
    this.jenisKebutuhan,
    this.jenisKabel,
    this.isExisting,
    this.typeGeometry
  });

  Map<String, dynamic> toJson() {
    return {
      'jenisKebutuhan': jenisKebutuhan
    };
  }
}