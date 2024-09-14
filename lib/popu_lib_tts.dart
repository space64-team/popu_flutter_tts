import 'package:flutter/material.dart';

import 'flutter_tts.dart';

class PopuTtsService {
  static PopuTtsService instance = PopuTtsService();

  FlutterTts? tts;
  List<dynamic> languages = [];

  Future<void> init(String language) async {
    tts = FlutterTts();
    await tts?.setLanguage(language);
    languages = await tts?.getLanguages as List<String>;
  }

  Future<void> speak(String text) async {
    await tts?.speak(text);
  }
}

class PopuTtsTroubleshootScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Tts')),
        body: SizedBox(
            height: 500,
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1,
              // Number of columns in the grid
              padding: const EdgeInsets.all(16.0),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: PopuTtsService.instance.languages.map((x) =>
                  _buildGridItem(context, x.toString())
              ).toList(),
            )));
  }

  Widget _buildGridItem(
      BuildContext context, String language) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              language,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            )
          ]),
        )
    );
  }
}