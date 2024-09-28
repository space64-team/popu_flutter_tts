import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:popu_lib_core/popu_lib_core.dart';
import 'package:popu_lib_prefs/popu_lib_prefs.dart';

class PopuTtsPreferences {
  static var ttsVoice = PopuStringPreferences('ttsVoice', '');
}

class PopuTtsService {
  static PopuTtsService instance = PopuTtsService();
  static final String _gttsPrefix = "W64";

  final player = AudioPlayer();
  bool firstSetup = false;
  String language = "";
  String currentVoice = "";
  FlutterTts? tts;
  ValueNotifier<int> voiceCount = ValueNotifier<int>(0);

  Future<void> init(String language) async {
    tts = FlutterTts();
    this.language = language;
    await tts?.setLanguage(language);
    currentVoice = PopuTtsPreferences.ttsVoice.get();
  }

  Future<void> _firstSetup() async {
    if (firstSetup) {
      return;
    }
    var voices = await getVoices();
    if (voices.contains(currentVoice)) {
      changeVoice(currentVoice);
    } else if (voices.isNotEmpty) {
      changeVoice(voices.first);
    }
    voiceCount.value = voices.length;
    firstSetup = true;
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
    ret.add(language + _gttsPrefix);
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
    await _firstSetup();
    if (currentVoice == (language + _gttsPrefix)) {
      player.play(UrlSource(
          "https://simplytranslate.org/api/tts/?engine=google&lang=$language&text=${Uri
              .encodeComponent(text)}")).ignore();
    } else {
      tts?.speak(text).ignore();
    }
  }

  void changeVoice(String voice) async {
    if (voice.isEmpty) {
      return;
    }
    currentVoice = voice;
    PopuTtsPreferences.ttsVoice.set(voice);
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
    PopuTtsService.instance.getTroubleshootData().then((v) =>
    {
      setState(() {
        _data = v;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('TTS Troubleshoot')),
        body: ListView(
          padding: const EdgeInsets.all(8),
          children:
          _data.map((x) => _buildGridItem(context, x.toString())).toList(),
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
    PopuTtsService.instance.getVoices().then((x) =>
    {
      setState(() {
        _voices = x;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          PopuLocalization.localizer.localized(context, 'settingsSpeechVoice')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _voices.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(_voices[index]),
              trailing: _voices[index] == PopuTtsService.instance.currentVoice
                  ? Icon(
                Icons.check, // This is the checkmark icon
                color: Colors.green, // You can set the color of the checkmark
              )
                  : null,
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
