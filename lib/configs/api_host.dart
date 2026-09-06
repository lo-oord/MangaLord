/// Proxy settings

import 'package:flutter/material.dart';
import 'package:manga_lord/src/rust/copy_client/client.dart';

import '../src/rust/api/api.dart' as api;
import '../screens/components/commons.dart';

late String _currentApiHost;

Future<String?> initApiHost() async {
  _currentApiHost = await api.getApiHost();
  return null;
}

String currentApiHostName() {
  return _currentApiHost == "" ? "Not set" : _currentApiHost;
}

Future<dynamic> inputApiHost(BuildContext context) async {
  String? input = await displayTextInputDialog(
    context,
    src: _currentApiHost,
    title: 'Server',
    hint: 'Enter server address',
    desc: " ( For example https://domain.com ) ",
  );
  if (input != null) {
    await api.setApiHost(api: input);
    _currentApiHost = input;
  }
}

Widget apiHostSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return Column(
        children: [
          ListTile(
            title: const Text("Server address"),
            subtitle: Text(currentApiHostName()),
            onTap: () async {
              await inputApiHost(context);
              setState(() {});
            },
          ),
          ListTile(
            title: const Text("Sync server and request headers"),
            onTap: () async {
              try {
                String apiHost = await api.syncApiHost();
                _currentApiHost = apiHost;
                defaultToast(context, "Synchronized successfully");
              } catch (e, s) {
                print(e);
                print(s);
                defaultToast(context, "Synchronization failed");
              }
              setState(() {});
            },
          ),
          ListTile(
            title: const Text("View current request headers"),
            onTap: () async {
              List<CopyHeader> headers = await api.getAllHeaders();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Request headers"),
                  content: Text(
                      headers.map((e) => "${e.key}: ${e.value}").join("\n")),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
