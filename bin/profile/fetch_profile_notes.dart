import 'dart:io';
import 'dart:convert';
import 'package:nostr/nostr.dart';

Future<void> fetchNotesForNpub(String npub) async {
  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  var requestWithFilter = Request(generate64RandomHexChars(), [
    Filter(
      authors: [npub],
      kinds: [1],
      limit: 10
    )
  ]);

  print('Requesting note data...');

  webSocket.listen((event) {
    var decodedEvent = jsonDecode(event);

    print('Received event: $decodedEvent');

    if (decodedEvent[0] == "EVENT") {
      var eventData = decodedEvent[2];
      var kind = eventData['kind'];

      if (kind == 1) {
        print('--- Note ---');
        print('Content: ${eventData['content']}');
        print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(eventData['created_at'] * 1000)}');
        print('------------------------\n');
      }
    }
  });

  webSocket.add(requestWithFilter.serialize());

  await Future.delayed(Duration(seconds: 15));
  await webSocket.close();
  print('Connection closed.');
}

void main() async {
  String npub = "HEX NPUB";
  await fetchNotesForNpub(npub);
}
