// ignore_for_file: unawaited_futures, discarded_futures

import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ogg_opus_player_example/player_widget.dart';
import 'package:ogg_record_player/ogg_record_player.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

late AudioSession session;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory tempDir = await getTemporaryDirectory();
  final String workDir = p.join(tempDir.path, 'ogg_record_player');
  debugPrint('workDir: $workDir');
  session = await AudioSession.instance;
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()
          ),
          slivers: [
            SliverToBoxAdapter(child: _RecorderExample(dir: workDir)),
            SliverList.separated(
              itemCount: 80,
              itemBuilder: (_, index) => ListTile(title: Text('Asset example $index')),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecorderExample extends StatefulWidget {
  const _RecorderExample({required this.dir});

  final String dir;

  @override
  State<_RecorderExample> createState() => _RecorderExampleState();
}

class _RecorderExampleState extends State<_RecorderExample> {
  late String _recordedPath;

  OggOpusRecorder? _recorder;

  @override
  void initState() {
    super.initState();
    _recordedPath = p.join(widget.dir, '${DateTime.now().millisecondsSinceEpoch/1000}.ogg');
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const SizedBox(height: 8),
      if (_recorder == null)
        IconButton(
          onPressed: () async {
            final File file = File(_recordedPath);
            if (file.existsSync()) {
              File(_recordedPath).deleteSync();
            }
            File(_recordedPath).createSync(recursive: true);
            await session.configure(
              const AudioSessionConfiguration(
                avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
                avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
                avAudioSessionMode: AVAudioSessionMode.spokenAudio,
              ),
            );
            await session.setActive(true);
            final OggOpusRecorder recorder = OggOpusRecorder(_recordedPath)..start();
            setState(() {
              _recorder = recorder;
            });
          },
          icon: const Icon(Icons.keyboard_voice_outlined),
        )
      else
        IconButton(
          onPressed: () async {
            await _recorder?.stop();
            debugPrint('recording stopped');
            debugPrint('duration: ${await _recorder?.duration()}');
            debugPrint('waveform: ${await _recorder?.getWaveformData()}');
            _recorder?.dispose();
            setState(() {
              _recorder = null;
              unawaited(
                session.setActive(
                  false,
                  avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
                ),
              );
            });
          },
          icon: const Icon(Icons.stop),
        ),
      const SizedBox(height: 8),
      if (_recorder == null && File(_recordedPath).existsSync()) OpusOggPlayerWidget(path: _recordedPath),
    ],
  );
}
