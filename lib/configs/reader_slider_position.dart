import 'package:flutter/material.dart';

import '../src/rust/api/api.dart' as api;
import '../screens/components/commons.dart';

enum ReaderSliderPosition {
  bottom,
  right,
  left,
}

const _positionNames = {
  ReaderSliderPosition.bottom: 'Bottom',
  ReaderSliderPosition.right: 'Right',
  ReaderSliderPosition.left: 'Left',
};

const _propertyName = "reader_slider_position";
late ReaderSliderPosition _readerSliderPosition;

Future initReaderSliderPosition() async {
  _readerSliderPosition = _readerSliderPositionFromString(
    await api.loadProperty(k: _propertyName),
  );
}

ReaderSliderPosition _readerSliderPositionFromString(String str) {
  for (var value in ReaderSliderPosition.values) {
    if (str == value.toString()) return value;
  }
  return ReaderSliderPosition.bottom;
}

ReaderSliderPosition get currentReaderSliderPosition => _readerSliderPosition;

String get currentReaderSliderPositionName =>
    _positionNames[_readerSliderPosition] ?? "";

Future<void> chooseReaderSliderPosition(BuildContext context) async {
  Map<String, ReaderSliderPosition> map = {};
  _positionNames.forEach((key, value) {
    map[value] = key;
  });
  ReaderSliderPosition? result = await chooseMapDialog<ReaderSliderPosition>(
    context,
    title: "Choose slider position",
    values: map,
  );
  if (result != null) {
    await api.saveProperty(k: _propertyName, v: result.toString());
    _readerSliderPosition = result;
  }
}
