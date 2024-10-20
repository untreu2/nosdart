import 'dart:io';
import 'dart:convert';
import 'package:nostr/nostr.dart';

Future<void> fetchProfileForNpub(String npub) async {
  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  var requestWithFilter = Request(generate64RandomHexChars(), [
    Filter(
      authors: [npub],
      kinds: [0],
      limit: 1
    )
  ]);

  print('Requesting profile data...');

  webSocket.listen((event) {
    var decodedEvent = jsonDecode(event);

    print('Received event: $decodedEvent');

    if (decodedEvent[0] == "EVENT") {
      var eventData = decodedEvent[2];
      var kind = eventData['kind'];

      if (kind == 0) {
        var profileContent = jsonDecode(eventData['content']);
        print('--- Profile Information ---');
        print('Name: ${profileContent['name']}');
        print('Bio: ${profileContent['about']}');
        print('Profile Picture: ${profileContent['picture']}');
        print('Banner: ${profileContent['banner']}');
        print('Lightning Address: ${profileContent['lud06'] ?? profileContent['lud16']}');
        print('------------------------\n');
      }
    }
  });

  webSocket.add(requestWithFilter.serialize());

  await Future.delayed(Duration(seconds: 10));
  await webSocket.close();
  print('Connection closed.');
}

void main() async {
  String npub = "HEX NPUB";

  await fetchProfileForNpub(npub);
}
