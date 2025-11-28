import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_extract/Model/KebutuhanModel.dart';
import 'package:pdf_extract/Model/MasterKebutuhanModel.dart';

class CreateAndEditGeometries extends StatefulWidget {
  const CreateAndEditGeometries({super.key});

  @override
  State<CreateAndEditGeometries> createState() =>
      _CreateAndEditGeometriesState();
}


class _CreateAndEditGeometriesState extends State<CreateAndEditGeometries> {
  // Create a controller for the map view.
  final _mapViewController = ArcGISMapView.createController();
  // Create a graphics overlay.
  final _graphicsOverlay = GraphicsOverlay();
  // Create a geometry editor.
  final _geometryEditor = GeometryEditor();

  List<KebutuhanModel>? listKebutuhanModel = [];
  List<MasterKebutuhanModel>? listMasterKebutuhanModel = [];
  List<MasterKebutuhanModel>? listMasterKebutuhanKabelModel = [];

  // Create a list of geometry types to make available for editing.
  final _geometryTypes = [
    GeometryType.point,
    GeometryType.multipoint,
    GeometryType.polyline,
    GeometryType.polygon,
  ];

  // Create symbols which will be used for each geometry type.
  SimpleMarkerSymbol? _pointSymbol;
  SimpleMarkerSymbol? _multipointSymbol;
  SimpleLineSymbol? _polylineSymbol;
  late final SimpleFillSymbol _polygonSymbol;

  // Create a selection of tools to make available to the geometry editor.
  final _vertexTool = VertexTool();
  final _reticleVertexTool = ReticleVertexTool();
  final _freehandTool = FreehandTool();
  final _arrowShapeTool = ShapeTool(shapeType: ShapeToolType.arrow);
  final _ellipseShapeTool = ShapeTool(shapeType: ShapeToolType.ellipse);
  final _rectangleShapeTool = ShapeTool(shapeType: ShapeToolType.rectangle);
  final _triangleShapeTool = ShapeTool(shapeType: ShapeToolType.triangle);

  // Create variables for holding state relating to the geometry editor for controlling the UI.
  GeometryType? _selectedGeometryType;
  GeometryEditorTool? _selectedTool;
  Graphic? _selectedGraphic;
  Color? _selectedColorMultiPoint = Colors.yellow;
  var _selectedScaleMode = GeometryEditorScaleMode.stretch;
  var _geometryEditorCanUndo = false;
  var _geometryEditorCanRedo = false;
  var _geometryEditorIsStarted = false;
  var _geometryEditorHasSelectedElement = false;
  // A flag for controlling the visibility of the editing toolbar.
  var _showEditToolbar = true;

  MasterKebutuhanModel? masterKebutuhanModel;
  MasterKebutuhanModel? masterKebutuhanKabelModel;
  bool? isKebutuhan = true;
  bool? isKebutuhanKabel = false;

  List<PathsTrigger> paths = [];
  bool drawPoint = false, drawLine = false;
  TextEditingController searchController = TextEditingController();
  LocatorTask? locatorTask;
  SuggestResult? suggestResult;
  final _repaintKey = GlobalKey();

  List<SuggestResult> suggestPlace = [];
  bool isLoadingSuggest = false;

