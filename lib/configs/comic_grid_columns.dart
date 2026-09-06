import 'package:flutter/material.dart';
import 'package:event/event.dart';
import '../src/rust/api/api.dart' as api;

const _minColumns = 2;
const _maxColumns = 10;
const _propertyName = "comic_grid_columns";

late int _comicGridColumns = 3; // Default: 3 columns

int get currentComicGridColumns => _comicGridColumns;

class ComicGridColumnsEventArgs extends EventArgs {
  final int columns;
  ComicGridColumnsEventArgs(this.columns);
}

final Event<ComicGridColumnsEventArgs> comicGridColumnsEvent = Event<ComicGridColumnsEventArgs>();

Future initComicGridColumns() async {
  var value = await api.loadProperty(k: _propertyName);
  if (value == null || value.isEmpty) {
    await api.saveProperty(k: _propertyName, v: _comicGridColumns.toString());
  } else {
    var columns = int.tryParse(value) ?? _comicGridColumns;
    // Ensure the column count is within the valid range
    columns = columns.clamp(_minColumns, _maxColumns);
    _comicGridColumns = columns;
  }
  comicGridColumnsEvent.broadcast(ComicGridColumnsEventArgs(_comicGridColumns));
}

Future chooseComicGridColumns(BuildContext context) async {
  var result = await showDialog<int>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xAA000000),
        title: const Text(
          "Choose grid columns",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = _minColumns; i <= _maxColumns; i++)
              ListTile(
                title: Text(
                  "$i columns",
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop(i);
                },
              ),
          ],
        ),
      );
    },
  );
  if (result != null) {
    await api.saveProperty(k: _propertyName, v: result.toString());
    _comicGridColumns = result;
    comicGridColumnsEvent.broadcast(ComicGridColumnsEventArgs(_comicGridColumns));
  }
}

Widget comicGridColumnsSetting(BuildContext context) {
  return ListTile(
    title: const Text(
      "Grid columns",
    ),
    subtitle: Text(
      "${currentComicGridColumns} columns",
    ),
    onTap: () => chooseComicGridColumns(context),
  );
}
