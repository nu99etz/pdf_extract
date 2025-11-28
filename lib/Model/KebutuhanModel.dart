import 'package:arcgis_maps/arcgis_maps.dart';

class KebutuhanModel {
  String? jenisKebutuhan;
  String? jenisKabel;
  bool? isExisting;
  GeometryType? typeGeometry;
  double? x,y;
  SpatialReference? spatialReference;
  KebutuhanModel({
    this.jenisKebutuhan,
    this.jenisKabel,
    this.isExisting,
    this.typeGeometry,
    this.x,
    this.y,
    this.spatialReference
  });

  Map<String, dynamic> toJson() {
    return {
      'jenisKebutuhan': jenisKebutuhan,
      'jenisKabel': jenisKabel ?? "-"
    };
  }
}