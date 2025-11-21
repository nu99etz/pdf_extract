// import 'dart:developer';
// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'dart:math' as math;
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/rendering.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const GarisDiAtasGambarPage(),
//     );
//   }
// }

// class GarisDiAtasGambarPage extends StatefulWidget {
//   const GarisDiAtasGambarPage({super.key});

//   @override
//   State<GarisDiAtasGambarPage> createState() => _GarisDiAtasGambarPageState();
// }

// class _GarisDiAtasGambarPageState extends State<GarisDiAtasGambarPage> {
//   final List<Offset> points = [];
//   final Map<int, String> labels = {};
//   final Map<int, Color> pointColors = {};
//   final Map<int, Color> lineColors = {};
//   int? selectedIndex;
//   final TextEditingController _controller = TextEditingController();
//   File? _imageFile;

//   final ImagePicker _picker = ImagePicker();

//   List<KebutuhanMaterial> listKebutuhanMaterial = [];
//   List<KebutuhanGaris> listKebutuhanGaris = [];
//   List<String> listExisting = [];
//   List<PointsModel> listPoints = [];

//   Color? selectedColor;
//   KebutuhanMaterial? selectedKebutuhanMaterial;
//   KebutuhanGaris? selectedKebutuhanGaris;
//   String? selectedExisting;

//   @override
//   void initState() {
//     // TODO: implement initState
//     listKebutuhanMaterial.add(
//       KebutuhanMaterial(
//         idKebutuhan: 1,
//         color: Colors.yellow,
//         title: "Tiang Beton"
//       )
//     );
//     listKebutuhanMaterial.add(
//       KebutuhanMaterial(
//         idKebutuhan: 2,
//         color: Colors.red,
//         title: "Tiang Besi"
//       )
//     );
//      listKebutuhanMaterial.add(
//       KebutuhanMaterial(
//         idKebutuhan: 3,
//         color: Colors.blue,
//         title: "Konstruksi"
//       )
//     );
//     listKebutuhanMaterial.add(
//       KebutuhanMaterial(
//         idKebutuhan: 4,
//         color: Colors.red,
//         title: "Trafo"
//       )
//     );
//     listKebutuhanGaris.add(
//       KebutuhanGaris(
//         color: Colors.yellow,
//         title: "sutr"
//       )
//     );
//     listKebutuhanGaris.add(
//       KebutuhanGaris(
//         color: Colors.red,
//         title: "sutm"
//       )
//     );
//     listExisting.add("existing");
//     listExisting.add("non-existing");
//     super.initState();
//   }


//   // 📸 Ambil gambar dari galeri
//   Future<void> _pickImage() async {
//     final picked = await _picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         _imageFile = File(picked.path);
//         points.clear();
//         labels.clear();
//         pointColors.clear();
//         lineColors.clear();
//         selectedIndex = null;
//       });
//     }
//   }

//   // 💾 Simpan hasil ke file PNG
//   Future<void> _saveToFile() async {
//     try {
//       RenderRepaintBoundary boundary =
//           _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       Uint8List pngBytes = byteData!.buffer.asUint8List();

//       final dir = await getApplicationDocumentsDirectory();
//       final path = '${dir.path}/hasil_garis_warna_${DateTime.now().millisecondsSinceEpoch}.png';
//       await File(path).writeAsBytes(pngBytes);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('✅ Gambar disimpan di: $path')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('❌ Gagal menyimpan gambar: $e')),
//       );
//     }
//   }

//   // ➕ Tambah titik baru
//   void _addPoint(Offset pos) {
//     log("hhh");
//     setState(() {
//       points.add(pos);
//       selectedIndex = points.length - 1;
//       labels[selectedIndex!] = "Titik ${points.length}";
//       pointColors[selectedIndex!] = _randomColor();
//       lineColors[selectedIndex!] = _randomColor();
//       _controller.text = labels[selectedIndex!]!;
//       listPoints.add(
//         PointsModel(
//           dotColor: selectedKebutuhanMaterial!.color,
//           lineColor: selectedKebutuhanGaris!.color,
//           point: pos,
//           title: "Titik ${listPoints.length + 1}"
//         )
//       );
//       selectedIndex = listPoints.length - 1;
//     });
//   }

//   void _selectPoint(int i) {
//     setState(() {
//       selectedIndex = i;
//       _controller.text = labels[i] ?? "";
//     });
//   }

