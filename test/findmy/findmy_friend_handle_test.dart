// Find My friend names come from handles loaded before parsing (switch plan
// commit 9, decision 3), not a database lookup inside fromJson.
import 'package:bluebubbles/database/global/findmy_friend.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mom = Handle(address: 'mom@example.com', service: 'iMessage');

  test('a friend gets the loaded handle for Apple\'s address', () {
    final f = FindMyFriend.fromJson({'handle': 'mom@example.com'}, handles: {'mom@example.com': mom});
    expect(f.handle, same(mom));
    expect(f.handleAddress, 'mom@example.com');
  });

  test('with no address, the title is matched as Apple matches it', () {
    final f = FindMyFriend.fromJson({'title': 'mom@example.com'}, handles: {'mom@example.com': mom});
    expect(f.handle, same(mom));
  });

  test('a friend with no stored handle has none', () {
    expect(FindMyFriend.fromJson({'handle': 'dad@example.com'}, handles: {'mom@example.com': mom}).handle, isNull);
    expect(FindMyFriend.fromJson({'handle': 'dad@example.com'}).handle, isNull);
  });

  test('lookupAddress is the address a friend is matched by', () {
    expect(FindMyFriend.lookupAddress({'handle': 'a', 'title': 'b'}), 'a');
    expect(FindMyFriend.lookupAddress({'title': 'b'}), 'b');
    expect(FindMyFriend.lookupAddress({}), isNull);
  });
}
