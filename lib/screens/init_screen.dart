import 'package:flutter/material.dart';
import 'package:manga_lord/configs/configs.dart';
import 'package:manga_lord/screens/components/fade_image_widget.dart';
import '../cross.dart';
import '../src/rust/api/api.dart' as api;
import '../src/rust/udto.dart';
import 'app_screen.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  _InitScreenState createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  Object? _error;

  Future<void> init() async {
    try {
      final root = await cross.root();
      await api.init(root: root).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw StateError(
          'The native data engine did not finish initializing within 30 seconds.',
        ),
      );
      await initConfigs().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw StateError(
          'Application settings did not finish loading within 30 seconds.',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppScreen()),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: error == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading MangaLord...'),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 52, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'MangaLord could not load its data',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('$error', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        setState(() => _error = null);
                        init();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
