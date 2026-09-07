import 'package:flutter/material.dart';
import '../src/rust/api/api.dart' as api;
import '../src/rust/udto.dart';
import 'components/comic_pager.dart';

/// Displays manga ordered by the source's creation timestamp.
///
/// This deliberately uses the existing explorer endpoint instead of a
/// recommendation feed or local browsing history. The server performs the
/// ordering with its real catalog data, so newly added manga appear first
/// without treating a newly released chapter as a newly added manga.
class LatestAddedScreen extends StatelessWidget {
  const LatestAddedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComicPager(
      fetcher: (offset, limit) async {
        final result = await api.explorer(
          ordering: '-datetime_created',
          offset: offset,
          limit: limit,
        );
        return CommonPage<CommonComicInfo>(
          list: result.list
              .map(
                (comic) => CommonComicInfo(
                  author: comic.author,
                  cover: comic.cover,
                  imgType: 1,
                  name: comic.name,
                  pathWord: comic.pathWord,
                  popular: comic.popular,
                  males: comic.males,
                  females: comic.females,
                ),
              )
              .toList(),
          total: result.total,
          limit: result.limit,
          offset: result.offset,
        );
      },
    );
  }
}
