/// Full-screen controls

import 'package:flutter/material.dart';

import '../../src/rust/api/api.dart' as api;
import '../../src/rust/udto.dart';
import '../screens/components/commons.dart';

enum ReaderControllerType {
  touchOnce,
  controller,
  touchDouble,
  touchDoubleOnceNext,
  threeArea,
}

Map<String, ReaderControllerType> _readerControllerTypeMap = {
  "Tap the screen once for full screen": ReaderControllerType.touchOnce,
  "Use the controller for full screen": ReaderControllerType.controller,
  "Double-tap the screen for full screen": ReaderControllerType.touchDouble,
  "Double-tap for full screen + single-tap for next page": ReaderControllerType.touchDoubleOnceNext,
  "Divide the screen into three areas (previous page, next page, full screen)": ReaderControllerType.threeArea,
};

const _defaultController = ReaderControllerType.touchOnce;
const _propertyName = "reader_controller_type";
late ReaderControllerType _readerControllerType;

Future<void> initReaderControllerType() async {
  _readerControllerType = _readerControllerTypeFromString(
    await api.loadProperty(k: _propertyName),
  );
}

ReaderControllerType get currentReaderControllerType => _readerControllerType;

ReaderControllerType _readerControllerTypeFromString(String string) {
  for (var value in ReaderControllerType.values) {
    if (string == value.toString()) {
      return value;
    }
  }
  return _defaultController;
}

String currentReaderControllerTypeName() {
  for (var e in _readerControllerTypeMap.entries) {
    if (e.value == _readerControllerType) {
      return e.key;
    }
  }
  return '';
}

Future<void> chooseReaderControllerType(BuildContext context) async {
  ReaderControllerType? result = await chooseMapDialog<ReaderControllerType>(
    context,
    title: "Choose control method",
    values: _readerControllerTypeMap,
  );
  if (result != null) {
    await api.saveProperty(k: _propertyName, v: result.toString());
    _readerControllerType = result;
  }
}
