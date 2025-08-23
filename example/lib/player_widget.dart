// ignore_for_file: unawaited_futures, discarded_futures
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:ogg_opus_player_example/main.dart';
import 'package:ogg_record_player/ogg_record_player.dart';

class OpusOggPlayerWidget extends StatefulWidget {
  const OpusOggPlayerWidget({super.key, required this.path});

  final String path;

  @override
  State<OpusOggPlayerWidget> createState() => _OpusOggPlayerWidgetState();
}

class _OpusOggPlayerWidgetState extends State<OpusOggPlayerWidget> {
  late OggOpusPlayer? _player;

  Timer? timer;

  int _playingPosition = 0;
  int _playingDuration = 0;

  static const List<double> _kPlaybackSpeedSteps = <double>[0.5, 1, 1.5, 2];

  int _speedIndex = 1;

  @override
  void initState() {
    super.initState();
    unawaited(initPlayer());
    timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      final PlayerState state = _player?.state.value ?? PlayerState.idle;
      if (state == PlayerState.playing) {
        setState(() {
          _playingPosition = _player?.currentPosition ?? 0;
          _playingDuration = _player?.duration ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();

    _player?.dispose();
    super.dispose();
  }

  Future<void> initPlayer() async {
    _speedIndex = 1;
    _player = OggOpusPlayer(widget.path);
    await session.configure(const AudioSessionConfiguration.music());
    final bool active = await session.setActive(true);
    debugPrint('active: $active');
    _player?.state.addListener(() async {
      if (mounted) {
        setState(() {});
        if (_player?.state.value == PlayerState.ended) {
          _player?.dispose();
          _player = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final PlayerState state = _player?.state.value ?? PlayerState.idle;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('p: ${_playingPosition.toStringAsFixed(2)} / d: ${_playingDuration.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          if (state == PlayerState.playing)
            IconButton(
              onPressed: () {
                _player?.pause();
              },
              icon: const Icon(Icons.pause),
            )
          else
            IconButton(
              onPressed: () async {
                if (state == PlayerState.paused) {
                  _player?.play();
                  return;
                } else {
                  await initPlayer();
                  _player?.play();
                }
              },
              icon: const Icon(Icons.play_arrow),
            ),
          TextButton(
            onPressed: () {
              _speedIndex++;
              if (_speedIndex >= _kPlaybackSpeedSteps.length) {
                _speedIndex = 0;
              }
              _player?.setPlaybackRate(_kPlaybackSpeedSteps[_speedIndex]);
            },
            child: Text('X${_kPlaybackSpeedSteps[_speedIndex]}'),
          ),
        ],
      ),
    );
  }
}