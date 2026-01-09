import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const VideoSplashScreen({super.key, required this.onComplete});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset(
            'assets/_video_intent_create_202601091901_8ebgc.mp4',
          )
          ..initialize().then((_) {
            setState(() {
              _initialized = true;
            });
            _controller.play();
            _controller.addListener(_checkVideo);
          });
  }

  void _checkVideo() {
    if (_controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration &&
        !_completed) {
      _completed = true;
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideo);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(), // Show nothing while initializing
      ),
    );
  }
}
