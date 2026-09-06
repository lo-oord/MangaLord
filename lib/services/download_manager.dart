import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'team_x_source.dart';
import 'notification_service.dart';

class DownloadItem {
  DownloadItem({required this.id, required this.mangaTitle, required this.chapter, required this.cover, required this.images, this.completed = 0, this.status = DownloadStatus.queued});
  final String id;
  final String mangaTitle;
  final TeamXChapter chapter;
  final String cover;
  final List<String> images;
  int completed;
  DownloadStatus status;
  double get progress => images.isEmpty ? 0 : completed / images.length;
  Map<String, dynamic> toJson() => {'id': id, 'mangaTitle': mangaTitle, 'cover': cover, 'chapter': chapter.toJson(), 'images': images, 'completed': completed, 'status': status.name};
}

enum DownloadStatus { queued, downloading, paused, completed, failed, cancelled }

class DownloadManager extends ChangeNotifier {
  final List<DownloadItem> items = [];
  final Map<String, Future<void>> _running = {};
  final http.Client _client = http.Client();

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('mangalord.downloads');
    if (raw == null) return;
    final decoded = jsonDecode(raw) as List?;
    if (decoded == null) return;
    items
      ..clear()
      ..addAll(decoded.whereType<Map>().map((entry) {
        final json = Map<String, dynamic>.from(entry);
        return DownloadItem(id: json['id'] as String, mangaTitle: json['mangaTitle'] as String? ?? '', cover: json['cover'] as String? ?? '', chapter: TeamXChapter.fromJson(Map<String, dynamic>.from(json['chapter'] as Map)), images: (json['images'] as List? ?? const []).whereType<String>().toList(), completed: (json['completed'] as num?)?.toInt() ?? 0, status: DownloadStatus.values.firstWhere((value) => value.name == json['status'], orElse: () => DownloadStatus.paused));
      }));
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mangalord.downloads', jsonEncode(items.map((item) => item.toJson()).toList()));
  }

  Future<void> enqueue({required String mangaTitle, required String cover, required TeamXChapter chapter}) async {
    final id = '${chapter.url}::${chapter.number}';
    if (items.any((item) => item.id == id && item.status != DownloadStatus.failed && item.status != DownloadStatus.cancelled)) return;
    final item = DownloadItem(id: id, mangaTitle: mangaTitle, cover: cover, chapter: chapter, images: chapter.images);
    items.add(item);
    notifyListeners();
    await _persist();
    _running[id] = _download(item).whenComplete(() => _running.remove(id));
  }

  Future<void> enqueueAll({required String mangaTitle, required String cover, required List<TeamXChapter> chapters}) async {
    for (final chapter in chapters) {
      if (chapter.images.isNotEmpty) await enqueue(mangaTitle: mangaTitle, cover: cover, chapter: chapter);
    }
  }

  Future<void> _download(DownloadItem item) async {
    item.status = DownloadStatus.downloading;
    notifyListeners();
    await MangaNotificationService.instance.downloadProgress(title: '${item.mangaTitle} • الفصل ${item.chapter.number}', progress: (item.progress * 100).round(), failed: false);
    try {
      final root = await getApplicationDocumentsDirectory();
      final directory = Directory('${root.path}/mangalord/${_safe(item.mangaTitle)}/chapter_${_safe(item.chapter.number)}');
      await directory.create(recursive: true);
      for (var index = item.completed; index < item.images.length; index++) {
        if (item.status == DownloadStatus.paused || item.status == DownloadStatus.cancelled) break;
        final response = await _client.get(Uri.parse(item.images[index]), headers: const {'Referer': 'https://olympustaff.com/'});
        if (response.statusCode < 200 || response.statusCode >= 400) throw Exception('HTTP ${response.statusCode}');
        await File('${directory.path}/${(index + 1).toString().padLeft(4, '0')}.jpg').writeAsBytes(response.bodyBytes);
        item.completed = index + 1;
        notifyListeners();
        await MangaNotificationService.instance.downloadProgress(title: '${item.mangaTitle} • الفصل ${item.chapter.number}', progress: (item.progress * 100).round(), failed: false);
        await _persist();
      }
      if (item.completed == item.images.length) item.status = DownloadStatus.completed;
      await _persist();
      await MangaNotificationService.instance.downloadProgress(title: '${item.mangaTitle} • الفصل ${item.chapter.number}', progress: (item.progress * 100).round(), failed: false);
      notifyListeners();
    } catch (_) {
      item.status = DownloadStatus.failed;
      await _persist();
      await MangaNotificationService.instance.downloadProgress(title: '${item.mangaTitle} • الفصل ${item.chapter.number}', progress: (item.progress * 100).round(), failed: true);
      notifyListeners();
    }
  }

  Future<List<String>> localImagesFor(TeamXChapter chapter, String mangaTitle) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/mangalord/${_safe(mangaTitle)}/chapter_${_safe(chapter.number)}');
    if (!await directory.exists()) return const [];
    final files = (await directory.list().where((entry) => entry is File).cast<File>().toList())..sort((a, b) => a.path.compareTo(b.path));
    return files.map((file) => file.path).toList();
  }

  Future<void> pause(String id) async { final item = _find(id); if (item == null) return; item.status = DownloadStatus.paused; await _persist(); notifyListeners(); }
  Future<void> resume(String id) async { final item = _find(id); if (item == null || item.status == DownloadStatus.completed) return; item.status = DownloadStatus.queued; notifyListeners(); _running[id] = _download(item).whenComplete(() => _running.remove(id)); }
  Future<void> remove(String id) async { final item = _find(id); if (item == null) return; item.status = DownloadStatus.cancelled; items.remove(item); await _persist(); notifyListeners(); }
  DownloadItem? _find(String id) { for (final item in items) { if (item.id == id) return item; } return null; }
  String _safe(String value) => value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
}

