import 'package:nostr_tools/nostr_tools.dart';
import 'dart:convert';

String nip19ToHex(String nip19Id) {
  final nip19 = Nip19();
  var decodedNote = nip19.decode(nip19Id);
  return decodedNote['data'];
}

Future<String?> fetchAuthorName(String pubkey, RelayApi relay) async {
  final stream = await relay.connect();
  
  relay.sub([
    Filter(
      kinds: [0],
      authors: [pubkey],
      limit: 1,
    )
  ]);

  String? authorName;

  await for (Message message in stream) {
    if (message.type == 'EVENT') {
      Event event = message.message;
      var profileContent = jsonDecode(event.content);
      authorName = profileContent['name'] ?? 'Unknown';
      break;
    }
  }

  relay.close();
  return authorName;
}

Future<void> fetchInteractionsForNoteId(String nip19NoteId) async {
  String noteId = nip19ToHex(nip19NoteId);
  
  final relay = RelayApi(relayUrl: 'wss://relay.damus.io');
  final stream = await relay.connect();

  relay.on((event) {
    if (event == RelayEvent.connect) {
      print('[+] connected to ${relay.relayUrl}');
    } else if (event == RelayEvent.error) {
      print('[!] failed to connect to ${relay.relayUrl}');
    }
  });

  relay.sub([
    Filter(
      kinds: [1, 7],
      e: [noteId],
      limit: 50,
    )
  ]);

  stream.listen((Message message) async {
    if (message.type == 'EVENT') {
      Event event = message.message;
      var kind = event.kind;
      var tags = event.tags;

      bool isRelatedToNote = tags.any((tag) => tag[0] == 'e' && tag[1] == noteId);

      if (isRelatedToNote) {
        String? authorName = await fetchAuthorName(event.pubkey, relay);

        if (kind == 1) {
          print('--- Comment ---');
          print('Author: $authorName');
          print('Content: ${event.content}');
          print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(event.created_at * 1000)}');
          print('------------------\n');
        } else if (kind == 7) {
          print('--- Reaction ---');
          print('Author: $authorName');
          print('Reaction: ${event.content}');
          print('Timestamp: ${DateTime.fromMillisecondsSinceEpoch(event.created_at * 1000)}');
          print('------------------\n');
        } 
      }
    }
  });

  await Future.delayed(Duration(seconds: 30));
  relay.close();
  print('Connection closed.');
}

void main() async {
  String nip19NoteId = 'NOTE ID (note123...)';

  await fetchInteractionsForNoteId(nip19NoteId);
}
