import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf_extract/CreateAndEditGeometries.dart';
import 'package:pdf_extract/Model/SnapGeometryEdits.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  ArcGISEnvironment.apiKey =
      'AAPTxy8BH1VEsoebNVZXo8HurGg8GhcR-F3-iQtJ01J3YvK1uXuKS-Jciw4IGFMGw7EMUXz9jaixmnM896oOSBLzFl0pZ035BIgCZn3NKKlp8mYE-mS-rRerbYEJFmP-aSJBSshKecYMVLqyVNRdTFOr16PRAXJD5WLlBJIG3zVRlYCVORGQ7MJVtIHoXtmpKw1zGOMhMUEX-8pVVlSvQ4XW1ADrXWXiOURbLB1EH9W72p8.AT1_tSyrftwT';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CreateAndEditGeometries(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? textExtract, judul, jumlahPelanggan, daya, lokasi;
  List<KebutuhanPdf> listKebutuhanSutr = [];
  List<KebutuhanPdf> listKebutuhanSutm = [];
  List<KebutuhanPdf> listKebutuhanGd = [];
  List<KebutuhanPdf> listKebutuhanSpApp = [];

  final GraphicsOverlay _graphicsOverlay = GraphicsOverlay();
  final List<Graphic> _markers = [];
  final List<Point> _routePoints = [];

  TextEditingController searchController = TextEditingController();
  ArcGISMapViewController arcGISMapViewController = ArcGISMapView.createController();
  ArcGISPoint arcGISPoint = ArcGISPoint(
    x: 112.76980810000001,
    y: -7.2763873999999999,
    spatialReference: SpatialReference.webMercator
  );

  double zoomMap = 100;

  final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);

  ArcGISPoint point = ArcGISPoint(
    x: 310.2593994140625,
    y: 107.029296875,
    spatialReference: SpatialReference.webMercator,
  );

  GraphicsOverlay graphicsOverlay = GraphicsOverlay();

  void geocodingSearch() async {
    try {
      final locatorTask = LocatorTask.withUri(
        Uri.parse(
          'https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer',
        ),
      );
      locatorTask.apiKey = 'AAPTxy8BH1VEsoebNVZXo8HurGg8GhcR-F3-iQtJ01J3YvK1uXuKS-Jciw4IGFMGw7EMUXz9jaixmnM896oOSBLzFl0pZ035BIgCZn3NKKlp8mYE-mS-rRerbYEJFmP-aSJBSshKecYMVLqyVNRdTFOr16PRAXJD5WLlBJIG3zVRlYCVORGQ7MJVtIHoXtmpKw1zGOMhMUEX-8pVVlSvQ4XW1ADrXWXiOURbLB1EH9W72p8.AT1_tSyrftwT';
      GeocodeParameters geocodeParameters = GeocodeParameters();
      var results = await locatorTask.geocode(searchText: searchController.text);

      final result = results.firstOrNull;

      if (result != null) {
        final combinedString =
            'Found ${result.label} at ${result.displayLocation} with score ${result.score}';

        setState(() {
          arcGISPoint = ArcGISPoint(x: result.displayLocation!.x, y: result.displayLocation!.y);
        });

        debugPrint(combinedString);
      }

    } catch (e) {
      dev.log("error ${e.toString()}");
    }
  }

  Future<void> _setExtent() async {
    // Create a new envelope builder using the same spatial reference as the graphics.
    final myEnvelopeBuilder = EnvelopeBuilder(
      spatialReference: SpatialReference.webMercator,
    );

    // Loop through each graphic in the graphic collection.
    for (final graphic in graphicsOverlay.graphics) {
      // Union the extent of each graphic in the envelope builder.
      myEnvelopeBuilder.unionWithEnvelope(graphic.geometry!.extent);
    }

    // Expand the envelope builder by 30%.
    myEnvelopeBuilder.expandBy(1.3);

    // Adjust the viewable area of the map to encompass all of the graphics in the
    // graphics overlay plus an extra 30% margin for better viewing.
    await arcGISMapViewController.setViewpointAnimated(
      Viewpoint.fromTargetExtent(myEnvelopeBuilder.extent),
    );
  }

  onTapMap(Offset position) async {
    final identifyResult = await arcGISMapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: position,
      tolerance: 12,
    );
    ArcGISPoint point = ArcGISPoint(
      x: position.dx,
      y: position.dy,
      spatialReference: SpatialReference.webMercator
    );
    var graphic = Graphic(
      geometry: point,
      symbol: SimpleMarkerSymbol(color: Colors.red, size: 10)
    );
    setState(() {
      graphicsOverlay.graphics.add(graphic);
    });
    _setExtent();
  }

  @override 
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onSubmitted: (value) {
                geocodingSearch();
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      zoomMap++;
                    });
                  },
                  child: Text("Zoom In"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      zoomMap--;
                    });
                  },
                  child: Text("Zoom Out"),
                )
              ],
            ),
          ),
          Expanded(
            child: ArcGISMapView(
            controllerProvider: () => arcGISMapViewController,
            onMapViewReady: () {
              map.initialViewpoint = Viewpoint.fromCenter(arcGISPoint, scale: zoomMap);
              arcGISMapViewController.arcGISMap = map;
              arcGISMapViewController.graphicsOverlays.add(graphicsOverlay);
            },
            onTap: (localPosition) {
              dev.log("localPosition ${localPosition.toString()}");
              dev.log({
                "dx": localPosition.dx,
                "dy": localPosition.dy,
              }.toString());
              onTapMap(localPosition);
            }),
          )
        ],
      ),
    );
  }
}

class KebutuhanPdf {
  String? namaKebutuhan, satuan;
  int? volume;

  KebutuhanPdf({this.namaKebutuhan, this.volume, this.satuan});
}

class MarkerMap {
  double? x,y;
  int? id;
  SpatialReference? spatialReference;

  MarkerMap({
    required this.x,
    required this.y,
    this.id,
    this.spatialReference
  });
}
