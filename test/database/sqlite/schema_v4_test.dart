// Schema v4 (S5 step 6): a body that only repeats the text and a summary info
// that says nothing are stored as NULL and rebuilt on read; a v3 file is
// migrated in place and compacted once.
import 'dart:convert';
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/sqlite/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

Message _message(String guid, String? text, List<AttributedBody> body, {List<MessageSummaryInfo> summary = const []}) =>
    Message(guid: guid, text: text, attributedBody: body, messageSummaryInfo: summary, dateCreated: DateTime(2026));

AttributedBody _body(String s, List<Run> runs) => AttributedBody(string: s, runs: runs);
Run _run(int start, int length, {int part = 0, String? attachment, String? mention}) =>
    Run(range: [start, length], attributes: Attributes(messagePart: part, attachmentGuid: attachment, mention: mention));

MessageSummaryInfo _summary({List<int> retracted = const [], List<int> edited = const []}) =>
    MessageSummaryInfo(retractedParts: [...retracted], editedContent: {}, originalTextRange: {}, editedParts: [...edited]);

String _bodyJson(Message m) => jsonEncode([for (final b in m.attributedBody) b.toMap()]);

/// Every body shape the phone holds, keyed by guid.
Map<String, Message> shapes() => {
      for (final m in [
        _message('plain', 'hello there', plainTextBody('hello there')),
        _message('emoji', 'hi \u{1F44B}\u{1F3FD} ok', plainTextBody('hi \u{1F44B}\u{1F3FD} ok')),
        _message('empty-text', '', plainTextBody('')),
        _message('no-body', 'text only', []),
        _message('no-text', null, []),
        _message('attachment', 'see', [_body('\u{FFFC}see', [_run(0, 1, attachment: 'att-1'), _run(1, 3, part: 1)])]),
        _message('mention', 'hey Sam', [_body('hey Sam', [_run(0, 4), _run(4, 3, mention: 'x')])]),
        _message('short-run', 'abc', [_body('abc', [_run(0, 2)])]),
        _message('other-part', 'abc', [_body('abc', [_run(0, 3, part: 1)])]),
        _message('other-string', 'abc', [_body('abd', [_run(0, 3)])]),
        _message('two-bodies', 'abc', [...plainTextBody('abc'), ...plainTextBody('abc')]),
        _message('unsent', 'abc', plainTextBody('abc'), summary: [_summary(retracted: [0])]),
        _message('edited', 'abc', plainTextBody('abc'), summary: [_summary(edited: [0])]),
        _message('empty-summary', 'abc', plainTextBody('abc'), summary: [_summary()]),
      ])
        m.guid!: m
    };

void main() {
  test('only a body that repeats the text, and only an empty summary, are stored as NULL', () {
    final nullBody = {for (final m in shapes().values) if (messageToRow(m)['attributed_body_json'] == null) m.guid};
    final nullSummary = {for (final m in shapes().values) if (messageToRow(m)['message_summary_info_json'] == null) m.guid};
    expect(nullBody, {'plain', 'emoji', 'empty-text', 'unsent', 'edited', 'empty-summary'});
    expect(nullSummary, isNot(contains('unsent')));
    expect(nullSummary, isNot(contains('edited')));
    expect(nullSummary, containsAll(['plain', 'empty-summary', 'no-body']));
  });

  test('every body shape reads back as written', () {
    for (final m in shapes().values) {
      final back = messageFromRow({...messageToRow(m), 'id': 1});
      expect(_bodyJson(back), _bodyJson(m), reason: m.guid);
      expect(back.retractedParts, m.retractedParts, reason: m.guid);
      expect(back.messageSummaryInfo.firstOrNull?.editedParts ?? [], m.messageSummaryInfo.firstOrNull?.editedParts ?? [],
          reason: m.guid);
    }
  });

  group('a v3 file', () {
    late Directory dir;
    late File file;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('v4');
      file = File('${dir.path}/$storageFileName');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    /// The rows as v3 wrote them: every body and summary as JSON.
    Future<void> writeV3() async {
      final db = Db.file(file);
      await db.write((tx) async {
        for (final m in shapes().values) {
          await tx.insert('messages', {
            ...messageToRow(m),
            'id': null,
            'chat_id': null,
            'handle_relation_id': null,
            'attributed_body_json': m.dbAttributedBody,
            'message_summary_info_json': m.dbMessageSummaryInfo,
          });
        }
      });
      await db.close();
      final r = raw.sqlite3.open(file.path);
      r.execute('CREATE TABLE copy_checkpoints (entity TEXT NOT NULL PRIMARY KEY, last_source_id INTEGER NOT NULL, '
          'rows_copied INTEGER NOT NULL)');
      r.execute('PRAGMA user_version = 3');
      r.dispose();
    }

    test('migrates to v4: same messages through the mappers, NULL where the rule says, checkpoints gone', () async {
      await writeV3();
      final store = await openStorage(dir, onMain: false);
      addTearDown(closeStorage);
      final db = store.db;

      expect((await db.select('PRAGMA user_version')).single.values.single, 4);
      final rows = {for (final r in await db.select('SELECT * FROM messages')) r['guid']: r};
      for (final m in shapes().values) {
        final row = rows[m.guid]!;
        expect(row['attributed_body_json'], messageToRow(m)['attributed_body_json'], reason: m.guid);
        expect(row['message_summary_info_json'], messageToRow(m)['message_summary_info_json'], reason: m.guid);
        expect(_bodyJson(messageFromRow(row)), _bodyJson(m), reason: m.guid);
      }
      expect(await db.select("SELECT name FROM sqlite_master WHERE name = 'copy_checkpoints'"), isEmpty);
      expect(await db.select("SELECT 1 FROM storage_meta WHERE key = 'vacuum_pending'"), hasLength(1));
    });

    test('the main isolate compacts it once and clears the flag', () async {
      await writeV3();
      final store = await openStorage(dir, onMain: true);
      addTearDown(closeStorage);
      final db = store.db;
      expect(await db.select("SELECT 1 FROM storage_meta WHERE key = 'vacuum_pending'"), isEmpty);
      expect((await db.select('PRAGMA freelist_count')).single.values.single, 0);
      expect(await db.select('SELECT guid FROM messages'), hasLength(shapes().length));
    });
  });
}
