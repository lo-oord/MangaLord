import 'package:flutter/material.dart';
import 'package:manga_lord/configs/login.dart';
import 'package:manga_lord/src/rust/api/api.dart';
import 'package:manga_lord/screens/components/comic_pager.dart';
import 'package:manga_lord/screens/components/comic_card.dart';

class BrowserComicsAccountScreen extends StatefulWidget {
  const BrowserComicsAccountScreen({Key? key}) : super(key: key);

  @override
  State<BrowserComicsAccountScreen> createState() => _BrowserComicsAccountScreenState();
}

class _BrowserComicsAccountScreenState extends State<BrowserComicsAccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reading history"),
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
    return _buildBody1();
  }

  Widget _buildBody1() {
    return Column(
      children: [
        Expanded(
          child: _comicPager(),
        ),
      ],
    );
  }

  Widget _comicPager() {
    return ComicPager(
      key: const Key("browser_comics_account"),
      pageSize: 18,
      fetcher: (offset, limit) async {
        final result = await browser(
          offset: offset,
          limit: limit,
        );
        return CommonPage<CommonComicInfo>(
          list: result.list.map((e) => CommonComicInfo(
            author: e.comic.author, // Browse Model has has no author information
            cover: e.comic.cover, // use pathWord as the cover placeholder
            imgType: 1,
            name: e.comic.name,
            pathWord: e.comic.pathWord,
            popular: e.comic.popular, // Browse Model has has no popularity information
            males: e.comic.males, // Browse Model has has no gender information
            females: e.comic.females, // Browse Model has has no gender information
          )).toList(),
          total: result.total.toInt(),
          limit: result.limit.toInt(),
          offset: result.offset.toInt(),
        );
      },
    );
  }
}
