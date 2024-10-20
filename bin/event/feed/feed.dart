import 'dart:io';
import 'dart:convert';
import 'package:nostr/nostr.dart';

Future<List<String>> getFollowingList(String npub) async {
  var requestWithFilter = Request(generate64RandomHexChars(), [
    Filter(
      authors: [npub], 
      kinds: [3],      
      limit: 1,        
    )
  ]);

  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  List<String> followingNpubs = [];

  webSocket.listen((event) {
    var message = Message.deserialize(event);
    if (message.type == 'EVENT' && message.message.kind == 3) {
      for (var tag in message.message.tags) {
        if (tag.isNotEmpty && tag[0] == 'p') {
          followingNpubs.add(tag[1]);
        }
      }
    }
  });

  webSocket.add(requestWithFilter.serialize());

  await Future.delayed(Duration(seconds: 3));
  await webSocket.close();

  return followingNpubs;
}

Future<void> fetchFeedForFollowingNpubs(List<String> followingNpubs) async {
  if (followingNpubs.isEmpty) {
    print("No users found.");
    return;
  }

  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  var requestWithFilter = Request(generate64RandomHexChars(), [
    Filter(
      authors: followingNpubs, 
      kinds: [1],              
      limit: 10,               
    )
  ]);

  webSocket.listen((event) {
    var decodedEvent = jsonDecode(event);

    if (decodedEvent[0] == "EVENT") {
      var eventData = decodedEvent[2];
      print('--- Event ---');
      print('Author: ${eventData['pubkey']}');
      print('Content: ${eventData['content']}');
      print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(eventData['created_at'] * 1000)}');
      print('------------------\n');
    }
  });

  webSocket.add(requestWithFilter.serialize());

  await Future.delayed(Duration(seconds: 10));
  await webSocket.close();
}

void main() async {
  String npub = "NPUB HEX";

  List<String> followingNpubs = await getFollowingList(npub);

  await fetchFeedForFollowingNpubs(followingNpubs);
}
