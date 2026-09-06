import 'package:flutter/material.dart';

import '../../src/rust/api/api.dart' as api;
import '../../src/rust/udto.dart';
import '../screens/components/commons.dart';

const _propertyName = "listVolume";
late bool _listVolume;

Future initListVolume() async {
  _listVolume = false;
  final st = await api.loadProperty(k: _propertyName);
  if (st.isNotEmpty) {
    try {
      _listVolume = bool.parse(st);
    } catch (e) {}
  }
}

bool get currentListVolume => _listVolume;

Future chooseListVolume(BuildContext context) async {
  final Map<String, bool> map = {};
  map["Yes"] = true;
  map["No"] = false;
  final newListVolume = await chooseMapDialog(
    context,
    title: "Enable volume-button page turning",
    values: map,
  );
  if (newListVolume != null) {
    await api.saveProperty(k: _propertyName, v: "$newListVolume");
    _listVolume = newListVolume;
  }
}

Widget listVolumeSwitch() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return SwitchListTile(
        title: const Text("Volume-button page turning enabled"),
        value: currentListVolume,
        onChanged: (value) async {
          await api.saveProperty(k: _propertyName, v: "$value");
          setState(() {
            _listVolume = value;
          });
        },
      );
    },
  );
}
