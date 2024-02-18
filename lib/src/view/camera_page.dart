import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  final _streamController = StreamController<String>();
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _initilizeCamera();
    _initializeWebsocket();
  }

  _initilizeCamera() async {
    final camera = await availableCameras();
    final firstCamera = camera.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {});

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final image = await _cameraController!.takePicture();
        Uint8List imageBytes = await image.readAsBytes();
        _channel.sink.add(imageBytes);
      } catch (e) {
        if (kDebugMode) {
          print('Can not take picture');
          print('Error $e');
        }
      }
    });
  }

  _initializeWebsocket() {
    _channel = WebSocketChannel.connect(Uri.parse('ws://0.0.0.0:8765'));
    _channel.stream.listen((event) {
      final parsedEvent = jsonDecode(event);

      if (parsedEvent['status'] == 'success') {
        _streamController.sink.add('Your Face Regonized');
      } else if (parsedEvent['status'] == 'error') {
        _streamController.sink.add('Your Face Not Regonized');
      } else {
        _streamController.sink.add('Error');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController?.dispose();
    _channel.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _cameraController != null
              ? AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(
                    _cameraController!,
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
          StreamBuilder<String>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DataState(
                          data: snapshot.data,
                        )),
                  );
                } else {
                  return const DataState();
                }
              }),
        ],
      ),
    );
  }
}

class DataState extends StatelessWidget {
  const DataState({
    this.data,
    super.key,
  });

  final String? data;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: data == null
                ? Colors.orange
                : data == 'Your Face Regonized'
                    ? Colors.green
                    : Colors.red,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              data ?? 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
