import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:queue_platform/data/queue_service.dart';
import 'package:queue_platform/data/queue_vm.dart';
import 'package:queue_platform/models/guild.dart';
import 'package:queue_platform/views/home.dart';

class PageLoader extends StatefulWidget {
  const PageLoader({Key? key}) : super(key: key);

  @override
  _PageLoaderState createState() => _PageLoaderState();
}

class _PageLoaderState extends State<PageLoader> {
  late Future future;

  @override
  void initState() {
    super.initState();
    setState(() {
      future = QueueViewModel().getGuilds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: future,
        builder: (BuildContext context, snapshot) {
          if (snapshot.hasData) {
            List<Guild> data = snapshot.data as List<Guild>;
            Widget no_active =
                Center(child: Text('There are no active queues.'));

            if (data.isEmpty) {
              return no_active;
            }

            if (data.length == 1) {
              if (data[0].entities <= 0) {
                return no_active;
              }
              return HomePage(data[0]);
            }
            return Center(
              child: Text('Pick the queue:'),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('An error has accured.\nPlease refresh.'),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
