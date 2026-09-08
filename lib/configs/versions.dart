import 'dart:async' show Future;
import 'dart:convert';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../src/rust/api/api.dart' as api;
import '../../src/rust/udto.dart';
import '../screens/components/commons.dart';

const _versionUrl = 'https://api.github.com/repos/lo-oord/MangaLord/releases/latest';
const _versionAssets = 'lib/assets/version.txt';
final _versionExp = RegExp(r'^v\d+\.\d+\.\d+$');
late String _version;
String? _latestVersion;
String? _latestVersionInfo;

Future initVersion() async {
  try { _version = (await rootBundle.loadString(_versionAssets)).trim(); } catch (_) { _version = 'dirty'; }
}
var versionEvent = Event<EventArgs>();
String currentVersion() => _version;
String? get latestVersion => _latestVersion;
String? latestVersionInfo() => _latestVersionInfo;
Future autoCheckNewVersion() => _versionCheck();
Future manualCheckNewVersion(BuildContext context) async {
  try { defaultToast(context, 'Checking for updates'); await _versionCheck(); defaultToast(context, 'Update check completed'); } catch (e) { defaultToast(context, 'Update check failed: $e'); }
}
bool dirtyVersion() => !_versionExp.hasMatch(_version);

Future _versionCheck() async {
  if (_versionExp.hasMatch(_version)) {
    final json = jsonDecode(await api.httpGet(url: _versionUrl));
    final rawLatest = json is Map ? '${json['tag_name'] ?? ''}' : '';
    final normalizedLatest = rawLatest.startsWith('v') ? rawLatest : 'v$rawLatest';
    if (_versionExp.hasMatch(normalizedLatest) && _isNewer(normalizedLatest, _version)) {
      _latestVersion = normalizedLatest;
      _latestVersionInfo = json['body'] as String? ?? '';
    }
  }
  versionEvent.broadcast();
}

bool _isNewer(String candidate, String current) {
  List<int> parse(String value) => value.substring(1).split('.').map(int.parse).toList();
  final next = parse(candidate);
  final old = parse(current);
  for (var index = 0; index < 3; index++) { if (next[index] != old[index]) return next[index] > old[index]; }
  return false;
}
