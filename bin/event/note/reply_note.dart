import 'package:nostr_tools/nostr_tools.dart';

Future<void> replyToNote(String nsec, String nip19NoteId, String replyContent) async {
  final relay = RelayApi(relayUrl: 'wss://relay.damus.io');

  final nip19 = Nip19();
  var decodedNote = nip19.decode(nip19NoteId);
  String noteId = decodedNote['data'];

  final stream = await relay.connect();

  relay.on((event) {
    if (event == RelayEvent.connect) {
      print('[+] connected to ${relay.relayUrl}');
    } else if (event == RelayEvent.error) {
      print('[!] failed to connect to ${relay.relayUrl}');
    }
  });

  final eventApi = EventApi();
  final privateKey = nsec;
  final publicKey = KeyApi().getPublicKey(privateKey);
  
  final event = Event(
    kind: 1,
    tags: [
      ['e', noteId]
    ],
    content: replyContent,
    created_at: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    pubkey: publicKey,
  );

  event.id = eventApi.getEventHash(event);
  event.sig = eventApi.signEvent(event, privateKey);

  relay.publish(event);

  stream.listen((Message message) {
    if (message.type == 'EVENT') {
      print('[+] Reply sent: ${message.message}');
    } else if (message.type == 'OK') {
      print('[+] Event Published: ${message.message}');
    }
  });

  await Future.delayed(Duration(seconds: 10));
  relay.close();
}

void main() async {
  String nsec = 'NSEC HEX';
  String nip19NoteId = 'NOTE ID (note 123...)';
  String replyContent = 'hi dart!'; 

  await replyToNote(nsec, nip19NoteId, replyContent);
}
