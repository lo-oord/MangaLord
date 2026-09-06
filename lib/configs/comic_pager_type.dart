import 'package:flutter/material.dart';
import 'package:event/event.dart';
import '../src/rust/api/api.dart' as api;

enum ComicPagerType {
  grid, // Multi-column grid
  list, // Details list
}

const _propertyName = "comic_pager_type";

ComicPagerType _comicPagerType = ComicPagerType.grid;

ComicPagerType get currentComicPagerType => _comicPagerType;

class ComicPagerTypeEventArgs extends EventArgs {
  final ComicPagerType type;
  ComicPagerTypeEventArgs(this.type);
}

final Event<ComicPagerTypeEventArgs> comicPagerTypeEvent = Event<ComicPagerTypeEventArgs>();

Future initComicPagerType() async {
  var value = await api.loadProperty(k: _propertyName);
  if (value == null || value.isEmpty) {
    _comicPagerType = ComicPagerType.grid;
  } else {
    _comicPagerType = ComicPagerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComicPagerType.grid,
    );
  }
  comicPagerTypeEvent.broadcast(ComicPagerTypeEventArgs(_comicPagerType));
}

Future chooseComicPagerType(BuildContext context) async {
  var result = await showDialog<ComicPagerType>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xAA000000),
        title: const Text(
          "Choose manga list layout",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                "Multi-column grid",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop(ComicPagerType.grid);
              },
            ),
            ListTile(
              title: const Text(
                "Details list",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop(ComicPagerType.list);
              },
            ),
          ],
        ),
      );
    },
  );
  if (result != null) {
    await api.saveProperty(k: _propertyName, v: result.name);
    _comicPagerType = result;
    comicPagerTypeEvent.broadcast(ComicPagerTypeEventArgs(_comicPagerType));
  }
}

String comicPagerTypeName(ComicPagerType type, BuildContext context) {
  switch (type) {
    case ComicPagerType.grid:
      return "Multi-column grid";
    case ComicPagerType.list:
      return "Details list";
  }
}

Widget comicPagerTypeSetting(BuildContext context) {
  return ListTile(
    title: const Text(
      "Manga list layout",
    ),
    subtitle: Text(
      comicPagerTypeName(currentComicPagerType, context),
    ),
    onTap: () => chooseComicPagerType(context),
  );
}
