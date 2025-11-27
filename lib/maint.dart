import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

checkIsNumeric(String number) {
  final numericRegex = RegExp(r'^[0-9]+$');
  return numericRegex.hasMatch(number);
}

recursiveText(String text, int i, List<String> listText) {
  if(i != (listText.length - 1)) {
    if("${text.toString()}${listText[i+1]}".contains(":")) {
      skippedCheck.add(i+1);
      listString.add("${text.toString()}${listText[i+1]}");
    } else {
      recursiveText("${text.toString()}${listText[i+1]}", i + 1, listText);
    }
  }
}

List<int> skippedCheck = [];
List<String> listString = [];
List<String> cleanText(List<String> listText) {
  skippedCheck = [];
  listString = [];
  for(int i = 0; i < listText.length; i++) {
    if(!skippedCheck.contains(i)) {
      if(!checkIsNumeric(listText[i].split(".")[0].trim())) {
        break;
      }
      if(listText[i].contains(":")) {
        List<String> pecahText = listText[i].split(":");
        if(pecahText.length > 1 && RegExp(r'\s{2,}').hasMatch(pecahText[1])) {
          listString.add("${listText[i]}${listText[i+1]}");
          skippedCheck.add(i+1);
        } else {
          listString.add(listText[i]);
        }
      } else {
        if(i != (listText.length - 1)) {
          skippedCheck.add(i+1);
          if("${listText[i]}${listText[i + 1]}".contains(":")) {
            listString.add("${listText[i]}${listText[i + 1]}");
          } else {
            recursiveText("${listText[i]}${listText[i + 1]}", i + 1, listText);
          }
        }
      }
    }
  }
  return listString;
}

List<KebutuhanPdf> getKeyValue(List<String> listText) {
  List<KebutuhanPdf> listCleanText = [];
  for (var value in listText) {
    List<String> textPecah = value.trim().split(":");
    if(textPecah.length > 1) {
      List<String> valueAngka = textPecah[1].trim().split(" ");
      valueAngka = valueAngka.where((value) {
        return value != "";
      }).toList();
      listCleanText.add(KebutuhanPdf(
        namaKebutuhan: textPecah[0].replaceAll(RegExp(r'\s{2,}'), " ").split(".")[1].trim(),
        volume: int.parse(valueAngka[0]),
        satuan: valueAngka[1]
      ));
    }
  }
  return listCleanText;
}

List<KebutuhanPdf> getKebutuhan({
  String jenisKebutuhan = 'KEBUTUHAN MATERIAL SUTR',
  String? fullText
}) {
  try {
    
    List<KebutuhanPdf> listKebutuhanPdf = [];
    int startIndex = fullText!.indexOf(jenisKebutuhan);
    if(startIndex == -1) {
      throw Exception("Error Can't Read PDF $jenisKebutuhan");
    }

    startIndex += jenisKebutuhan.length;

    String textDapat = fullText.substring(startIndex).trim();
    List<String> textSplit = textDapat.split("\n");
    List<String> listKebutuhan = cleanText(textSplit);
    if(listKebutuhan.isNotEmpty) {
      listKebutuhanPdf = getKeyValue(listKebutuhan);
    }

    return listKebutuhanPdf;

  } catch (e) {
    log("CANT RETRIEVE KEBUTUHAN BECAUSE PDF IS NOT READ ${e.toString()}");
    return [];
  }
}

String cleanTitleText(String title) {
  List<String> cleanTexts = [
    "KEBUTUHAN MATERIAL SUTR",
    "KEBUTUHAN MATERIAL SUTM",
    "KEBUTUHAN MATERIAL GARDU",
    "KONDISI EXISTNG",
    "KEBUTUHAN MATERIAL SP APP",
    "DISETUJUI",
    "DIPERIKSA",
    "DIGAMBAR",
    "NO. GAMBAR",
    "NO. LEMBAR",
    "TANGGAL"
  ];
  List<String> listKataClean = title.split("\n");
  String titleClean = "USULAN ";
  for (var value in listKataClean) {
    bool isBreak = false;
    for (var cleanTextValue in cleanTexts) {
      if(value.contains(cleanTextValue)) {
        isBreak = true;
      }
    }
    if(!isBreak) {
      titleClean += value;
    } else {
      break;
    }
  }
  return titleClean;
}

