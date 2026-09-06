import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:manga_lord/screens/components/comic_pager.dart';

import '../configs/collect_ordering.dart';
import '../configs/login.dart';
import '../src/rust/api/api.dart' as api;
import 'components/comic_card.dart';

const _sortMap = {
  "-datetime_modifier": "Newest favorites",
  "datetime_modifier": "Oldest favorites",
  "-datetime_updated": "Newest updates",
  "datetime_updated": "Oldest updates",
};

class CollectedComicsAccountScreen extends StatefulWidget {
  const CollectedComicsAccountScreen({Key? key}) : super(key: key);

  @override
  _CollectedComicsAccountScreenState createState() =>
      _CollectedComicsAccountScreenState();
}

class _CollectedComicsAccountScreenState
    extends State<CollectedComicsAccountScreen> {
  String _sort = _sortMap.keys.first;

  @override
  void initState() {
    super.initState();
    loginEvent.subscribe(_setState);
  }

  @override
  void dispose() {
    loginEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites (Account)"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return _sortMap.entries
                  .map((e) => PopupMenuItem<String>(
                        value: e.key,
                        child: Row(
                          children: [
                            if (e.key == _sort)
                              const Icon(Icons.check_box)
                            else
                              const Icon(Icons.check_box_outline_blank),
                            Container(width: 10),
                            Text(e.value),
                          ],
                        ),
                      ))
                  .toList();
            },
            child: Container(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                _sortMap[_sort] ?? "UNKNOWN",
                style: const TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (logging) {
      return const Center(child: Text("Processing"));
    }
    if (loginState.state == 0) {
      return const Center(child: Text("Not logged in"));
    }
    if (loginState.state == 2) {
      return const Center(child: Text("Login failed"));
    }
    return Column(children: [
      Expanded(child: _comicPager()),
    ]);
  }

  Widget _comicPager() {
    return ComicPager(
      key: Key("collected_comics_account:$_sort"),
      fetcher: (offset, limit) async {
        final result = await api.collectFromAccount(
          freeType: 1,
          ordering: _sort,
          offset: offset,
          limit: limit,
        );
        return CommonPage<CommonComicInfo>(
          list: result.list
              .map((e) => CommonComicInfo(
                    author: e.comic.author,
                    cover: e.comic.cover,
                    imgType: 1,
                    name: e.comic.name,
                    pathWord: e.comic.pathWord,
                    popular: e.comic.popular,
                    males: e.comic.males,
                    females: e.comic.females,
                  ))
              .toList(),
          total: result.total,
          limit: result.limit,
          offset: result.offset,
        );
      },
    );
  }
}
