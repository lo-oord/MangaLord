import 'package:flutter/material.dart';
import 'components/flutter_search_bar_base.dart' as sb;
import '../src/rust/api/api.dart' as api;
import '../src/rust/udto.dart';
import 'components/comic_card.dart';
import 'components/comic_pager.dart';

class AuthorSearchScreen extends StatefulWidget {
  const AuthorSearchScreen({Key? key}) : super(key: key);

  @override
  _AuthorSearchScreenState createState() => _AuthorSearchScreenState();
}

class _AuthorSearchScreenState extends State<AuthorSearchScreen> {
  String _query = "";
  String _ordering = "-datetime_updated"; // Default sort by Recently updated

  late final _searchBar = sb.SearchBar(
    hintText: 'Search by author name',
    inBar: false,
    setState: setState,
    onSubmitted: (value) {
      setState(() {
        _query = value;
      });
    },
    buildDefaultAppBar: _appBar,
  );

  AppBar _appBar(BuildContext context) {
    return AppBar(
      title: Text(_query.isEmpty ? "Search by author name" : _query),
      actions: [
        if (_query.isNotEmpty)
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _ordering = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: "-datetime_updated",
                child: Text("Recently updated"),
              ),
              const PopupMenuItem(
                value: "datetime_updated",
                child: Text("Oldest updates"),
              ),
              const PopupMenuItem(
                value: "-popular",
                child: Text("Most popular"),
              ),
              const PopupMenuItem(
                value: "popular",
                child: Text("Least popular"),
              ),
            ],
          ),
        _searchBar.getSearchAction(context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searchBar.build(context),
      body: _query.isEmpty
          ? const Center(
              child: Text(
                "Enter an author name to search",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ComicPager(
              key: Key("author_search:$_query:$_ordering"),
              fetcher: (offset, limit) async {
                final result = await api.exploreByAuthorName(
                  authorName: _query,
                  ordering: _ordering,
                  offset: offset,
                  limit: limit,
                );
                return CommonPage<CommonComicInfo>(
                  list: result.list
                      .map((e) => CommonComicInfo(
                            author: e.author,
                            cover: e.cover,
                            imgType: 1,
                            name: e.name,
                            pathWord: e.pathWord,
                            popular: e.popular.toInt(),
                            males: e.males,
                            females: e.females,
                          ))
                      .toList(),
                  total: result.total,
                  limit: result.limit,
                  offset: result.offset,
                );
              },
            ),
    );
  }
}
