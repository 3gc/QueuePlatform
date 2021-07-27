import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:queue_platform/data/const.dart';

import 'package:queue_platform/models/guild.dart';
import 'package:queue_platform/models/queue_entity.dart';

class QueueService {
  Future<List<Map<String, dynamic>>> getGuilds() async {
    try {
      var resp = await Dio().get('${server_url}/guilds');

      Map<dynamic, dynamic> response = resp.data;

      if (response.containsKey('data')) {
        if (response['data']['guilds'].isEmpty) {
          return [];
        }
        return (response['data']['guilds'] as List)
            .map((dynamic guild) => Map<String, dynamic>.from(guild))
            .toList();
      }
      return [];
    } catch (e) {
      // print(e.toString());
      return [];
    }
  }

  Future<EntityInfo> getEntities(String guild_id) async {
    EntityInfo empty = EntityInfo([], 0);
    try {
      var resp = await Dio().get('${server_url}/guild/${guild_id}/entities');

      Map<dynamic, dynamic> response = resp.data;

      if (response.containsKey('data')) {
        if (response['data']['entities'].isEmpty) {
          return empty;
        }
        var entities = (response['data']['entities'] as List)
            .map((dynamic entity) => Map<String, dynamic>.from(entity))
            .toList();
        return EntityInfo(entities.map((e) => QueueEntity.fromJson(e)).toList(),
            response['data']['total']);
      }
      return empty;
    } catch (e) {
      // print(e.toString());
      return empty;
    }
  }

  Future<Map<String, dynamic>> verifyKey(String key, String guild_id) async {
    try {
      var resp = await Dio()
          .get('${server_url}/check?key=${key}&guild_id=${guild_id}');
      var response = resp.data;
      if (!response.containsKey('data') ||
          !response['data'].containsKey('valid')) {
        return {};
      }
      return response;
    } catch (e) {
      // print(e.toString());
      return {};
    }
  }
}
