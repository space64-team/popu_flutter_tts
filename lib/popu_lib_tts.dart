import 'package:flutter/material.dart';
import 'package:popu_flutter_tts/flutter_tts.dart';
import 'package:popu_lib_core/popu_lib_core.dart';

class PopuTtsService {
  static PopuTtsService instance = PopuTtsService();

  String language = "";
  FlutterTts? tts;

  Future<void> init(String language) async {
    tts = FlutterTts();
    this.language = language;
    await tts?.setLanguage(language);
  }

  Future<List<String>> getVoices() async {
    var vRaw = await tts?.getVoices;
    var voices = vRaw as List<dynamic>;
    List<String> ret = [];
    for (var v in voices) {
      if (v['locale'] == language) {
        ret.add(v['name'].toString());
      }
    }
    ret.sort((a, b) => a.compareTo(b));
    PopuLogging.logger.w('Voices ${ret.toString()}');
    return ret;
  }

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
    var voices = vRaw as List<dynamic>;
    for (var v in voices) {
      for (var l in ret) {
        if (l.langCode == v['locale']) {
          l.voices.add(v['name'].toString());
        }
      }
    }
    ret.sort((a, b) => a.langCode.compareTo(b.langCode));
    return ret;
  }

  Future<void> speak(String text) async {
    await tts?.speak(text);
  }

  void changeVoice(String voice) async {
    await tts?.setVoice({"name": voice, "locale": language});
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
  const PopuTtsTroubleshootScreen({super.key});

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
        body: ListView(
          padding: const EdgeInsets.all(8),
          children: _data
              .map((x) => _buildGridItem(context, x.toString()))
              .toList(),
        ));
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

class PopuVoiceChangeDialog extends StatefulWidget {
  const PopuVoiceChangeDialog({super.key});

  @override
  State<PopuVoiceChangeDialog> createState() => _PopuVoiceChangeDialogState();
}

class _PopuVoiceChangeDialogState extends State<PopuVoiceChangeDialog> {
  List<String> _voices = [];

  @override
  void initState() {
    super.initState();
    PopuTtsService.instance.getVoices().then((x) => {
      setState(() {
        _voices = x;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Speech Voice'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _voices.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(_voices[index]),
              onTap: () {
                _changeVoice(_voices[index]);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
    );
  }

  void _changeVoice(String voice) {
    PopuTtsService.instance.changeVoice(voice);
  }
}
