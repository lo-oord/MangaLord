import 'package:manga_lord/configs/app_orientation.dart';
import 'package:manga_lord/configs/app_theme.dart';
import 'package:manga_lord/configs/comic_grid_columns.dart';
import 'package:manga_lord/configs/comic_pager_type.dart';
import 'package:manga_lord/configs/list_volume.dart';
import 'package:manga_lord/configs/login.dart';
import 'package:manga_lord/configs/no_pager_animation.dart';
import 'package:manga_lord/configs/proxy.dart';
import 'package:manga_lord/configs/reader_controller_type.dart';
import 'package:manga_lord/configs/reader_direction.dart';
import 'package:manga_lord/configs/reader_slider_position.dart';
import 'package:manga_lord/configs/reader_type.dart';
import 'package:manga_lord/configs/versions.dart';

import 'api_host.dart';
import 'cache_time.dart';
import 'chapter_order_newest.dart';
import 'collect_ordering.dart';

Future initConfigs() async {
  await initAppOrientation();
  await initAppTheme();
  await initApiHost();
  await initProxy();
  await initCacheTime();
  await initReaderControllerType();
  await initReaderDirection();
  await initReaderSliderPosition();
  await initReaderType();
  await initLogin();
  await initVersion();
  await initNoPagerAnimation();
  await initChapterOrderNewest();
  await initComicPagerType();
  await initComicGridColumns();
  await initListVolume();
  autoCheckNewVersion();
}
