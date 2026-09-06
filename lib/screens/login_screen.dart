import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:manga_lord/configs/login.dart';
import 'package:manga_lord/screens/components/content_loading.dart';

import '../src/rust/api/api.dart' as api;
import '../src/rust/udto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _username = "";
  late String _password = "";
  late String _token = "";

  @override
  void initState() {
    super.initState();
    loginEvent.subscribe(_setState);
    _loadProperties();
  }

  @override
  void dispose() {
    loginEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) {
    setState(() {});
  }

  Future _loadProperties() async {
    var username = await api.loadProperty(k: "username");
    var password = await api.loadProperty(k: "password");
    var token = await api.loadProperty(k: "token");
    setState(() {
      _username = username;
      _password = password;
      _token = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User settings"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (logging) {
      return const ContentLoading(label: "Processing");
    }
    if (loginState.state == 1) {
      return const Text("Logged in successfully");
    }
    return Column(children: [
      const Center(
        child: Text(
          "If login fails at startup, you can log in again with the previous token. The username and password fields are shared by the Register and Log in buttons.",
          style: TextStyle(fontSize: 20),
        ),
      ),
      Container(height: 50),
      ...(_token.isNotEmpty
          ? <Widget>[
              MaterialButton(
                onPressed: () async {
                  await initLogin();
                },
                child: const Text("Log in with the previous token"),
              ),
              Container(height: 50),
            ]
          : []),
      ListTile(
        title: const Text("Username"),
        subtitle: Text(_username),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            var username = await inputDialog(context, "Username", "Enter username");
            if (username != null) {
              setState(() {
                _username = username;
              });
            }
          },
        ),
      ),
      ListTile(
        title: const Text("Password"),
        subtitle: Text(_password),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            var password = await inputDialog(context, "Password", "Enter password");
            if (password != null) {
              setState(() {
                _password = password;
              });
            }
          },
        ),
      ),
      Container(height: 50),
      MaterialButton(
        onPressed: () async {
          await register(context, _username, _password);
        },
        child: const Text("Register"),
      ),
      Container(height: 50),
      MaterialButton(
        onPressed: () async {
          try {
            await login(_username, _password);
            _token = await api.loadProperty(k: "token");
          } catch (e, s) {
            log("$e\n$s");
          }
          setState(() {});
        },
        child: const Text("Log in with username and password"),
      ),
      Container(height: 50),
      Text(loginState.message, style: const TextStyle(color: Colors.red)),
    ]);
  }

  Future<String?> inputDialog(
      BuildContext context, String title, String label) async {
    var controller = TextEditingController();
    var result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return result;
  }
}
