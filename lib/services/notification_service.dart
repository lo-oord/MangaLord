import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MangaNotificationService {
  MangaNotificationService._();
  static final instance = MangaNotificationService._();
  final plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    await plugin.initialize(settings);
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  Future<void> newChapter({required String mangaTitle, required String chapterNumber, required String coverUrl}) async {
    final image = await _cacheCover(mangaTitle, coverUrl);
    final style = image == null ? null : BigPictureStyleInformation(FilePathAndroidBitmap(image), contentTitle: mangaTitle, summaryText: 'فصل جديد • $chapterNumber');
    final android = AndroidNotificationDetails('mangalord_updates', 'Manga updates', channelDescription: 'New chapters from favorite manga', importance: Importance.high, priority: Priority.high, styleInformation: style);
    await plugin.show(mangaTitle.hashCode ^ chapterNumber.hashCode, 'فصل جديد', '$mangaTitle • الفصل $chapterNumber', NotificationDetails(android: android));
  }

  Future<void> downloadProgress({required String title, required int progress, required bool failed}) async {
    final android = AndroidNotificationDetails('mangalord_downloads', 'Downloads', channelDescription: 'Manga download progress', importance: Importance.low, priority: Priority.low, showProgress: !failed, maxProgress: 100, progress: progress.clamp(0, 100).toInt(), ongoing: !failed && progress < 100, onlyAlertOnce: true);
    await plugin.show(title.hashCode, failed ? 'فشل التنزيل' : progress >= 100 ? 'تم التنزيل' : 'جاري التنزيل', title, NotificationDetails(android: android));
  }

  Future<String?> _cacheCover(String title, String url) async {
    if (url.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url), headers: const {'Referer': 'https://olympustaff.com/'});
      if (response.statusCode < 400) {
        final dir = await getTemporaryDirectory();
        final safe = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
        final file = File('${dir.path}/cover_$safe.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (_) {}
    return null;
  }
}
