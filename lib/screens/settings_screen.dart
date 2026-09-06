import 'dart:io';

import 'package:flutter/material.dart';
import 'package:manga_lord/configs/api_host.dart';
import 'package:manga_lord/configs/app_orientation.dart';
import 'package:manga_lord/configs/app_theme.dart';
import 'package:manga_lord/configs/chapter_order_newest.dart';
import 'package:manga_lord/configs/collect_ordering.dart';
import 'package:manga_lord/configs/comic_grid_columns.dart';
import 'package:manga_lord/configs/comic_pager_type.dart';
import 'package:manga_lord/configs/list_volume.dart';
import 'package:manga_lord/configs/no_pager_animation.dart';

import '../configs/cache_time.dart';
import '../configs/proxy.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          appThemeSetting(context),
          apiHostSetting(),
          proxySetting(),
          cacheTimeNameSetting(),
          appOrientationWidget(),
          noPagerAnimationSwitch(),
          comicPagerTypeSetting(context),
          comicGridColumnsSetting(context),
          chapterOrderNewestSwitch(),
          if (Platform.isAndroid) listVolumeSwitch(),
        ],
      ),
    );
  }
}
