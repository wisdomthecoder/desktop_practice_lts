import 'dart:io';

import 'package:screen_retriever/screen_retriever.dart';
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:desktop_practice/controller.dart';
import 'package:desktop_practice/event_widget.dart';
import 'package:desktop_practice/share_pref.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  print('app$args');

  WidgetsFlutterBinding.ensureInitialized();
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument =
        args[2].isEmpty
            ? const {}
            : jsonDecode(args[2]) as Map<String, dynamic>;
    runApp(
      _ExampleSubWindow(
        windowController: WindowController.fromWindowId(windowId),
        args: argument,
      ),
    );
  } else {
    await WindowManager.instance.ensureInitialized();

    // await windowManager.setSize(Size(300, 300));
    await windowManager.setAlignment(Alignment.center);
    await windowManager.maximize();
    await windowManager.focus();

    await windowManager.setMinimizable(false);

    await windowManager.setTitle("Sacred Song of Solos");
  }
  runApp(const _ExampleMainWindow());
}

class _ExampleMainWindow extends StatefulWidget {
  const _ExampleMainWindow({Key? key}) : super(key: key);

  @override
  State<_ExampleMainWindow> createState() => _ExampleMainWindowState();
}

class _ExampleMainWindowState extends State<_ExampleMainWindow>
    with ScreenListener {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    screenRetriever.addListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          children: [
            TextButton(
              onPressed: () async {
                final subWindowIds =
                    await DesktopMultiWindow.getAllSubWindowIds();
                for (final windowId in subWindowIds) {
                  DesktopMultiWindow.invokeMethod(
                    windowId,
                    'updateData',
                    'Real-time data: ${DateTime.now()}',
                  );
                }
              },
              child: Text("Show"),
            ),
            TextButton(
              onPressed: () async {
                final window = await DesktopMultiWindow.createWindow(
                  jsonEncode({
                    'args1': 'Sub window',
                    'args2': 100,
                    'args3': true,
                    'business': 'business_test',
                  }),
                );
                window
                  ..setFrame(const Offset(0, 0) & const Size(1280, 720))
                  ..setTitle('Another window')
                  ..show();
              },
              child: const Text('Create a new World!'),
            ),

            TextButton(
              onPressed: () async {
                await screenRetriever.getAllDisplays().then((screens) async {
                  print(screens);
                  if (screens.length > 1) {
                    // Get the second screen's bounds
                    final secondScreen = screens[1];
                    final window = await DesktopMultiWindow.createWindow(
                      jsonEncode({
                        'args1': 'Sub window',
                        'args2': 100,
                        'args3': true,
                        'business': 'business_test',
                      }),
                    );
                    print(
                      (secondScreen.visiblePosition! &
                              secondScreen.visibleSize!)
                          .toString(),
                    );
                    window
                      ..setFrame(
                        secondScreen.visiblePosition! &
                            secondScreen.visibleSize!,
                      )
                      ..setTitle('Second Screen Window')
                      ..show();
                  } else {
                    // Fallback if only one screen is available
                    final window = await DesktopMultiWindow.createWindow(
                      jsonEncode({
                        'args1': 'Sub window',
                        'args2': 100,
                        'args3': true,
                        'business': 'business_test',
                      }),
                    );
                    window
                      ..setFrame(const Offset(0, 0) & const Size(1280, 720))
                      ..setTitle('Another window')
                      ..show();
                  }
                });
              },
              child: const Text('Create a new World on Second Screen!'),
            ),
            Expanded(
              child: EventWidget(controller: WindowController.fromWindowId(0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleSubWindow extends StatefulWidget {
  const _ExampleSubWindow({
    Key? key,
    required this.windowController,
    required this.args,
  }) : super(key: key);

  final WindowController windowController;
  final Map? args;

  @override
  State<_ExampleSubWindow> createState() => _ExampleSubWindowState();
}

class _ExampleSubWindowState extends State<_ExampleSubWindow>
    with ScreenListener {
  final _controller = StreamController<String?>();
  Timer? _timer;
  String? _lastValue;

  @override
  void initState() {
    super.initState();
    screenRetriever.addListener(this);
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == 'updateData') {
        final newData = call.arguments as String;
        _controller.add(newData); // Add new data to the stream
      }
    });
    SharedPrefsHelper().init();
  }

  viewOn2ndScreen() {
    screenRetriever.getAllDisplays().then((screens) async {
      var primaryDiplay = await screenRetriever.getPrimaryDisplay();
      screens.remove(primaryDiplay);
      print(screens);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: ElevatedButton(
            onPressed: () {
              viewOn2ndScreen();
            },
            child: Text("Vew On Monitor"),
          ),
        ),
        body: StreamBuilder<String?>(
          stream: _controller.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              return Center(child: Text(snapshot.data!));
            }
            return const Center(child: Text('No data received'));
          },
        ),
      ),
    );
  }
}
