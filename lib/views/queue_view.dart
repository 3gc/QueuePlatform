import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:queue_platform/data/common_state.dart';
import 'package:queue_platform/data/const.dart';
import 'package:queue_platform/data/queue_vm.dart';
import 'package:queue_platform/models/guild.dart';
import 'package:queue_platform/models/queue_entity.dart';
import 'package:universal_html/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const int MAX_LIMIT = 20;
const int FETCH_LIMIT = 10;

class QueueView extends StatefulWidget {
  final Guild guild;
  late final bool is_key;
  late final WebSocketChannel channel;
  List<QueueEntity> entities = [];
  QueueView(this.guild) {
    is_key = guild.key != null;

    if (is_key) {
      channel = WebSocketChannel.connect(
          Uri.parse('$ws_url/ws?guild_id=${guild.id}&key=${guild.key}'));
    }
  }

  @override
  _QueueViewState createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  List<QueueEntity> entities = [];
  late Future future;

  _QueueViewState() {}

  @override
  void didUpdateWidget(QueueView old) {
    Provider.of<CommonState>(context, listen: false)
        .setConnected(widget.is_key);
    if (widget.is_key) {
      wsConnection();
    }
  }

  @override
  void dipose() {
    super.dispose();
    if (widget.is_key) {
      widget.channel.sink.close();
    }
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      future = helperGetEntities();
    });
  }

  void wsDisconnected() {
    setState(() {
      widget.is_key = false;
      Provider.of<CommonState>(context, listen: false).setConnected(false);
    });
  }

  void wsConnection() {
    widget.channel.stream.listen(
      (data) {
        var event = jsonDecode(data);

        if (event['event'] == 'remove') {
          remove(
            event['target'],
          );
        } else if (event['event'] == 'add') {
          setState(
            () {
              Provider.of<CommonState>(context, listen: false).entitiesIncr();
              if (entities.length < MAX_LIMIT) {
                entities.add(
                  QueueEntity.fromJson(
                    Map<String, dynamic>.from(event),
                  ),
                );
              }
            },
          );
        } else if (event['event'] == 'clear') {
          setState(
            () {
              Provider.of<CommonState>(context, listen: false).setEntities(0);
              entities.clear();
            },
          );
        }
      },
      onDone: wsDisconnected,
      onError: (_) => wsDisconnected(),
    );
  }

  Future<EntityInfo> helperGetEntities() async {
    EntityInfo info = await QueueViewModel().getEntities(widget.guild.id);
    entities = info.entities;
    return info;
  }

  void remove(String id) {
    Provider.of<CommonState>(context, listen: false).entitiesDecr();
    setState(() {
      entities.removeWhere((element) => element.id == id);
    });
    if (entities.length <= FETCH_LIMIT) {
      helperGetEntities()
          .then((value) => setEntities(value.entities, amount: value.total));
    }
  }

  void setEntities(List<QueueEntity> value, {int? amount}) {
    Provider.of<CommonState>(context, listen: false)
        .setEntities(amount != null ? amount : value.length);
    setState(() {
      if (value.length == 0) {
        entities = [];
      } else if (value.length > MAX_LIMIT) {
        entities = value.sublist(0, value.length);
      } else {
        entities = value;
      }
    });
  }

  void processDeletion(QueueEntity entity) {
    if (widget.is_key) {
      widget.channel.sink
          .add(jsonEncode({"event": "remove", "target": entity.id}));

      remove(entity.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return Container(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            helperGetEntities().then((value) => setEntities(
                                value.entities,
                                amount: value.total));
                          });
                        },
                        child: Container(
                          child: Text('Refresh'),
                        ),
                      ),
                      // only visible if user authenticated through key
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          widget.is_key ? Icon(Icons.wifi) : SizedBox.shrink(),
                          widget.is_key
                              ? TextButton(
                                  style: ButtonStyle(),
                                  onPressed: () {},
                                  child: Container(
                                    child: Text(
                                      'Live connection to the server.',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ),
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: entities.length <= 0
                      ? Container(
                          child: Text(
                            'The queue is empty',
                            style: TextStyle(fontSize: 20),
                          ),
                        )
                      : ListView.builder(
                          itemCount: entities.length,
                          itemBuilder: (context, index) {
                            QueueEntity entity = entities[index];
                            return Container(
                              child: Card(
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.topRight,
                                      child: widget.guild.key != null
                                          ? IconButton(
                                              onPressed: () =>
                                                  processDeletion(entity),
                                              icon: Icon(Icons.close),
                                            )
                                          : Container(),
                                    ),
                                    ListTile(
                                      subtitle: Text('Tier ${entity.tier}'),
                                      leading: Tooltip(
                                        child: Text((index + 1).toString()),
                                        message: 'Position',
                                      ),
                                      title: Text(entity.value),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
