import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:developer' as dev;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GarisTitikWarnaPage(),
    );
  }
}

class GarisTitikWarnaPage extends StatefulWidget {
  const GarisTitikWarnaPage({super.key});

  @override
  State<GarisTitikWarnaPage> createState() => _GarisTitikWarnaPageState();
}

class _GarisTitikWarnaPageState extends State<GarisTitikWarnaPage> {
  final List<Offset> points = [];
  final Map<int, String> labels = {};
  final Map<int, Color> pointColors = {};
  final Map<int, Color> lineColors = {};
  final Map<int, String> existingLine = {};
  int? selectedIndex;
  int? selectedTrafoIndex;
  File? _imageFile;
  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _repaintKey = GlobalKey();
  int? tempSelectedForLine;
  int? selectedLineTemp;
  int? selectedLineId;
  bool? isSelectedLine = false, isSelectedPoint = false;

  final Random _rand = Random();

  List<KebutuhanMaterial> listKebutuhanMaterial = [];
  List<KebutuhanGaris> listKebutuhanGaris = [];
  List<String> listExisting = [];
  List<PointsModel> listPoints = [];
  List<PointsModel> listTrafo = [];
  List<LineModel> listLine = [];

  Color? selectedColor;
  KebutuhanMaterial? selectedKebutuhanMaterial;
  KebutuhanGaris? selectedKebutuhanGaris;
  String? selectedExisting;
  String? selectedKebutuhan, selectedGaris, selectedIsExisting;

  @override
  void initState() {
    // TODO: implement initState
    listKebutuhanMaterial.add(KebutuhanMaterial(
        idKebutuhan: 1, color: Colors.yellow, title: "Tiang Beton"));
    listKebutuhanMaterial.add(KebutuhanMaterial(
        idKebutuhan: 2, color: Colors.red, title: "Tiang Besi"));
    listKebutuhanMaterial.add(KebutuhanMaterial(
        idKebutuhan: 3, color: Colors.blue, title: "Konstruksi"));
    listKebutuhanMaterial.add(
        KebutuhanMaterial(idKebutuhan: 4, color: Colors.red, title: "Trafo"));
    listKebutuhanGaris.add(KebutuhanGaris(color: Colors.yellow, title: "sutr"));
    listKebutuhanGaris.add(KebutuhanGaris(color: Colors.red, title: "sutm"));
    listExisting.add("existing");
    listExisting.add("non-existing");
    super.initState();
  }