  Widget buildDropDownLocationSuggest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Search Place",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        Container(
          // padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownSearch<SuggestResult>(
              asyncItems: (String filter) async {
                return await suggestList(filter: filter);
              },
              itemAsString: (item) {
                return item.label;
              },
              selectedItem: suggestResult,
              popupProps: const PopupProps.menu(
                  fit: FlexFit.loose,
                  showSearchBox: true,
                  isFilterOnline: true),
              onChanged: (value) {
                geocodingSearch(filter: value!.label);
              },
            ),
          ),
        ),
      ],
    );
  }

  void initLocatorTask() async {
    locatorTask = LocatorTask.withUri(
      Uri.parse(
        'https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer',
      ),
    );
    locatorTask!.apiKey = 'AAPTxy8BH1VEsoebNVZXo8HurGg8GhcR-F3-iQtJ01J3YvK1uXuKS-Jciw4IGFMGw7EMUXz9jaixmnM896oOSBLzFl0pZ035BIgCZn3NKKlp8mYE-mS-rRerbYEJFmP-aSJBSshKecYMVLqyVNRdTFOr16PRAXJD5WLlBJIG3zVRlYCVORGQ7MJVtIHoXtmpKw1zGOMhMUEX-8pVVlSvQ4XW1ADrXWXiOURbLB1EH9W72p8.AT1_tSyrftwT';
  }

  void geocodingSearch({String? filter}) async {
    try {
      initLocatorTask();
      GeocodeParameters geocodeParameters = GeocodeParameters();
      var results = await locatorTask!.geocode(searchText: filter!);

      final result = results.firstOrNull;

      if (result != null) {
        final combinedString =
            'Found ${result.label} at ${result.displayLocation} with score ${result.score}';

        setState(() {
         _mapViewController.setViewpoint(
            Viewpoint.fromCenter(
              ArcGISPoint(
                x: result.displayLocation!.x,
                y: result.displayLocation!.y,
                spatialReference: result.displayLocation!.spatialReference,
              ),
              scale: 5000,
            ),
          );
        });
      }

    } catch (e) {
      dev.log("error ${e.toString()}");
    }
  }

  suggestList({String? filter}) async {
    try {
      initLocatorTask();
      dev.log("bye $filter");
      if(filter!.isEmpty) {
        return [];
      }
      suggestPlace = await locatorTask!.suggest(searchText: filter, parameters: SuggestParameters()..maxResults = 5);
      return suggestPlace;
    } catch (e) {
      dev.log("error ${e.toString()}");
    }
  }

  onInit() async {
    setState(() {
      listMasterKebutuhanModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "Tiang Beton", typeGeometry: GeometryType.multipoint, color: Colors.red)
      );
      listMasterKebutuhanModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "Tiang Besi", typeGeometry: GeometryType.multipoint, color: Colors.yellow)
      );
      listMasterKebutuhanModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "Konstruksi", typeGeometry: GeometryType.multipoint, color: Colors.blue)
      );
      listMasterKebutuhanModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "Trafo", typeGeometry: GeometryType.multipoint, color: Colors.black)
      );
      listMasterKebutuhanKabelModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "SUTR", typeGeometry: GeometryType.polyline, color: Colors.yellow)
      );
      listMasterKebutuhanKabelModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "JUTR", typeGeometry: GeometryType.polyline, color: Colors.red)
      );
    });
  }
  
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    onInit();
  }

  Future<void> _saveToFile() async {
    try {
      final path =
          '/storage/emulated/0/Download/hasil_garis_warna_${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = await _mapViewController.exportImage();
      final file = File(path);
      await file.writeAsBytes(bytes.getEncodedBuffer());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Gambar disimpan di: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menyimpan gambar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garis & Titik Warna Berbeda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToFile,
            tooltip: "Simpan ke PNG",
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  child: buildDropDownLocationSuggest()
                ),
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: ArcGISMapView(
                      controllerProvider: () => _mapViewController,
                      onMapViewReady: onMapViewReady,
                      // Only select existing graphics to edit if the geometry editor is not started
                      // i.e. editing is not already in progress.
                      onTap: !_geometryEditorIsStarted ? onTap : null,
                    ),
                  ),
                ),
                // Build the bottom menu.
                buildBottomMenu(),
                if(listKebutuhanModel!.isNotEmpty)
                ...listMasterKebutuhanKabelModel!.map((valueKabel) {
                  return Column(
                    children: [
                      const Divider(height: 10),
                      Text(valueKabel.namaKebutuhan!),
                      const Divider(height: 10),
                      ...listMasterKebutuhanModel!.map((valueKebutuhan) {
                        int total = listKebutuhanModel!.where((elementKebutuhan) {
                          return elementKebutuhan.jenisKabel == valueKabel.namaKebutuhan && elementKebutuhan.jenisKebutuhan == valueKebutuhan.namaKebutuhan;
                        }).length;
                        return Text("${valueKebutuhan.namaKebutuhan}: $total");
                      }),
                      const Divider(height: 10),
                    ],
                  );
                }),
              ],
            ),
            Visibility(
              visible: _showEditToolbar,
              // Build the editing toolbar.
              child: buildEditingToolbar(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onMapViewReady() async {
    // Create a map with an imagery basemap style.
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISImagery);
    // Set the map to the map view controller.
    _mapViewController.arcGISMap = map;
    // Add the graphics overlay to the map view.
    _mapViewController.graphicsOverlays.add(_graphicsOverlay);
    // Configure some initial graphics.
    _graphicsOverlay.graphics.addAll(initialGraphics());
    // Set an initial viewpoint over the graphics.
    _mapViewController.setViewpoint(
      Viewpoint.fromCenter(
        ArcGISPoint(
          x: -9.5920,
          y: 53.08230,
          spatialReference: SpatialReference(wkid: 4326),
        ),
        scale: 5000,
      ),
    );
    // Do some initial configuration of the geometry editor.
    // Initially set the created vertex tool as the current tool.
    setState(() => _selectedTool = _vertexTool);
    _geometryEditor.tool = _vertexTool;
    // Listen to changes in canUndo and canRedo in order to enable/disable the UI.
    _geometryEditor.onCanUndoChanged.listen(
      (canUndo) => setState(() => _geometryEditorCanUndo = canUndo),
    );
    _geometryEditor.onCanRedoChanged.listen(
      (canRedo) => setState(() => _geometryEditorCanRedo = canRedo),
    );
    // Listen to changes in isStarted in order to enable/disable the UI.
    _geometryEditor.onIsStartedChanged.listen(
      (isStarted) => setState(() => _geometryEditorIsStarted = isStarted),
    );
    // Listen to changes in the selected element in order to enable/disable the UI.
    _geometryEditor.onSelectedElementChanged.listen(
      (selectedElement) => setState(
        () => _geometryEditorHasSelectedElement = selectedElement != null,
      ),
    );
    // Set the geometry editor to the map view controller.
    _mapViewController.geometryEditor = _geometryEditor;
  }

  Future<void> onTap(Offset localPosition) async {
    // Perform an identify operation on the graphics overlay at the tapped location.
    final identifyResult = await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 12,
    );

    // Get the features from the identify result.
    final graphics = identifyResult.graphics;

    if (graphics.isNotEmpty) {
      final graphic = graphics.first;
      if (graphic.geometry != null) {
        final geometry = graphic.geometry!;
        Map<String, dynamic> trigger = geometry.toJson();
        dev.log("json ${trigger.toString()}");
        // Hide the selected graphic so that only the version of the graphic that is being edited is visible.
        graphic.isVisible = false;
        // Set the graphic as the selected graphic and also set the selected geometry type to update the UI.
        _selectedGraphic = graphic;
        setState(() => _selectedGeometryType = geometry.geometryType);
        // If a point or multipoint has been selected, we need to use a vertex tool - the UI also needs updating.
        if (geometry.geometryType == GeometryType.point ||
            geometry.geometryType == GeometryType.multipoint) {
          _geometryEditor.tool = _vertexTool;
          
          setState(() => _selectedTool = _vertexTool);
        }
        // Start the geometry editor using the geometry of the graphic.
        _geometryEditor.startWithGeometry(geometry);
      }
    }
  }

  void startEditingWithGeometryType(GeometryType geometryType) {
    // Set the selected geometry type.
    setState(() => _selectedGeometryType = geometryType);
    _geometryEditor.startWithGeometryType(geometryType);
  }

  void createLine() {
    Map<String, dynamic> json = {};
    List<List> points = [];
    for (var value in listKebutuhanModel!) {
      points.add([value.x, value.y]);
    }

    json['paths'] = [points];
    json['spatialReference'] = _mapViewController.spatialReference;

    final ggg = Geometry.fromJson(json);
    
    _polylineSymbol = SimpleLineSymbol(color: masterKebutuhanKabelModel!.color!, width: 2, style: SimpleLineSymbolStyle.dash);
    _graphicsOverlay.graphics.add(Graphic(geometry: ggg, symbol: _polylineSymbol));
  }

  double calculateDistance(double x1, double y1, double x2, double y2) {
    double x = x2 - x1;
    double y = y2 - y1;
    x = x * x;
    y = y * y;
    return sqrt(x+y);
  }

  bool isNear(KebutuhanModel kebutuhan, List paths) {
    bool isFind = false;
    for(int j = 0; j < paths.length; j++) {
      double sfrt = calculateDistance(kebutuhan.x!, kebutuhan.y!, paths[j][0], paths[j][1]);
      if(sfrt <= 10) {
        isFind = true;
        break;
      }
      dev.log("log : ${calculateDistance(kebutuhan.x!, kebutuhan.y!, paths[j][0], paths[j][1])}");
    }
    return isFind;
  }

  void stopAndSave() {
    dev.log("yanto");
    // Get the geometry from the geometry editor.
    final geometry = _geometryEditor.stop();
    Map<String, dynamic> jsonDecodeGeometry = jsonDecode(jsonEncode(geometry));

    dev.log("geometry ${jsonDecodeGeometry.toString()}");

    if (geometry != null) {
      if (_selectedGraphic != null) {
        // If there was a selected graphic being edited, update it.
        _selectedGraphic!.geometry = geometry;
        _selectedGraphic!.isVisible = true;
        // Reset the selected graphic to null.
        _selectedGraphic = null;
      } else {
        // If there was no existing graphic, create a new one and add to the graphics overlay.
        final graphic = Graphic(geometry: geometry);
        // Apply a symbol to the graphic depending on the geometry type.
        final geometryType = geometry.geometryType;
        if (geometryType == GeometryType.point) {
          graphic.symbol = _pointSymbol;
        } else if (geometryType == GeometryType.multipoint) {
          graphic.symbol = _multipointSymbol;
        } else if (geometryType == GeometryType.polyline) {
          graphic.symbol = _polylineSymbol;
        } else if (geometryType == GeometryType.polygon) {
          graphic.symbol = _polygonSymbol;
        }
        _graphicsOverlay.graphics.add(graphic);
      }

      setState(() {
        if(jsonDecodeGeometry['points'] != null && jsonDecodeGeometry['points'].length > 0) {
          for(int i = 0; i < jsonDecodeGeometry['points'].length; i++) {
            bool? isEmpty = true;
            if(listKebutuhanModel!.isNotEmpty) {
              List<KebutuhanModel> checkExisting = listKebutuhanModel!.where((value) {
                return value.x == jsonDecodeGeometry['points'][i][0] && value.y == jsonDecodeGeometry['points'][i][1];
              }).toList();
              if(checkExisting.isNotEmpty) {
                isEmpty = false;
              }
            }
            if(isEmpty) {
              listKebutuhanModel!.add(KebutuhanModel(
                jenisKebutuhan: masterKebutuhanModel!.namaKebutuhan,
                x: jsonDecodeGeometry['points'][i][0],
                y: jsonDecodeGeometry['points'][i][1],
                spatialReference: _mapViewController.spatialReference
              ));
            }
          }
          
          dev.log("deee");
        }
      });
    }
    
    setState(() {  
      if(drawLine) {
        for (var value in listKebutuhanModel!) {
          if(isNear(value, jsonDecodeGeometry['paths'][0])) {
            dev.log("near");
            value.jenisKabel ??= masterKebutuhanKabelModel!.namaKebutuhan;
          }
        }
      }
      masterKebutuhanModel = null;
      masterKebutuhanKabelModel = null;
    });

    dev.log("list_kebutuhan ${jsonEncode(listKebutuhanModel)}");

    // Reset the selected geometry type to null.
    setState(() => _selectedGeometryType = null);
  }

  void stopAndDiscardEdits() {
    // Stop the geometry editor. No need to capture the geometry as we are discarding.
    _geometryEditor.stop();
    if (_selectedGraphic != null) {
      // If editing a previously existing geometry, reset the selectedGraphic.
      _selectedGraphic!.isVisible = true;
      _selectedGraphic = null;
    }
    // Reset the selected geometry type.
    setState(() => _selectedGeometryType = null);
  }

  void toggleScale() {
    // Toggle the selected scale mode and then update each tool with the new value.
    setState(
      () => _selectedScaleMode =
          _selectedScaleMode == GeometryEditorScaleMode.uniform
          ? GeometryEditorScaleMode.stretch
          : GeometryEditorScaleMode.uniform,
    );
    _vertexTool.configuration.scaleMode = _selectedScaleMode;
    _freehandTool.configuration.scaleMode = _selectedScaleMode;
    _arrowShapeTool.configuration.scaleMode = _selectedScaleMode;
    _ellipseShapeTool.configuration.scaleMode = _selectedScaleMode;
    _rectangleShapeTool.configuration.scaleMode = _selectedScaleMode;
    _triangleShapeTool.configuration.scaleMode = _selectedScaleMode;
  }

  List<DropdownMenuItem<GeometryType>> configureGeometryTypeMenuItems() {
    // Returns a list of drop down menu items for each geometry type.
    return _geometryTypes.map((type) {
      // All geometry types can be created using a vertex or reticle vertex tool.
      // Only polyline and polygon geometry types can be created using freehand or shape tools.
      final isVertexTool =
          _selectedTool == _vertexTool || _selectedTool == _reticleVertexTool;
      if (type == GeometryType.point || type == GeometryType.multipoint) {
        return DropdownMenuItem(
          enabled: isVertexTool,
          value: type,
          child: Text(
            type.name.capitalize(),
            style: isVertexTool
                ? null
                : const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
          ),
        );
      } else {
        return DropdownMenuItem(
          value: type,
          child: Text(type.name.capitalize()),
        );
      }
    }).toList();
  }

  List<DropdownMenuItem<GeometryEditorTool>> configureToolMenuItems() {
    // A list of all tools with an identifying name to display in the UI.
    final tools = {
      _vertexTool: 'Vertex Tool',
      _reticleVertexTool: 'Reticle Vertex Tool',
      _freehandTool: 'Freehand Tool',
      _arrowShapeTool: 'Arrow Shape Tool',
      _ellipseShapeTool: 'Ellipse Shape Tool',
      _rectangleShapeTool: 'Rectangle Shape Tool',
      _triangleShapeTool: 'Triangle Shape Tool',
    };

    // Vertex and reticle vertex tools are compatible with all geometry types.
    // Freehand and shape tools are only compatible with polyline or polygon.
    // We also enable selection of freehand/shape tools when a geometry type has not yet been selected.
    final isNotPointOrMultipoint =
        _selectedGeometryType != GeometryType.point &&
        _selectedGeometryType != GeometryType.multipoint;

    return tools.keys.map((tool) {
      if (tool == _vertexTool || tool == _reticleVertexTool) {
        return DropdownMenuItem(
          value: tool,
          child: Text(tools[tool] ?? 'Unknown Tool'),
        );
      } else {
        return DropdownMenuItem(
          enabled: isNotPointOrMultipoint,
          value: tool,
          child: Text(
            tools[tool] ?? 'Unknown Tool',
            style: isNotPointOrMultipoint
                ? null
                : const TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
          ),
        );
      }
    }).toList();
  }

  Widget buildBottomMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // A drop down button for selecting geometry type.
        DropdownButton(
          alignment: Alignment.center,
          hint: Text(
            'Kebutuhan',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          icon: const Icon(Icons.arrow_drop_down),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          iconDisabledColor: Theme.of(context).disabledColor,
          style: Theme.of(context).textTheme.labelMedium,
          value: masterKebutuhanModel,
          items: listMasterKebutuhanModel!.map((value) {
            final isVertexTool = _selectedTool == _vertexTool || _selectedTool == _reticleVertexTool;
            if (value.typeGeometry == GeometryType.point || value.typeGeometry == GeometryType.multipoint) {
              return DropdownMenuItem(
                enabled: isVertexTool,
                value: value,
                child: Text(
                  value.namaKebutuhan!.capitalize(),
                  style: isVertexTool
                      ? null
                      : const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                ),
              );
            } else {
              return DropdownMenuItem(
                value: value,
                child: Text(value.namaKebutuhan!.capitalize()),
              );
            }
          }).toList(),
          onChanged: !_geometryEditorIsStarted
            ? (MasterKebutuhanModel? masterKebutuhan) {
                if (masterKebutuhan != null) {
                  setState(() {  
                    masterKebutuhanModel = masterKebutuhan;
                    _selectedColorMultiPoint = masterKebutuhan.color;
                    startEditingWithGeometryType(masterKebutuhanModel!.typeGeometry!);
                    if(masterKebutuhan.typeGeometry == GeometryType.multipoint) {
                      drawPoint = true;
                      drawLine = false;
                     _multipointSymbol = SimpleMarkerSymbol(
                        color: _selectedColorMultiPoint!,
                        size: 12
                      );
                    }
                  });
                }
              }
            : null,  
        ),

        DropdownButton(
          alignment: Alignment.center,
          hint: Text(
            'Kebutuhan Kabel',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          icon: const Icon(Icons.arrow_drop_down),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          iconDisabledColor: Theme.of(context).disabledColor,
          style: Theme.of(context).textTheme.labelMedium,
          value: masterKebutuhanKabelModel,
          items: listMasterKebutuhanKabelModel!.map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value.namaKebutuhan!.capitalize()),
            );
          }).toList(),
          onChanged: !_geometryEditorIsStarted
            ? (MasterKebutuhanModel? masterKebutuhan) {
                if (masterKebutuhan != null) {
                  startEditingWithGeometryType(masterKebutuhan.typeGeometry!);
                  setState(() {  
                    drawPoint = false;
                    drawLine = true;
                    masterKebutuhanKabelModel = masterKebutuhan;
                    _polylineSymbol = SimpleLineSymbol(color: masterKebutuhan.color!, width: 5, style: SimpleLineSymbolStyle.dash);
                  });
                }
              }
            : null,  
        ),

        // A drop down button for selecting a tool.
        // DropdownButton(
        //   alignment: Alignment.center,
        //   hint: Text('Tool', style: Theme.of(context).textTheme.labelMedium),
        //   iconEnabledColor: Theme.of(context).colorScheme.primary,
        //   style: Theme.of(context).textTheme.labelMedium,
        //   value: _selectedTool,
        //   items: configureToolMenuItems(),
        //   onChanged: (tool) {
        //     if (tool != null) {
        //       setState(() => _selectedTool = tool);
        //       _geometryEditor.tool = tool;
        //     }
        //   },
        // ),
        // // A button to toggle the visibility of the editing toolbar.
        // IconButton(
        //   onPressed: () => setState(() => _showEditToolbar = !_showEditToolbar),
        //   icon: const Icon(Icons.edit),
        // ),
      ],
    );
  }

  Widget buildEditingToolbar() {
    // A toolbar of buttons with icons for editing functions. Tooltips are used to aid the user experience.
    return Padding(
      padding: const EdgeInsets.only(bottom: 100, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  // A button to call undo on the geometry editor, if enabled.
                  Tooltip(
                    message: 'Undo',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted && _geometryEditorCanUndo
                          ? _geometryEditor.undo
                          : null,
                      child: const Icon(Icons.undo),
                    ),
                  ),
                  // A button to call redo on the geometry editor, if enabled.
                  Tooltip(
                    message: 'Redo',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted && _geometryEditorCanRedo
                          ? _geometryEditor.redo
                          : null,
                      child: const Icon(Icons.redo),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // A button to stop and save edits.
                  Tooltip(
                    message: 'Stop and save edits',
                    child: ElevatedButton(
                      onPressed: _geometryEditorIsStarted ? stopAndSave : null,
                      child: const Icon(Icons.save),
                    ),
                  ),
                  // A button to delete the selected element on the geometry editor.
                  Tooltip(
                    message: 'Delete selected element',
                    child: ElevatedButton(
                      onPressed:
                          _geometryEditorIsStarted &&
                              _geometryEditorHasSelectedElement &&
                              _geometryEditor.selectedElement != null &&
                              _geometryEditor.selectedElement!.canDelete
                          ? _geometryEditor.deleteSelectedElement
                          : null,
                      child: const Icon(Icons.clear),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // A button to stop the geometry editor and discard all edits.
                  Tooltip(
                    message: 'Stop and discard edits',
                    child: ElevatedButton(
                      onPressed: _geometryEditorIsStarted
                          ? stopAndDiscardEdits
                          : null,
                      child: const Icon(Icons.not_interested_sharp),
                    ),
                  ),
                  // A button to clear all graphics from the graphics overlay.
                  Tooltip(
                    message: 'Delete all graphics',
                    child: ElevatedButton(
                      onPressed: !_geometryEditorIsStarted
                          ? () {
                            setState(() {
                              _graphicsOverlay.graphics.clear();
                              listKebutuhanModel!.clear();
                              paths.clear();
                              masterKebutuhanKabelModel = null;
                              masterKebutuhanModel = null;
                            });
                          }
                          : null,
                      child: const Icon(Icons.delete_forever),
                    ),
                  ),
                ],
              ),
              // A button to toggle the scale mode setting of the geometry editor tools.
              ElevatedButton(
                // Scale mode is not compatible with point geometry types or the reticle vertex tool.
                onPressed:
                    _selectedGeometryType == GeometryType.point ||
                        _selectedTool == _reticleVertexTool
                    ? null
                    : toggleScale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      _selectedScaleMode == GeometryEditorScaleMode.uniform
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                    ),
                    const Text('Uniform\nScale'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Graphic> initialGraphics() {
    // Create symbols for each geometry type.
    _pointSymbol = SimpleMarkerSymbol(
      style: SimpleMarkerSymbolStyle.square,
      color: Colors.red,
      size: 10,
    );
    _multipointSymbol = SimpleMarkerSymbol(color: _selectedColorMultiPoint!, size: 10);
    _polylineSymbol = SimpleLineSymbol(color: Colors.blue, width: 2);
    final outlineSymbol = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.dash,
      color: Colors.black,
    );
    _polygonSymbol = SimpleFillSymbol(
      color: Colors.red,
      outline: outlineSymbol,
    );
    
    // Return a list of graphics for each geometry type.
    return [];
  }
}

extension on String {
  // An extension on String to capitalize the first character of the String.
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class PathsTrigger {
  double? x,y;
  Map<String, int>? spatialReference;

  PathsTrigger({
    required this.x,
    required this.y,
    required this.spatialReference
  });
}