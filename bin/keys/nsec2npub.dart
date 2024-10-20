import 'package:nostr/nostr.dart';

String deriveNpubFromNsec(String nsec) {
  var keychain = Keychain(nsec);
  return keychain.public;
}

void main() {
  String nsec = "HEX NSEC";
  String npub = deriveNpubFromNsec(nsec);
  print('Public Key (npub): $npub');
}
