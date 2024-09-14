import 'package:flutter/material.dart';
import 'package:popu_lib_core/popu_lib_core.dart';

import 'flutter_tts.dart';

class PopuTtsService {
  static PopuTtsService instance = PopuTtsService();

  Future<void> init(String language) async {
    tts = FlutterTts();
    await tts?.setLanguage(language);
  }

  FlutterTts? tts;

  Future<List<PopuTtsSupportedLanguage>> getTroubleshootData() async {
    List<PopuTtsSupportedLanguage> ret = [];
    var lRaw = await tts?.getLanguages;
    var vRaw = await tts?.getVoices;
    PopuLogging.logger.w('Languages $lRaw');
    PopuLogging.logger.w('Voices $vRaw');
    var languages = lRaw as List<dynamic>;
    
    for (var l in languages) {
      ret.add(PopuTtsSupportedLanguage(l.toString()));
    }
    var voices = vRaw as List<Map<dynamic, dynamic>>;
    for (var v in voices) {
      for (var entry in v.entries) {
        for (var l in ret) {
          if (l.langCode == entry.value.toString()) {
            l.voices.add(entry.key.toString());
          }
        }
      }
    }
    ret.sort((a, b) => a.langCode.compareTo(b.langCode));
    return ret;
  }

  Future<void> speak(String text) async {
    await tts?.speak(text);
  }
}

class PopuTtsSupportedLanguage {
  final String langCode;
  List<String> voices = [];

  PopuTtsSupportedLanguage(this.langCode);

  @override
  String toString() {
    return "$langCode[ ${voices.join(", ")}]";
  }
}

class PopuTtsTroubleshootScreen extends StatefulWidget {
  @override
  State<PopuTtsTroubleshootScreen> createState() =>
      _PopuTtsTroubleshootScreenState();
}

class _PopuTtsTroubleshootScreenState extends State<PopuTtsTroubleshootScreen> {
  List<PopuTtsSupportedLanguage> _data = [];

  @override
  void initState() {
    super.initState();
    PopuTtsService.instance.getTroubleshootData().then((v) => {
          setState(() {
            _data = v;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Tts')),
        body: SizedBox(
            height: 500,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: _data
                  .map((x) => _buildGridItem(context, x.toString()))
                  .toList(),
            )));
  }

  Widget _buildGridItem(BuildContext context, String language) {
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
        ));
  }
}