  Color _randomColor() {
    return HSLColor.fromAHSL(
      1.0,
      _rand.nextDouble() * 360,
      0.6,
      0.6,
    ).toColor();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        listPoints.clear();
        listTrafo.clear();
        selectedIndex = null;
      });
    }
  }

  // 💾 Simpan hasil ke file PNG
  Future<void> _saveToFile() async {
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '/storage/emulated/0/Download/hasil_garis_warna_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Gambar disimpan di: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menyimpan gambar: $e')),
      );
    }
  }

  // ➕ Tambah titik baru
  void _addPoint(Offset pos) {
    setState(() {
      selectedIndex = null;
      selectedTrafoIndex = null;
      isSelectedLine = false;
      isSelectedPoint = true;
      int id = DateTime.now().millisecondsSinceEpoch;
      if (selectedKebutuhanMaterial!.title != 'Trafo') {
        listPoints.add(PointsModel(
            id: id,
            title: selectedKebutuhanMaterial!.title,
            type: selectedKebutuhanMaterial!.title != 'Trafo'
                ? selectedKebutuhanGaris!.title
                : null,
            isExisting: selectedExisting == 'existing' ? true : false,
            dotColor: selectedKebutuhanMaterial != null
                ? selectedKebutuhanMaterial!.color!
                : Colors.blue,
            lineColor: selectedKebutuhanGaris != null &&
                    selectedKebutuhanMaterial!.title != 'Trafo'
                ? selectedKebutuhanGaris!.color!
                : null,
            point: pos));
        selectedIndex = id;
        _controller.text = listPoints
            .firstWhere((element) => element.id == selectedIndex)
            .title!;
      } else {
        listTrafo.add(PointsModel(
            id: id,
            title: selectedKebutuhanMaterial!.title,
            type: 'trafo',
            isExisting: selectedExisting == 'existing' ? true : false,
            dotColor: selectedKebutuhanMaterial!.color,
            point: pos));
        selectedTrafoIndex = id;
        _controller.text = listTrafo
            .firstWhere((element) => element.id == selectedTrafoIndex)
            .title!;
      }
    });
  }

  void _selectPoint(int index, String type) {
    setState(() {
      selectedLineId = null;
      isSelectedLine = false;
      isSelectedPoint = true;
      if (type == 'trafo') {
        selectedTrafoIndex = index;
        _controller.text =
            listTrafo.firstWhere((value) => value.id == index).title ?? "";
      } else {
        selectedKebutuhan = null;
        selectedGaris = null;
        selectedIsExisting = null;
        if (tempSelectedForLine == null) {
          dev.log("selected line : $index");
          tempSelectedForLine = index;
          selectedIndex = index;
          _controller.text =
              listPoints.firstWhere((value) => value.id == index).title ?? "";
          String title =
              listPoints.firstWhere((value) => value.id == index).title!;
          String garis =
              listPoints.firstWhere((value) => value.id == index).type!;
          setState(() {
            selectedKebutuhan = title;
            selectedGaris = garis;
            selectedIsExisting =
                listPoints.firstWhere((value) => value.id == index).isExisting!
                    ? 'existing'
                    : 'non-existing';
          });
        } else if (tempSelectedForLine == index) {
          // Klik lagi titik yang sama → batal pilih
          tempSelectedForLine = null;
        } else {
          // Buat garis antara dua titik
          dev.log("tempSelectedForLine $tempSelectedForLine");
          dev.log("index $index");
          dev.log("masuk sini");
          _createLine(tempSelectedForLine!, index);
          tempSelectedForLine = null;
        }
      }
    });
  }

  void _createLine(int id1, int id2) {
    for (var value in listLine) {
      dev.log({
        "id1": id1,
        "id2": id2,
        "line1": value.startId,
        "line2": value.endId
      }.toString());
    }
    // Hindari duplikat
    if (listLine.any((l) =>
        (l.startId == id1 && l.endId == id2) ||
        (l.startId == id2 && l.endId == id1))) return;

    setState(() {
      listLine.add(LineModel(
          lineid: DateTime.now().millisecondsSinceEpoch,
          startId: id1,
          endId: id2,
          color: listPoints.firstWhere((value) => value.id == id2).lineColor!,
          isExisting:
              listPoints.firstWhere((value) => value.id == id2).isExisting!));
    });
    dev.log("listLine $listLine");
  }

  void _deletePoint() {
    dev.log("sele $selectedIndex");
    if (selectedIndex == null) {
      if (selectedTrafoIndex == null) {
        return;
      } else {
        setState(() {
          listTrafo.removeWhere((element) => element.id == selectedTrafoIndex);
          selectedTrafoIndex = null;
        });
      }
    } else {
      setState(() {
        listLine.removeWhere((element) =>
            element.startId == selectedIndex || element.endId == selectedIndex);
        listPoints.removeWhere((element) => element.id == selectedIndex);
        selectedIndex = null;
        tempSelectedForLine = null;
      });
    }
  }

  int? detctedLine(Offset tapPos) {
    for (var l in listLine) {
      final p1 = listPoints.firstWhere((p) => p.id == l.startId).point;
      final p2 = listPoints.firstWhere((p) => p.id == l.endId).point;

      if (_isTapNearLine(tapPos, p1!, p2!)) {
        return l.lineid;
      }
    }
    return null;
  }

  // Hitung klik dekat garis
  bool _isTapNearLine(Offset tap, Offset a, Offset b) {
    const threshold = 1;
    double distance = _distanceFromPointToLine(tap, a, b);
    return distance <= threshold;
  }

  double _distanceFromPointToLine(Offset p, Offset a, Offset b) {
    final A = p.dx - a.dx;
    final B = p.dy - a.dy;
    final C = b.dx - a.dx;
    final D = b.dy - a.dy;

    double dot = A * C + B * D;
    double lenSq = C * C + D * D;
    double param = dot / lenSq;

    double xx, yy;

    if (param < 0) {
      xx = a.dx;
      yy = a.dy;
    } else if (param > 1) {
      xx = b.dx;
      yy = b.dy;
    } else {
      xx = a.dx + param * C;
      yy = a.dy + param * D;
    }

    double dx = p.dx - xx;
    double dy = p.dy - yy;
    return sqrt(dx * dx + dy * dy);
  }

  // Pilih garis
  void selectLine(int id) {
    setState(() {
      tempSelectedForLine = null;
      selectedIndex = null;
      selectedTrafoIndex = null;
      isSelectedLine = true;
      isSelectedPoint = false;
      if(selectedLineId != id) {
        selectedLineId = id;
      } else {
        isSelectedLine = false;
        selectedLineId = null;
      }
      dev.log("isSelectedLine $isSelectedLine");
    });
  }

  void deleteLine() {
    setState(() {
      listLine.removeWhere((value) => value.lineid == selectedLineId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garis & Titik Warna Berbeda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
            tooltip: "Upload Gambar",
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToFile,
            tooltip: "Simpan ke PNG",
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: MediaQuery.sizeOf(context).height * 0.5,
                child: _imageFile == null
                    ? const Text("📷 Pilih gambar dulu...")
                    : RepaintBoundary(
                        key: _repaintKey,
                        child: GestureDetector(
                          onTapDown: (details) {
                            final pos = details.localPosition;
                            int? tapped, tappedLine;
                            
                            tappedLine = detctedLine(pos);
                            if(tappedLine != null) {
                              selectLine(tappedLine);
                              return;
                            }

                            for (int i = 0; i < listPoints.length; i++) {
                              if ((listPoints[i].point! - pos).distance < 30) {
                                tapped = listPoints[i].id;
                                break;
                              }
                            }
                            if (tapped != null) {
                              _selectPoint(tapped, 'non-trafo');
                            } else {
                              for (int i = 0; i < listTrafo.length; i++) {
                                if ((listTrafo[i].point! - pos).distance < 30) {
                                  tapped = listTrafo[i].id;
                                  break;
                                }
                              }
                              if (tapped != null) {
                                _selectPoint(tapped, 'trafo');
                              } else {
                                _addPoint(pos);
                              }
                            }
                          },
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              CustomPaint(
                                size: Size.infinite,
                                painter:
                                    GarisWarnaPainter(listPoints, listLine, selectedLineId),
                              ),
                              for (int i = 0; i < listPoints.length; i++)
                                Positioned(
                                  left: listPoints[i].point!.dx - 12,
                                  top: listPoints[i].point!.dy - 12,
                                  child: GestureDetector(
                                    onPanUpdate: (d) {
                                      setState(() {
                                        listPoints[i].point =
                                            listPoints[i].point! + d.delta;
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        if (listPoints[i].title?.isNotEmpty ??
                                            false)
                                          // Container(
                                          //   padding: const EdgeInsets.symmetric(
                                          //       horizontal: 6, vertical: 3),
                                          //   decoration: BoxDecoration(
                                          //     color: Colors.white,
                                          //     borderRadius:
                                          //         BorderRadius.circular(6),
                                          //     boxShadow: const [
                                          //       BoxShadow(
                                          //           color: Colors.black26,
                                          //           blurRadius: 3)
                                          //     ],
                                          //   ),
                                          //   child: Text(
                                          //     listPoints[i].title!,
                                          //     style:
                                          //         const TextStyle(fontSize: 10),
                                          //   ),
                                          // ),
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: listPoints[i].dotColor ??
                                                Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: listPoints[i].id ==
                                                        tempSelectedForLine
                                                    ? Colors.black
                                                    : Colors.white,
                                                width: 2),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${i + 1}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              for (int i = 0; i < listTrafo.length; i++)
                                Positioned(
                                  left: listTrafo[i].point!.dx - 12,
                                  top: listTrafo[i].point!.dy - 12,
                                  child: GestureDetector(
                                    onPanUpdate: (d) {
                                      setState(() {
                                        listTrafo[i].point =
                                            listTrafo[i].point! + d.delta;
                                      });
                                    },
                                    child: Column(
                                      children: [
                                        if (listTrafo[i].title?.isNotEmpty ??
                                            false)
                                          // Container(
                                          //   padding: const EdgeInsets.symmetric(
                                          //       horizontal: 6, vertical: 3),
                                          //   decoration: BoxDecoration(
                                          //     color: Colors.white,
                                          //     borderRadius:
                                          //         BorderRadius.circular(6),
                                          //     boxShadow: const [
                                          //       BoxShadow(
                                          //           color: Colors.black26,
                                          //           blurRadius: 3)
                                          //     ],
                                          //   ),
                                          //   child: Text(
                                          //     listTrafo[i].title!,
                                          //     style:
                                          //         const TextStyle(fontSize: 10),
                                          //   ),
                                          // ),
                                        Container(
                                            width: 24,
                                            height: 24,
                                            alignment: Alignment.center,
                                            child: ClipPath(
                                              clipper: TriangleClipper(),
                                              child: Container(
                                                  color: listTrafo[i].dotColor),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              selectedIndex != null || selectedTrafoIndex != null
                  ? Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                    "Edit Label Titik ${(selectedIndex ?? selectedTrafoIndex)! + 1}"),
                              ),
                              Expanded(
                                  child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedKebutuhan = null;
                                    selectedGaris = null;
                                    selectedIsExisting = null;
                                    selectedIndex = null;
                                    selectedTrafoIndex = null;
                                    tempSelectedForLine = null;
                                  });
                                },
                                child: Icon(Icons.close),
                              ))
                            ],
                          ),
                          const SizedBox(height: 8),
                          if(isSelectedPoint!)
                          Column(
                            children: [
                              TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: "Label Titik",
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    if (selectedIndex != null) {
                                      listPoints.firstWhere((value) => value.id == selectedIndex).title = v;
                                    } else {
                                      listTrafo.firstWhere((value) => value.id == selectedTrafoIndex).title = v;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _deletePoint,
                                icon: const Icon(Icons.delete),
                                label: const Text("Hapus Titk"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(),
              if(isSelectedLine!)
              Column(
                children: [
                  Text("Garis"),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: deleteLine,
                    icon: const Icon(Icons.delete),
                    label: const Text("Hapus Garis"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),    
              Container(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Expanded(
                        child: buildDropDownKebutuhan((value) {
                          setState(() {
                            selectedKebutuhanMaterial = value;
                          });
                        }),
                      ),
                      if (selectedKebutuhanMaterial != null)
                        Expanded(
                          child: buildDropDownGaris((value) {
                            setState(() {
                              selectedKebutuhanGaris = value;
                              dev.log("selected index $selectedIndex");
                              if (listPoints.isNotEmpty &&
                                  selectedIndex != null) {
                                listPoints
                                    .firstWhere(
                                        (value) => value.id == selectedIndex)
                                    .lineColor = selectedKebutuhanGaris!.color!;
                              }
                            });
                          }),
                        ),
                      if (selectedKebutuhanGaris != null)
                        Expanded(
                          child: buildDropDownExisting((value) {
                            setState(() {
                              selectedExisting = value;
                              if (listPoints.isNotEmpty &&
                                  selectedIndex != null) {
                                listPoints
                                        .firstWhere((value) =>
                                            value.id == selectedIndex)
                                        .isExisting =
                                    value == 'existing' ? true : false;
                              }
                            });
                          }),
                        )
                    ],
                  )),
              if (selectedKebutuhan != null &&
                  selectedGaris != null &&
                  selectedIsExisting != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Titik Yang Dipilih"),
                      Text("Nama Kebutuhan : $selectedKebutuhan"),
                      Text("Nama Garis : $selectedGaris"),
                      Text("Existing : $selectedIsExisting"),
                    ],
                  ),
                ),
              Container(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Existing"),
                          SizedBox(height: 10),
                          ...listKebutuhanMaterial.map((value) {
                            int total = listPoints.where((element) {
                              return element.title!.contains(value.title!) &&
                                  element.isExisting == true &&
                                  element.type == 'sutm';
                            }).length;
                            if (total >= 1) {
                              return Text("${value.title!} sutm : $total");
                            }
                            return Container();
                          }),
                          ...listKebutuhanMaterial.map((value) {
                            int total = listPoints.where((element) {
                              return element.title!.contains(value.title!) &&
                                  element.isExisting == true &&
                                  element.type == 'sutr';
                            }).length;
                            if (total >= 1) {
                              return Text("${value.title!} sutr : $total");
                            }
                            return Container();
                          }),
                          const Divider(height: 10),
                          Text("SUTM"),
                          SizedBox(height: 10),
                          ...listKebutuhanMaterial.map((value) {
                            int total = listPoints.where((element) {
                              return element.title!.contains(value.title!) &&
                                  element.isExisting == false &&
                                  element.type == 'sutm';
                            }).length;
                            if (total >= 1) {
                              return Text("${value.title!}: $total");
                            }
                            return Container();
                          }),
                          const Divider(height: 10),
                          Text("SUTR"),
                          SizedBox(height: 10),
                          ...listKebutuhanMaterial.map((value) {
                            int total = listPoints.where((element) {
                              return element.title!.contains(value.title!) &&
                                  element.isExisting == false &&
                                  element.type == 'sutr';
                            }).length;
                            if (total >= 1) {
                              return Text("${value.title!}: $total");
                            }
                            return Container();
                          }),
                          const Divider(height: 10),
                          Text("Trafo"),
                          SizedBox(height: 10),
                          ...listKebutuhanMaterial
                              .where((value) {
                                return value.title == 'Trafo';
                              })
                              .toList()
                              .map((value) {
                                int total = listTrafo.where((element) {
                                  return element.title!.contains(value.title!);
                                }).length;
                                if (total >= 1) {
                                  return Text("${value.title!}: $total");
                                }
                                return Container();
                              }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropDownKebutuhan(ValueChanged onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<KebutuhanMaterial>(
          isExpanded: true,
          hint: const Text("Pilih Kategori Material"),
          value: selectedKebutuhanMaterial,
          items: listKebutuhanMaterial.map((kebutuhanMaterial) {
            return DropdownMenuItem(
              value: kebutuhanMaterial,
              child: Text(kebutuhanMaterial.title.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget buildDropDownGaris(ValueChanged onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<KebutuhanGaris>(
          isExpanded: true,
          hint: const Text("Pilih Kategori Garis"),
          value: selectedKebutuhanGaris,
          items: listKebutuhanGaris.map((KebutuhanGaris) {
            return DropdownMenuItem(
              value: KebutuhanGaris,
              child: Text(KebutuhanGaris.title.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget buildDropDownExisting(ValueChanged onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("Pilih Existing"),
          value: selectedExisting,
          items: ['existing', 'non-existing'].map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// 🎨 Custom Painter untuk garis warna berbeda
class GarisWarnaPainter extends CustomPainter {
  final List<PointsModel> listPoints;
  final List<LineModel> lines;
  int? selectedLine;

  GarisWarnaPainter(this.listPoints, this.lines, this.selectedLine);

  @override
  void paint(Canvas canvas, Size size) {
    // if (listPoints.length < 2) return;

    // for (int i = 0; i < listPoints.length - 1; i++) {
    //   final paint = Paint()
    //     ..color = listPoints[i].lineColor ?? Colors.blue
    //     ..strokeWidth = 3
    //     ..style = PaintingStyle.stroke;
    //   if (!listPoints[i].isExisting!) {
    //     _drawDashedLine(
    //         canvas, listPoints[i].point!, listPoints[i + 1].point!, paint);
    //   } else {
    //     canvas.drawLine(listPoints[i].point!, listPoints[i + 1].point!, paint);
    //   }
    // }
    for (var line in lines) {
      final start = listPoints.firstWhere((p) => p.id == line.startId,
          orElse: () => PointsModel.zero());
      final end = listPoints.firstWhere((p) => p.id == line.endId,
          orElse: () => PointsModel.zero());
      if (start.point == Offset.zero || end.point == Offset.zero) {
        dev.log("kenenk");
        continue;
      }

      dev.log("start ${start.toString()}");
      dev.log("end ${end.toString()}");

      final paint = Paint()
        ..color = line.color
        ..strokeWidth = 3
        ..strokeWidth =  line.lineid == selectedLine ? 5 : 3;
      if (line.isExisting) {
        canvas.drawLine(start.point!, end.point!, paint);
      } else {
        _drawDashedLine(canvas, start.point!, end.point!, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 6.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    double distance = (dx * dx + dy * dy);
    distance = math.sqrt(distance);
    final direction = Offset(dx / distance, dy / distance);

    double current = 0;
    while (current < distance) {
      final p1 = start + direction * current;
      current += dashWidth;
      final p2 = start + direction * (current.clamp(0, distance));
      canvas.drawLine(p1, p2, paint);
      current += dashSpace;
    }
  }

  @override
  bool shouldRepaint(GarisWarnaPainter oldDelegate) => true;
}

class KebutuhanMaterial {
  int? idKebutuhan;
  Color? color;
  String? title;

  KebutuhanMaterial({this.idKebutuhan, this.color, this.title});
}

class KebutuhanGaris {
  Color? color;
  String? title;

  KebutuhanGaris({this.color, this.title});
}

class PointsModel {
  int? id;
  Color? dotColor, lineColor;
  String? title, type;
  Offset? point;
  bool? isExisting;

  PointsModel(
      {this.id,
      this.dotColor,
      this.lineColor,
      this.title,
      this.point,
      this.type,
      this.isExisting});

  static PointsModel zero() => PointsModel(
      id: -1,
      point: Offset.zero,
      dotColor: Colors.transparent,
      lineColor: Colors.transparent);
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0); // Top center
    path.lineTo(0, size.height); // Bottom left
    path.lineTo(size.width, size.height); // Bottom right
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LineModel {
  int lineid;
  int startId;
  int endId;
  Color color;
  bool isExisting;

  LineModel(
      {required this.lineid,
      required this.startId,
      required this.endId,
      required this.color,
      required this.isExisting});
}
