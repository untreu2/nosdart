import 'dart:io';
import 'dart:convert';
import 'package:nostr/nostr.dart';
import 'package:convert/convert.dart';
import 'package:bech32/bech32.dart';

String nip19ToHex(String nip19Id) {
  var decoded = Bech32Decoder().convert(nip19Id);
  var data = decoded.data;
  var hexString = hex.encode(data);
  return hexString;
}

Future<void> fetchInteractionsForNoteId(String nip19NoteId) async {
  String noteId = nip19ToHex(nip19NoteId);

  WebSocket webSocket = await WebSocket.connect('wss://relay.damus.io');

  var requestWithFilter = Request(generate64RandomHexChars(), [
    Filter(
      kinds: [1, 7, 9735],
      limit: 50,
    )
  ]);

  print('Request sent...');

  webSocket.listen((event) {
    var decodedEvent = jsonDecode(event);
    print('Received event: $decodedEvent');

    if (decodedEvent[0] == "EVENT") {
      var eventData = decodedEvent[2];
      var kind = eventData['kind'];
      var tags = eventData['tags'] as List;

      bool isRelatedToNote = tags.any((tag) => tag[0] == 'e' && tag[1] == noteId);

      if (isRelatedToNote) {
        if (kind == 1) {
          print('--- Reply ---');
          print('Author: ${eventData['pubkey']}');
          print('Content: ${eventData['content']}');
          print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(eventData['created_at'] * 1000)}');
          print('------------------\n');
        } else if (kind == 7) {
          print('--- Reaction ---');
          print('Author: ${eventData['pubkey']}');
          print('Reaction: ${eventData['content']}');
          print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(eventData['created_at'] * 1000)}');
          print('------------------\n');
        } else if (kind == 9735) {
          print('--- Zap ---');
          print('Author: ${eventData['pubkey']}');
          print('Zap event');
          print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(eventData['created_at'] * 1000)}');
          print('------------------\n');
        }
      }
    }
  });

  webSocket.add(requestWithFilter.serialize());

  await Future.delayed(Duration(seconds: 30));
  await webSocket.close();
  print('Connection closed.');
}

void main() async {
  String nip19NoteId = "NOTE ID (note123...)";

  await fetchInteractionsForNoteId(nip19NoteId);
}
