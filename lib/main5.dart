import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
      home: const GarisTitikTidakUrutPage(),
    );
  }
}

class GarisTitikTidakUrutPage extends StatefulWidget {
  const GarisTitikTidakUrutPage({super.key});

  @override
  State<GarisTitikTidakUrutPage> createState() =>
      _GarisTitikTidakUrutPageState();
}

class _GarisTitikTidakUrutPageState extends State<GarisTitikTidakUrutPage> {
  File? _imageFile;
  final List<PointModel> _points = [];
  final List<LineModel> _lines = [];
  int? selectedPointId;
  int? tempSelectedForLine;
  final _labelController = TextEditingController();
  final _picker = ImagePicker();
  final _repaintKey = GlobalKey();
  final Random _rand = Random();

  // 🔹 Warna acak lembut
  Color _randomColor() {
    return HSLColor.fromAHSL(
      1.0,
      _rand.nextDouble() * 360,
      0.6,
      0.6,
    ).toColor();
  }

  // 📷 Upload gambar
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _points.clear();
        _lines.clear();
        selectedPointId = null;
      });
    }
  }

  // 💾 Simpan hasil ke PNG
  Future<void> _saveToFile() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/hasil_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Gambar disimpan di: $path')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal menyimpan: $e')),
      );
    }
  }

  // ➕ Tambah titik baru
  void _addPoint(Offset pos) {
    setState(() {
      final id = DateTime.now().millisecondsSinceEpoch;
      _points.add(PointModel(
        id: id,
        position: pos,
        color: _randomColor(),
        label: "Titik ${_points.length + 1}",
      ));
      selectedPointId = id;
      _labelController.text = "Titik ${_points.length}";
    });
  }

  // 🟡 Pilih titik (untuk edit atau sambung)
  void _selectPoint(int id) {
    setState(() {
      // Jika belum ada titik untuk sambungan
      if (tempSelectedForLine == null) {
        tempSelectedForLine = id;
        selectedPointId = id;
        _labelController.text =
            _points.firstWhere((p) => p.id == id).label ?? "";
      } else if (tempSelectedForLine == id) {
        // Klik lagi titik yang sama → batal pilih
        tempSelectedForLine = null;
      } else {
        // Buat garis antara dua titik
        _createLine(tempSelectedForLine!, id);
        tempSelectedForLine = null;
      }
    });
  }

  // 🔗 Buat garis antar dua titik
  void _createLine(int id1, int id2) {
    // Hindari duplikat
    if (_lines.any((l) =>
        (l.startId == id1 && l.endId == id2) ||
        (l.startId == id2 && l.endId == id1))) return;

    setState(() {
      _lines.add(LineModel(
        startId: id1,
        endId: id2,
        color: _randomColor(),
      ));
    });
  }

  // ❌ Hapus titik tanpa urut
  void _deleteSelectedPoint() {
    if (selectedPointId == null) return;
    setState(() {
      _lines.removeWhere((l) =>
          l.startId == selectedPointId || l.endId == selectedPointId);
      _points.removeWhere((p) => p.id == selectedPointId);
      selectedPointId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garis & Titik Tidak Urut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToFile,
          ),
        ],
      ),
      body: Center(
        child: _imageFile == null
            ? const Text("📷 Upload gambar terlebih dahulu...")
            : RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onTapDown: (details) {
                    final pos = details.localPosition;
                    int? tappedId;
                    for (var p in _points) {
                      if ((p.position - pos).distance < 20) {
                        tappedId = p.id;
                        break;
                      }
                    }
                    if (tappedId != null) {
                      _selectPoint(tappedId);
                    } else {
                      _addPoint(pos);
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
                        painter: GarisTidakUrutPainter(
                          points: _points,
                          lines: _lines,
                        ),
                      ),
                      for (var p in _points)
                        Positioned(
                          left: p.position.dx - 12,
                          top: p.position.dy - 12,
                          child: GestureDetector(
                            onPanUpdate: (d) {
                              setState(() {
                                p.position += d.delta;
                              });
                            },
                            child: Column(
                              children: [
                                if (p.label?.isNotEmpty ?? false)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 3)
                                      ],
                                    ),
                                    child: Text(
                                      p.label!,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: p.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: (p.id == tempSelectedForLine)
                                            ? Colors.black
                                            : Colors.white,
                                        width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${_points.indexOf(p) + 1}",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      bottomSheet: selectedPointId != null
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Edit Label Titik"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Label Titik",
                    ),
                    onChanged: (v) {
                      setState(() {
                        _points
                            .firstWhere((p) => p.id == selectedPointId!)
                            .label = v;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _deleteSelectedPoint,
                    icon: const Icon(Icons.delete),
                    label: const Text("Hapus Titik Ini"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class GarisTidakUrutPainter extends CustomPainter {
  final List<PointModel> points;
  final List<LineModel> lines;

  GarisTidakUrutPainter({required this.points, required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      final start =
          points.firstWhere((p) => p.id == line.startId, orElse: () => PointModel.zero());
      final end =
          points.firstWhere((p) => p.id == line.endId, orElse: () => PointModel.zero());
      if (start.position == Offset.zero || end.position == Offset.zero) continue;

      final paint = Paint()
        ..color = line.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start.position, end.position, paint);
    }
  }

  @override
  bool shouldRepaint(GarisTidakUrutPainter oldDelegate) => true;
}

// 📍 Model titik
class PointModel {
  int id;
  Offset position;
  Color color;
  String? label;

  PointModel({
    required this.id,
    required this.position,
    required this.color,
    this.label,
  });

  static PointModel zero() =>
      PointModel(id: -1, position: Offset.zero, color: Colors.transparent);
}

// 🔗 Model garis
class LineModel {
  int startId;
  int endId;
  Color color;

  LineModel({
    required this.startId,
    required this.endId,
    required this.color,
  });
}
