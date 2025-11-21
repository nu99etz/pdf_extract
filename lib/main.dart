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

pecahText(String text) {
  List<String> listText = text.split(":");
  Map<String, dynamic> textClean = {};
  textClean = {
    'nama_kebutuhan': listText[0].trim(),
    'jumlah': listText.length >= 2 ? listText[1].trim() : null,
  };
  return textClean;
}

getTitle(List<TextLine> textCollection, {
  double? top = 550,
  double? bottom = 660,
  double? left = 200,
  double? right = 0
}) {
  String judul = "";
  for(var text in textCollection) {
    if(text.bounds.top >= top! && text.bounds.bottom <= bottom! && text.bounds.left <= left!) {
      judul += " ${text.text}";
    }
  }     
  return judul;
}

getKebutuhan(List<TextLine> textCollection, {
  double? top = 550,
  double? bottom = 550,
  double? left = 650,
  double? right = 0
}) {
  KebutuhanPdf? kebutuhanPdf = KebutuhanPdf();
  String? type;
  List<String> duplicate = [];
  int key = 0;
  for(var text in textCollection) {
    if(text.bounds.top <= top! && text.bounds.bottom <= bottom! && text.bounds.left >= left!) {
      duplicate.add(text.text);
      if(text.text.contains("KONDISI EXISTING")) {
        type = 'existing';
        kebutuhanPdf.existing = [];
        continue;
      } else if(text.text.contains("KEBUTUHAN MATERIAL SUTM")) {
        type = 'sutm';
        kebutuhanPdf.sutm = [];
        continue;
      } else if(text.text.contains("KEBUTUHAN MATERIAL GARDU")) {
        type = 'gd';
        kebutuhanPdf.gardu = [];
        continue;
      } else if(text.text.contains("KEBUTUHAN MATERIAL SUTR")) {
        type = 'sutr';
        kebutuhanPdf.sutr = [];
        continue;
      }

      String originalText = text.text;
      if(!originalText.contains(":")) {
        key++;
        originalText = originalText + " ${textCollection[key].text}";
      }
      Map<String, dynamic> pechaText = pecahText(originalText);
      if(type == 'existing') {
        duplicate.add(text.text);
        kebutuhanPdf.existing!.add(pechaText);
      } else if(type == 'sutm') {
        duplicate.add(text.text);
        kebutuhanPdf.sutm!.add(pechaText);
      } else if(type == 'sutr') {
        duplicate.add(text.text);
        kebutuhanPdf.sutr!.add(pechaText);
      } else if(type == 'gd') {
        duplicate.add(text.text);
        kebutuhanPdf.gardu!.add(pechaText);
      }
    }
  }
  return kebutuhanPdf;
}

checkValue(List<String> listText) {

}

checkIsNumeric(String number) {
  final numericRegex = RegExp(r'^[0-9]+$');
  return numericRegex.hasMatch(number);
}

List<String> cleanText(List<String> listText) {
  List<int> skippedCheck = [];
  List<String> listString = [];
  for(int i = 0; i < listText.length; i++) {
    if(!skippedCheck.contains(i)) {
      if(!checkIsNumeric(listText[i].split(".")[0])) {
        break;
      }
      if(listText[i].contains(":")) {
        listString.add(listText[i]);
      } else {
        if(i != (listText.length - 1)) {
          if("${listText[i]}${listText[i + 1]}".contains(":")) {
            listString.add("${listText[i]}${listText[i + 1]}");
            skippedCheck.add(i+1);
          }
        }
      }
    }
  }
  return listString;
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? textExtract;

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
      log("file : " + file.toString());
      List<String> lines = [];

      //Load an existing PDF document.
      PdfDocument document =
          PdfDocument(inputBytes: file.readAsBytesSync());
      // //Find the text and get matched items.
      // List<TextLine> textCollection =
      //     PdfTextExtractor(document).extractTextLines();  

      // for(var text in textCollection) {
      //   final String textExtract = text.text.trim();
      //   if(textExtract.isNotEmpty) {
      //     lines.add(textExtract);
      //   }
      // }

      // log("line sebelum filter : ${lines.toString()}");

      // lines = lines.where((value) {
      //   return value.startsWith("KEBUTUHAN MATERIAL GARDU");
      // }).toList();

      // log("string lines ${lines.toString()}");

      // // judul
      // String judul = getTitle(textCollection);
      // log("judul ${judul}");

      // // list kebutuhan
      // KebutuhanPdf kebutuhanPdf = getKebutuhan(textCollection);
      // log({
      //   "sutr " : kebutuhanPdf.sutr,
      //   "sutm " : kebutuhanPdf.sutm,
      //   "existing " : kebutuhanPdf.existing, 
      //   "gardu " : kebutuhanPdf.gardu
      // }.toString());

      
      
      // //Get the matched item in the collection using index.
      // MatchedItem matchedText = textCollection[0];
      // //Get the text bounds.
      // Rect textBounds = matchedText.bounds;  
      // //Get the page index.
      // int pageIndex = matchedText.pageIndex; 
      // //Get the text.
      // String text = matchedText.text;
      // //Dispose the document.

      String text = PdfTextExtractor(document).extractText();
      int textSearch = text.indexOf("Tiang Beton 13M");
      log("index " + textSearch.toString());
      // log("text : " + textSearch[1].toString());
      // log("text yanro : " + text);

      setState(() {
        textExtract = text;
      });

      String fullText = PdfTextExtractor(document).extractText();

      int startIndex = fullText.indexOf("KEBUTUHAN MATERIAL SUTM");
      log("startIndex $startIndex");
      if (startIndex == -1) return null;

      // Hitung posisi setelah kata awal
      startIndex += "KEBUTUHAN MATERIAL SUTM".length;

      // Cari kata akhir setelah kata awal
      // int endIndex = fullText.indexOf("KEBUTUHAN MATERIAL SUTR", startIndex);
      // log("endindex $endIndex");
      // if (endIndex == -1) return null;

      // Ambil teks di antara keduanya
      String textDapat = fullText.substring(startIndex).trim();

      List<String> textSplit = textDapat.split("\n");

      List<String> listGardu = cleanText(textSplit);

      log("textDapat ${listGardu.toString()}");

      document.dispose();
      
      // AlertDialog(
      //   content: Text(text),
      // );

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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${textExtract ?? '-'}',
              style: TextStyle(
                fontSize: 10
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
  List<Map<String, dynamic>>? sutr = [];
  List<Map<String, dynamic>>? sutm = [];
  List<Map<String, dynamic>>? gardu = [];
  List<Map<String, dynamic>>? existing = [];

  KebutuhanPdf({
    this.sutm,
    this.sutr,
    this.gardu,
    this.existing
  });
}
