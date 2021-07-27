import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue_platform/data/common_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

import 'package:queue_platform/data/queue_vm.dart';
import 'package:queue_platform/models/guild.dart';
import 'package:queue_platform/views/queue_view.dart';

class HomePage extends StatefulWidget {
  Guild guild;
  HomePage(this.guild, {Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _textEditingController = TextEditingController();
  bool used_field = true;

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Provider.of<CommonState>(context, listen: false)
          .setEntities(widget.guild.entities);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool is_wide = MediaQuery.of(context).size.width > 600;
    double side_width = MediaQuery.of(context).size.width * 0.1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Flex(
        direction: is_wide ? Axis.horizontal : Axis.vertical,
        children: [
          Container(
            alignment: Alignment.topCenter,
            margin: EdgeInsets.only(
                top: side_width, right: side_width, left: side_width / 2),
            child: Container(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Tooltip(
                      message: 'Name of the guild',
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          widget.guild.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Amount of entities in the queue',
                      child: Consumer<CommonState>(
                        builder: (_, state, __) {
                          return Text(
                            'Queue length: ${state.entities}',
                            style: TextStyle(),
                          );
                        },
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxWidth: side_width, maxHeight: 50),
                      ),
                    )
                  ],
                )),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: side_width / 2),
                  child: Column(
                    children: [
                      Text('Queue'),
                      Divider(),
                    ],
                  ),
                ),
                Expanded(
                  child: QueueView(widget.guild),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            margin: EdgeInsets.all(side_width),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Information'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(Icons.info),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('QueuePlatform'),
                                content: Container(
                                  constraints: BoxConstraints(maxHeight: 100),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                            'This is a platform for handling queues.\nDeveloped by awking\n'),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                launch(
                                                    'https://github.com/3gc/');
                                              },
                                              icon: Icon(Icons.source)),
                                          Text('Source code')
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('close'))
                                ],
                              );
                            });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.vpn_key),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                content: Container(
                                  constraints: BoxConstraints(maxHeight: 100),
                                  child: Column(
                                    children: [
                                      Text(
                                          'Input the key, provided you are a guild owner\nof an authorized guild.'),
                                      TextField(
                                        controller: _textEditingController,
                                        textInputAction: TextInputAction.go,
                                        decoration:
                                            InputDecoration(hintText: 'key'),
                                        onSubmitted: (value) {
                                          String guess =
                                              _textEditingController.text;
                                          QueueViewModel()
                                              .verifyKey(guess, widget.guild.id)
                                              .then((value) {
                                            setState(() {
                                              _textEditingController.clear();

                                              if (value)
                                                widget.guild = Guild(
                                                    widget.guild.id,
                                                    widget.guild.name,
                                                    widget.guild.entities,
                                                    key: guess);
                                            });
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Close'))
                                ],
                              );
                            });
                      },
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
