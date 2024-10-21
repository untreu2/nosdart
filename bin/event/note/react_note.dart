import 'package:nostr_tools/nostr_tools.dart';

Future<void> leaveReaction(String nsec, String nip19NoteId, String reaction) async {
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
    kind: 7, 
    tags: [
      ['e', noteId],
    ],
    content: reaction,
    created_at: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    pubkey: publicKey,
  );

  event.id = eventApi.getEventHash(event);
  event.sig = eventApi.signEvent(event, privateKey);

  relay.publish(event);

  stream.listen((Message message) {
    if (message.type == 'EVENT') {
      print('[+] Reaction sent: ${message.message}');
    } else if (message.type == 'OK') {
      print('[+] Event Published: ${message.message}');
    }
  });

  await Future.delayed(Duration(seconds: 10));
  relay.close();
}

void main() async {
  String nsec = 'NSEC HEX';
  String nip19NoteId = 'note123...';
  String reaction = '👍'; 

  await leaveReaction(nsec, nip19NoteId, reaction);
}
