// Switch plan commit 8: screens read through MessagingStore (or a service that
// does), never the ObjectBox boxes. Each file joins this list as it is moved.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const switched = [
  'lib/app/layouts/conversation_details/pages/chat_stats/tabs/chat_stats_content_tab.dart',
  'lib/app/layouts/conversation_details/pages/chat_stats/tabs/chat_stats_engagement_tab.dart',
  'lib/app/layouts/conversation_details/pages/chat_stats/tabs/chat_stats_overview_tab.dart',
  'lib/app/layouts/handle_selector_view/handle_selector_view.dart',
  'lib/app/layouts/chat_creator/chat_creator.dart',
  'lib/app/layouts/settings/pages/misc/soft_deleted_chats_panel.dart',
  'lib/app/layouts/settings/pages/misc/handle_audit_panel.dart',
  'lib/app/layouts/conversation_details/widgets/sections/links/links_section.dart',
  'lib/app/layouts/conversation_view/widgets/message/reply/reply_thread_popup.dart',
  'lib/app/layouts/conversation_view/pages/messages_view.dart',
  'lib/app/layouts/conversation_list/pages/search/search_query_helper.dart',
];

void main() {
  for (final path in switched) {
    test('$path reads no ObjectBox box', () {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('Database.')));
      expect(source, isNot(matches(RegExp(r'\b(Message|Chat|Handle|Attachment)_\.'))));
    });
  }
}
