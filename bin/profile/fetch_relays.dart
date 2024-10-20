import 'dart:io';
import 'dart:convert';
import 'package:nostr/nostr.dart';

Future<void> fetchRelayListForNpub(String npub) async {
  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  var requestWithFilter = Request(generate64RandomHexChars(), [
    Filter(
      authors: [npub],
      kinds: [10002],
      limit: 1
    )
  ]);

  print('Requesting relay list...');

  webSocket.listen((event) {
    var decodedEvent = jsonDecode(event);
    print('Received event: $decodedEvent');

    if (decodedEvent[0] == "EVENT") {
      var eventData = decodedEvent[2];
      var tags = eventData['tags'] as List;

      print('--- Relay List ---');
      for (var tag in tags) {
        if (tag.isNotEmpty && tag[0] == 'r') {
          print('Relay: ${tag[1]}');
        }
      }
      print('---------------------\n');
    }
  });

  webSocket.add(requestWithFilter.serialize());

  await Future.delayed(Duration(seconds: 10));
  await webSocket.close();
  print('Connection closed.');
}

void main() async {
  String npub = "HEX NPUB";

  await fetchRelayListForNpub(npub);
}
