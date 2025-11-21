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
      home: const GarisTitikDinamisPage(),
    );
  }
}

class GarisTitikDinamisPage extends StatefulWidget {
  const GarisTitikDinamisPage({super.key});

  @override
  State<GarisTitikDinamisPage> createState() => _GarisTitikDinamisPageState();
}

class _GarisTitikDinamisPageState extends State<GarisTitikDinamisPage> {
  File? _imageFile;
  final List<PointModel> _points = [];
  int? selectedId;
  final _labelController = TextEditingController();
  final _picker = ImagePicker();
  final _repaintKey = GlobalKey();
  final Random _rand = Random();

  // 🎨 Fungsi warna acak lembut
  Color _randomColor() {
    return HSLColor.fromAHSL(
      1.0,
      _rand.nextDouble() * 360,
      0.6,
      0.6,
    ).toColor();
  }

  // 📷 Ambil gambar
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _points.clear();
        selectedId = null;
      });
    }
  }

  // 💾 Simpan ke PNG
  Future<void> _saveImage() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/hasil_${DateTime.now().millisecondsSinceEpoch}.png';
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
      selectedId = id;
      _labelController.text = "Titik ${_points.length}";
    });
  }

  // 🟡 Pilih titik
  void _selectPoint(int id) {
    setState(() {
      selectedId = id;
      _labelController.text =
          _points.firstWhere((p) => p.id == id).label ?? "";
    });
  }

  // ❌ Hapus titik tanpa urut
  void _deleteSelectedPoint() {
    if (selectedId == null) return;
    setState(() {
      _points.removeWhere((p) => p.id == selectedId);
      selectedId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garis & Titik Dinamis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
            tooltip: "Upload Gambar",
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveImage,
            tooltip: "Simpan ke PNG",
          ),
        ],
      ),
      body: Center(
        child: _imageFile == null
            ? const Text("📷 Silakan upload gambar terlebih dahulu...")
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
                        painter: GarisPainter(points: _points),
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
                                    border:
                                        Border.all(color: Colors.white, width: 2),
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
      bottomSheet: selectedId != null
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
                            .firstWhere((p) => p.id == selectedId!)
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

class GarisPainter extends CustomPainter {
  final List<PointModel> points;
  GarisPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final paint = Paint()
        ..color = points[i].color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(points[i].position, points[i + 1].position, paint);
    }
  }

  @override
  bool shouldRepaint(GarisPainter oldDelegate) => true;
}

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
}