String getTitle({
  String? fullText
}) {
  try {

    int startIndex = fullText!.indexOf("USULAN");
    if(startIndex == -1) {
      throw Exception("Error Can't Retrieved Judul");
    }

    startIndex += "USULAN".length;

    String textDapat = cleanTitleText(fullText.substring(startIndex).trim());
    return textDapat;

  } catch (e) {
    log("CANT RETRIEVE KEBUTUHAN BECAUSE PDF IS NOT READ ${e.toString()}");
    return "-";
  }
}

List<String> getDaya({
  String? title
}) {
  try {

    int startIndex = title!.indexOf("DAYA");
    if(startIndex == -1) {
      throw Exception("Error Can't Retrieved Daya");
    }

    startIndex += "DAYA".length;
    int endIndex = title.indexOf("VA", startIndex);

    List<String> hasil = title.substring(startIndex, endIndex).replaceAll(RegExp(r'[()]'), "").trim().toString().split("x");

    if(hasil.length > 1) {
      return hasil;
    }

    return [
      "1",
      hasil[0]
    ];

  } catch (e) {
    log("CANT RETRIEVE KEBUTUHAN BECAUSE PDF IS NOT READ ${e.toString()}");
    return [];
  }
}

String getLocationTitle({
  String? title
}) {
  int startIndex = title!.indexOf("LOKASI");
    if(startIndex == -1) {
      throw Exception("Error Can't Retrieved Location");
    }

    startIndex += "LOKASI".length;

    return title.substring(startIndex).trim();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? textExtract, judul, jumlahPelanggan, daya, lokasi;
  List<KebutuhanPdf> listKebutuhanSutr = [];
  List<KebutuhanPdf> listKebutuhanSutm = [];
  List<KebutuhanPdf> listKebutuhanGd = [];
  List<KebutuhanPdf> listKebutuhanSpApp = [];

  void _incrementCounter() async {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      // _counter++;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      setState(() {
        //Load an existing PDF document.
        PdfDocument document =
            PdfDocument(inputBytes: file.readAsBytesSync());

        String text = PdfTextExtractor(document).extractText();

        textExtract = text;

        judul = null;

        judul = getTitle(
          fullText: text
        );

        jumlahPelanggan = getDaya(
          title: judul
        )[0];

        daya = getDaya(
          title: judul
        )[1];

        lokasi = getLocationTitle(
          title: judul
        );

        listKebutuhanSutr = [];
        listKebutuhanGd = [];
        listKebutuhanSutm = [];

        listKebutuhanSutr = getKebutuhan(
          fullText: text,
          jenisKebutuhan: "KEBUTUHAN MATERIAL SUTR"
        );

        listKebutuhanGd = getKebutuhan(
          fullText: text,
          jenisKebutuhan: "KEBUTUHAN MATERIAL GARDU",
        );

        listKebutuhanSutm = getKebutuhan(
          fullText: text,
          jenisKebutuhan: "KEBUTUHAN MATERIAL SUTM"
        );
      });

    } else {

    }
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
      body: SingleChildScrollView(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              judul != null && judul != "-" ? judul! : 'You have pushed the button this many times:',
            ),
            const Text(
              "Kebutuhan SUTR",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),
            ...listKebutuhanSutr.map((value) {
              return Text(
                "${value.namaKebutuhan } - ${value.volume} - ${value.satuan}"
              );
            }),

            const Text(
              "Kebutuhan SUTM",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),
            ...listKebutuhanSutm.map((value) {
              return Text(
                "${value.namaKebutuhan } - ${value.volume} - ${value.satuan}"
              );
            }),

            const Text(
              "Kebutuhan GD",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),
            ...listKebutuhanGd.map((value) {
              return Text(
                "${value.namaKebutuhan } - ${value.volume} - ${value.satuan}"
              );
            }),

            Text(
              "Jumlah Pelanggan : ${jumlahPelanggan ?? "-"}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),

            Text(
              "Jumlah Daya : ${daya ?? "-"}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),

            Text(
              "Lokasi : ${lokasi ?? "-"}",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class KebutuhanPdf {
  String? namaKebutuhan, satuan;
  int? volume;

  KebutuhanPdf({
    this.namaKebutuhan,
    this.volume,
    this.satuan
  });
}
