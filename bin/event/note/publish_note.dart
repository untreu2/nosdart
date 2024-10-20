import 'dart:convert';
import 'dart:io';
import 'package:nostr/nostr.dart';

Future<void> broadcastEvent(String nsec, String content) async {
  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  Event newEvent = Event.from(
    kind: 1,
    tags: [],
    content: content,
    privkey: nsec,
  );

  String signedEventJson = jsonEncode(["EVENT", newEvent.toJson()]);

  print('Note signed and sent to relay: $signedEventJson');

  webSocket.add(signedEventJson);

  webSocket.listen((event) {
    print('Response from relay: $event');
  });

  await Future.delayed(Duration(seconds: 10));
  await webSocket.close();
  print('Connection closed.');
}

void main() async {
  String nsec = "HEX NSEC";

  String content = "dart!";

  await broadcastEvent(nsec, content);
}
