import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue_platform/data/common_state.dart';
import 'package:queue_platform/data/queue_service.dart';
import 'package:queue_platform/views/home.dart';

import 'package:get_it/get_it.dart';
import 'package:queue_platform/views/loader.dart';

void setupServices() {
  GetIt.I.registerLazySingleton<QueueService>(() => QueueService());
}

void main() {
  setupServices();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        lazy: false,
        create: (_) => CommonState(),
      )
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'QueuePlatform',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.grey,
        ),
        home: PageLoader());
  }
}