//   void _deleteSelectedPoint() {
//     if (selectedIndex == null) return;
//     setState(() {
//       points.removeAt(selectedIndex!);
//       labels.remove(selectedIndex);
//       // reindex labels
//       final newLabels = <int, String>{};
//       for (int i = 0; i < points.length; i++) {
//         newLabels[i] = labels[i] ?? "Titik ${i + 1}";
//       }
//       labels
//         ..clear()
//         ..addAll(newLabels);
//       selectedIndex = null;
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Garis Dinamis di Atas Gambar"),
//         actions: [
//           IconButton(
//             onPressed: _pickImage,
//             icon: const Icon(Icons.image),
//             onPressed: _pickImage,
//             tooltip: "Upload Gambar",
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Container(
//               height: MediaQuery.sizeOf(context).height * 0.5,
//                   child: Stack(
//                     children: [
//                   if (_imageFile != null)
//                       Positioned.fill(
//                         child: Image.file(
//                           _imageFile!,
//                           fit: BoxFit.contain,
//                         ),
//                     )
//                   else
//                     const Center(
//                       child: Text(
//                         "📷 Upload gambar dulu dengan tombol di atas",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     ),
        
//                   // Lapisan interaktif
//                   GestureDetector(
//                     onTapDown: (details) {
//                       final pos = details.localPosition;
        
//                       // Cek apakah tap di dekat titik
//                       int? tappedIndex;
//                       for (int i = 0; i < points.length; i++) {
//                         if ((points[i] - pos).distance < 25) {
//                           tappedIndex = i;
//                           break;
//                         }
//                       }
        
//                       if (tappedIndex != null) {
//                         _selectPoint(tappedIndex);
//                       } else {
//                         _addPoint(pos);
//                       }
//                     },
//                     child: CustomPaint(
//                       painter: GarisPainter(points, listPoints.isNotEmpty ? listPoints[selectedIndex!].lineColor : Colors.black),
//                       size: Size.infinite,
//                       child: Stack(
//                         children: [
//                       for (int i = 0; i < points.length; i++)
//                         Positioned(
//                               left: points[i].dx - 10,
//                               top: points[i].dy - 10,
//                           child: GestureDetector(
//                                 onPanUpdate: (details) {
//                               setState(() {
//                                     points[i] += details.delta;
//                               });
//                             },
//                                 child: Stack(
//                                   alignment: Alignment.center,
//                               children: [
//                                     Column(
//                                       children: [
//                                   Container(
//                                           width: 22,
//                                           height: 22,
//                                           decoration: BoxDecoration(
//                                             color: listPoints.isNotEmpty ? listPoints[selectedIndex!].dotColor : Colors.blue,
//                                             shape: BoxShape.circle,
//                                             border: Border.all(
//                                                 color: Colors.white, width: 2),
//                                             boxShadow: [
//                                               if (i == selectedIndex)
//                                                 BoxShadow(
//                                                   color: listPoints.isNotEmpty ? listPoints[selectedIndex!].dotColor! : Colors.blue,
//                                                   blurRadius: 8,
//                                                   spreadRadius: 2,
//                                                 )
//                                             ],
//                                           ),
//                                           alignment: Alignment.center,
//                                           child: Text(
//                                             '${i + 1}',
//                                             style: const TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 10),
//                                           ),
//                                         ),
//                                         if (labels[i]?.isNotEmpty ?? false)
//                                           Padding(
//                                             padding:
//                                                 const EdgeInsets.only(top: 4),
//                                             child: Text(
//                                               labels[i]!,
//                                               style:
//                                                   const TextStyle(fontSize: 10),
//                                             ),
//                                           ),
//                                       ],
//                                     ),
        
//                                     // Label teks di atas titik
//                                     if (labels[i]?.isNotEmpty ?? false)
//                                       Positioned(
//                                         top: -30,
//                                         child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 6, vertical: 3),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white,
//                                             borderRadius:
//                                                 BorderRadius.circular(6),
//                                       boxShadow: const [
//                                         BoxShadow(
//                                             color: Colors.black26,
//                                                   blurRadius: 4)
//                                       ],
//                                     ),
//                                     child: Text(
//                                       labels[i]!,
//                                             style: const TextStyle(
//                                                 fontSize: 10,
//                                                 color: Colors.black),
//                                   ),
//                                   alignment: Alignment.center,
//                                   child: Text(
//                                     "${i + 1}",
//                                     style: const TextStyle(
//                                         color: Colors.white, fontSize: 10),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                     )
//                   ),
        
//                   // TextField floating jika titik aktif
//                   if (selectedIndex != null)
//                     Positioned(
//                       bottom: 90,
//                       left: 20,
//                       right: 20,
//                       child: Container(
//               padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Colors.black26,
//                               blurRadius: 6,
//                               offset: Offset(0, 3),
//                             )
//                           ],
//                         ),
//               child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text("Edit Label Titik ${selectedIndex! + 1}"),
//                                 InkWell(
//                                     onTap: () async {
//                                       setState(() {
//                                         selectedIndex = null;
//                                       });
//                                     },
//                                     child: const Icon(Icons.delete))
//                               ],
//                             ),
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       border: OutlineInputBorder(),
//                       labelText: "Label Titik",
//                     ),
//                               onChanged: (value) {
//                       setState(() {
//                                   labels[selectedIndex!] = value;
//                       });
//                     },
//                   ),
//                           ],
//                         ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Container(
//               padding: EdgeInsets.all(5),
//               child: Column(
//                 children: [
//                   buildDropDownKebutuhan((value) {
//                      setState(() {
//                        selectedKebutuhanMaterial = value;
//                      });
//                   }),
//                   if(selectedKebutuhanMaterial != null)
//                   buildDropDownGaris((value) {
//                     setState(() {  
//                       selectedKebutuhanGaris = value;
//                     });
//                   }),
//                   if(selectedKebutuhanGaris != null)
//                   buildDropDownExisting((value) {
//                     setState(() {
//                       selectedExisting = value;
//                     });
//                   })
//                 ],
//               )
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (selectedIndex != null)
//             FloatingActionButton(
//               heroTag: "delete",
//               backgroundColor: Colors.red,
//               onPressed: _deleteSelectedPoint,
//               child: const Icon(Icons.delete),
//             ),
//           const SizedBox(width: 10),
//           FloatingActionButton(
//             heroTag: "clear",
//             onPressed: () {
//               setState(() {
//                 points.clear();
//                 labels.clear();
//                 selectedIndex = null;
//               });
//             },
//             child: const Icon(Icons.clear),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildDropDownKebutuhan(ValueChanged onChanged) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black26),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<KebutuhanMaterial>(
//           isExpanded: true,
//           hint: const Text("Pilih Kategori Material"),
//           value: selectedKebutuhanMaterial,
//           items: listKebutuhanMaterial.map((kebutuhanMaterial) {
//             return DropdownMenuItem(
//               value: kebutuhanMaterial,
//               child: Text(kebutuhanMaterial.title.toString()),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }

//   Widget buildDropDownGaris(ValueChanged onChanged) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black26),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<KebutuhanGaris>(
//           isExpanded: true,
//           hint: const Text("Pilih Kategori Garis"),
//           value: selectedKebutuhanGaris,
//           items: listKebutuhanGaris.map((KebutuhanGaris) {
//             return DropdownMenuItem(
//               value: KebutuhanGaris,
//               child: Text(KebutuhanGaris.title.toString()),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }

//   Widget buildDropDownExisting(ValueChanged onChanged) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.black26),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           isExpanded: true,
//           hint: const Text("Pilih Existing"),
//           value: selectedExisting,
//           items: ['existing', 'non-esiting'].map((value) {
//             return DropdownMenuItem(
//               value: value,
//               child: Text(value.toString()),
//             );
//           }).toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }
// }

// class GarisPainter extends CustomPainter {
//   final List<Offset> points;
//   Color? color;
//   GarisPainter(this.points, this.color);

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (points.length < 2) return;
//     final paint = Paint()
//       ..color = color ?? Colors.green
//       ..strokeWidth = 3
//       ..style = PaintingStyle.stroke;

//     for (int i = 0; i < points.length - 1; i++) {
//       _drawDashedLine(canvas, points[i], points[i + 1], paint);
//     }
//   }

  // void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  //   const dashWidth = 10.0;
  //   const dashSpace = 6.0;

  //   final dx = end.dx - start.dx;
  //   final dy = end.dy - start.dy;
  //   double distance = (dx * dx + dy * dy);
  //   distance = math.sqrt(distance);
  //   final direction = Offset(dx / distance, dy / distance);

  //   double current = 0;
  //   while (current < distance) {
  //     final p1 = start + direction * current;
  //     current += dashWidth;
  //     final p2 = start + direction * (current.clamp(0, distance));
  //     canvas.drawLine(p1, p2, paint);
  //     current += dashSpace;
  //   }
  // }

//   @override
//   bool shouldRepaint(GarisWarnaPainter oldDelegate) =>
//       oldDelegate.points != points;
// }

// class KebutuhanMaterial {
//   int? idKebutuhan;
//   Color? color;
//   String? title;

//   KebutuhanMaterial({
//     this.idKebutuhan,
//     this.color,
//     this.title
//   });
// }

// class KebutuhanGaris {
//   Color? color;
//   String? title;

//   KebutuhanGaris({
//     this.color,
//     this.title
//   });
// }

// class PointsModel {
//   Color? dotColor, lineColor;
//   String? title;
//   Offset? point;

//   PointsModel({
//     this.dotColor,
//     this.lineColor,
//     this.title,
//     this.point
//   });
// }
