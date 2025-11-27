import 'dart:convert';
import 'dart:developer';

import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
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

  // Create a list of geometry types to make available for editing.
  final _geometryTypes = [
    GeometryType.point,
    GeometryType.multipoint,
    GeometryType.polyline,
    GeometryType.polygon,
  ];

  // Create symbols which will be used for each geometry type.
  late final SimpleMarkerSymbol _pointSymbol;
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
      listMasterKebutuhanModel!.add(
        MasterKebutuhanModel(namaKebutuhan: "SUTR", typeGeometry: GeometryType.polyline, color: Colors.yellow)
      );
      listMasterKebutuhanModel!.add(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  // Add a map view to the widget tree and set a controller.
                  child: ArcGISMapView(
                    controllerProvider: () => _mapViewController,
                    onMapViewReady: onMapViewReady,
                    // Only select existing graphics to edit if the geometry editor is not started
                    // i.e. editing is not already in progress.
                    onTap: !_geometryEditorIsStarted ? onTap : null,
                  ),
                ),
                // Build the bottom menu.
                buildBottomMenu(),
                ...listKebutuhanModel!.map((value) {
                  return Container(
                    child: Text(value.jenisKebutuhan.toString()),
                  );
                })
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
    log("onTap");
    for (var value in listKebutuhanModel!) {
      log("value ${value.jenisKebutuhan}");
    }
    // Perform an identify operation on the graphics overlay at the tapped location.
    final identifyResult = await _mapViewController.identifyGraphicsOverlay(
      _graphicsOverlay,
      screenPoint: localPosition,
      tolerance: 12,
    );

    // Get the features from the identify result.
    final graphics = identifyResult.graphics;

    log("gar ${graphics.first.geometry.toString()}");

    if (graphics.isNotEmpty) {
      final graphic = graphics.first;
      if (graphic.geometry != null) {
        final geometry = graphic.geometry!;
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
    // setState(() {
    //   listKebutuhanModel!.add(KebutuhanModel(
    //     jenisKebutuhan: masterKebutuhanModel!.namaKebutuhan
    //   ));
    // });
    // for (var value in listKebutuhanModel!) {
    //   log("value ${value.jenisKebutuhan}");
    // }
  }

  void stopAndSave() {
    log("yanto");
    // Get the geometry from the geometry editor.
    final geometry = _geometryEditor.stop();
    Map<String, dynamic> jsonDecodeGeometry = jsonDecode(jsonEncode(geometry));
    log("point geometry : ${jsonDecodeGeometry['points'].toString()}");

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
            listKebutuhanModel!.add(KebutuhanModel(
              jenisKebutuhan: masterKebutuhanModel!.namaKebutuhan
            ));
          }
        }
      });
    }

    log("listKebutuhanModel ${jsonEncode(listKebutuhanModel)}");

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
            'Geometry Type',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          icon: const Icon(Icons.arrow_drop_down),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          iconDisabledColor: Theme.of(context).disabledColor,
          style: Theme.of(context).textTheme.labelMedium,
          value: masterKebutuhanModel,
          // items: configureGeometryTypeMenuItems(),
          // // If the geometry editor is already started then we fully disable the DropDownButton and prevent editing with another geometry type.
          // onChanged: !_geometryEditorIsStarted
          //     ? (GeometryType? geometryType) {
          //         if (geometryType != null) {
          //           startEditingWithGeometryType(geometryType);
          //         }
          //       }
          //     : null,
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
                  startEditingWithGeometryType(masterKebutuhan.typeGeometry!);
                  setState(() {  
                    masterKebutuhanModel = masterKebutuhan;
                    _selectedColorMultiPoint = masterKebutuhan.color;
                    if(masterKebutuhan.typeGeometry == GeometryType.multipoint) {
                      _multipointSymbol = SimpleMarkerSymbol(color: _selectedColorMultiPoint!, size: 10);
                    }

                    if(masterKebutuhan.typeGeometry == GeometryType.polyline) {
                       _polylineSymbol = SimpleLineSymbol(color: _selectedColorMultiPoint!, width: 2);
                    }
                  });
                }
              }
            : null,  
        ),
        // A drop down button for selecting a tool.
        DropdownButton(
          alignment: Alignment.center,
          hint: Text('Tool', style: Theme.of(context).textTheme.labelMedium),
          iconEnabledColor: Theme.of(context).colorScheme.primary,
          style: Theme.of(context).textTheme.labelMedium,
          value: _selectedTool,
          items: configureToolMenuItems(),
          onChanged: (tool) {
            if (tool != null) {
              setState(() => _selectedTool = tool);
              _geometryEditor.tool = tool;
            }
          },
        ),
        // A button to toggle the visibility of the editing toolbar.
        IconButton(
          onPressed: () => setState(() => _showEditToolbar = !_showEditToolbar),
          icon: const Icon(Icons.edit),
        ),
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