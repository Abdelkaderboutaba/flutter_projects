import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as p; // ✅ alias ajouté pour éviter le conflit
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Récupérer la liste des caméras disponibles
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(CameraApp(camera: firstCamera));
}

class CameraApp extends StatelessWidget {
  final CameraDescription camera;

  const CameraApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TP2 - Caméra Flutter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TakePictureScreen(camera: camera),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({super.key, required this.camera});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Initialisation du contrôleur de la caméra
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      // Obtenir un dossier temporaire pour enregistrer la photo
      final directory = await getTemporaryDirectory();
      final imagePath = p.join(
        directory.path,
        '${DateTime.now()}.png',
      );

      // Prendre la photo
      final image = await _controller.takePicture();

      // Sauvegarder la photo
      await image.saveTo(imagePath);

      if (!mounted) return;

      // Naviguer vers la page d’affichage
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: imagePath),
        ),
      );
    } catch (e) {
      print("Erreur lors de la prise de photo : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prendre une photo')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo prise')),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}
