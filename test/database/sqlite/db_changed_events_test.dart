// dbChanged events (SQLITE-PLAN-2 section 4, risk R11): each committed
// Db.write change set is posted as IsolateEvent.dbChanged on the isolate event
// channel, and DbChangeEvents on the main isolate hands it to subscribers.
// Not subscribed by any service yet (slice B2).
import 'dart:io';
import 'dart:isolate';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/db_change_events.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/services/isolates/global_isolate.dart';
import 'package:bluebubbles/services/isolates/isolate_event.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Second isolate: posts its writes through IsolateEventEmitter as the app's
/// isolates do, saves two handles and a chat with them, then a write that
/// fails, then replies on [done].
Future<void> _writer((SendPort, SendPort, String) args) async {
  final (events, done, path) = args;
  IsolateEventEmitter.setSendPort(events);
  final db = Db.file(File(path));
  final posting = DbChangeEvents.postFrom(db);
  final handles = [Handle(address: 'ana@x.com'), Handle(address: 'bo@x.com')];
  final chat = Chat(guid: 'iMessage;+;chat1');
  await db.write((tx) async {
    await HandleRepo(tx).upsert(tx, handles);
    await ChatRepo(tx).upsert(tx, [chat]);
    await ChatRepo(tx).setParticipants(tx, chat.id!, handles.map((h) => h.id!));
  });
  try {
    await db.write((tx) async {
      await HandleRepo(tx).upsert(tx, [Handle(address: 'never@x.com')]);
      throw StateError('rolled back');
    });
  } on StateError {
    // expected
  }
  await db.write((tx) async {}); // changes nothing
  await posting.cancel();
  await db.close();
  done.send([chat.id, ...handles.map((h) => h.id)]);
}

void main() {
  // GlobalIsolate logs every event it dispatches.
  setUpAll(() => GetIt.I.registerSingleton<BaseLogger>(BaseLogger()));
  tearDownAll(() => GetIt.I.reset());

  test('DbChanges survive the trip as an event payload', () {
    final changes = DbChanges({'messages': {1, 2}, 'chat_handles': {7}});
    final back = DbChanges.fromMap(IsolateEventMessage<dynamic>.fromMap(
      IsolateEventMessage(type: IsolateEvent.dbChanged, data: changes.toMap()).toMap(),
    ).data as Map);
    expect(back.tables, changes.tables);
  });

  test('a write on a second isolate reaches a listener on the main isolate with its tables and ids', () async {
    final dir = await Directory.systemTemp.createTemp('db_changed');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/bb.sqlite';
    await Db.file(File(path)).close(); // schema made here, as the app opens first

    final hub = DbChangeEvents();
    final isolate = GlobalIsolate(); // not started: only its event dispatch is used
    hub.listenTo(isolate);
    final received = <DbChanges>[];
    final sub = hub.stream.listen(received.add);
    final events = ReceivePort();
    events.listen(isolate.debugHandleIsolateMessage);
    final done = ReceivePort();

    await Isolate.spawn(_writer, (events.sendPort, done.sendPort, path));
    final ids = (await done.first as List).cast<int>();
    await pumpEventQueue();
    events.close();
    await sub.cancel();

    final [chatId, anaId, boId] = ids;
    expect(received, hasLength(1), reason: 'one event per committed write; rollbacks and empty writes post nothing');
    expect(received.single.tables, {
      'handles': {anaId, boId},
      'chats': {chatId},
      'chat_handles': {chatId},
    });
  });

  test('a subscriber can take one table only; main-isolate writes come through the same stream', () async {
    final db = Db.memory();
    addTearDown(db.close);
    final hub = DbChangeEvents();
    final local = hub.attachLocal(db);
    addTearDown(local.cancel);
    final chatIds = <Set<int>>[];
    final all = <DbChanges>[];
    hub.on('chats').listen(chatIds.add);
    hub.stream.listen(all.add);

    await db.write((tx) => HandleRepo(tx).upsert(tx, [Handle(address: 'ana@x.com')]));
    await db.write((tx) => ChatRepo(tx).upsert(tx, [Chat(guid: 'c1'), Chat(guid: 'c2')]));
    await pumpEventQueue();

    expect(all, hasLength(2));
    expect(chatIds, [
      {1, 2},
    ]);
  });

  test('events from the isolate channel that are not change sets are ignored', () async {
    final hub = DbChangeEvents();
    final isolate = GlobalIsolate();
    hub.listenTo(isolate);
    final received = <DbChanges>[];
    hub.stream.listen(received.add);
    isolate.debugHandleIsolateMessage(IsolateEventMessage(type: IsolateEvent.dbChanged, data: 'junk').toMap());
    isolate.debugHandleIsolateMessage(IsolateEventMessage(type: IsolateEvent.dbChanged, data: {'tables': {}}).toMap());
    await pumpEventQueue();
    expect(received, isEmpty);
    hub.stopListening(isolate);
  });
}
