import 'package:flutter/material.dart';
import 'package:manga_lord/configs/configs.dart';
import '../cross.dart';
import '../src/rust/api/api.dart' as api;
import 'app_screen.dart';

class InitScreen extends StatefulWidget { const InitScreen({super.key}); @override State<InitScreen> createState() => _InitScreenState(); }
class _InitScreenState extends State<InitScreen> {
  Object? _error;
  @override void initState() { super.initState(); init(); }
  Future<void> init() async { try { final root = await cross.root(); await api.init(root: root).timeout(const Duration(seconds: 30)); await initConfigs().timeout(const Duration(seconds: 30)); if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppScreen())); } catch (error) { if (mounted) setState(() => _error = error); } }
  @override Widget build(BuildContext context) { final error = _error; return Scaffold(backgroundColor: const Color(0xFF0B1714), body: Center(child: error == null ? const Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome_rounded, color: Color(0xFF3DDC97), size: 46), SizedBox(height: 18), CircularProgressIndicator(color: Color(0xFF3DDC97)), SizedBox(height: 18), Text('Loading MangaLord...', style: TextStyle(color: Colors.white))]) : Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFF3DDC97)), const SizedBox(height: 16), const Text('MangaLord could not load its data', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 20), FilledButton(onPressed: () { setState(() => _error = null); init(); }, child: const Text('Retry'))])))); }
}
