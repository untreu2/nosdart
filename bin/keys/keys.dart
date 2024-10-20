import 'package:nostr/nostr.dart';

void main() {
  var keyPair = Keychain.generate();

  print('Private Key (nsec): ${keyPair.private}');
  print('Public Key (npub): ${keyPair.public}');
}
