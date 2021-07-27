import 'package:get_it/get_it.dart';
import 'package:queue_platform/data/queue_service.dart';
import 'package:queue_platform/models/guild.dart';
import 'package:queue_platform/models/queue_entity.dart';

class QueueViewModel {
  // Each guild contains a queue object, and every
  // Queue object contains a list of QueueEntities

  Future<List<Guild>> getGuilds() async {
    var guilds = await GetIt.I<QueueService>().getGuilds();
    return guilds.map((guild) => Guild.fromJson(guild)).toList();
  }

  Future<EntityInfo> getEntities(String guild_id) async {
    return await GetIt.I<QueueService>().getEntities(guild_id);
  }

  Future<bool> verifyKey(String key, String guild_id) async {
    var response = await GetIt.I<QueueService>().verifyKey(key, guild_id);

    return response['data']['valid'] == true;
  }
}
