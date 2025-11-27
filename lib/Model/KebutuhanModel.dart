import 'package:arcgis_maps/arcgis_maps.dart';

class KebutuhanModel {
  String? jenisKebutuhan;
  String? jenisKabel;
  bool? isExisting;
  GeometryType? typeGeometry;
  double? x,y;
  KebutuhanModel({
    this.jenisKebutuhan,
    this.jenisKabel,
    this.isExisting,
    this.typeGeometry,
    this.x,
    this.y
  });

  Map<String, dynamic> toJson() {
    return {
      'jenisKebutuhan': jenisKebutuhan
    };
  }
}