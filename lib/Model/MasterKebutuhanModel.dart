import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';

class MasterKebutuhanModel {
  String? namaKebutuhan;
  GeometryType? typeGeometry;
  Color? color;

  MasterKebutuhanModel({
    this.namaKebutuhan,
    this.typeGeometry,
    this.color
  });
}