from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


def source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text()


class RecoverableChatDeletionContractTest(unittest.TestCase):
    def test_chat_api_uses_only_dedicated_recoverable_endpoint(self) -> None:
        code = source("lib/services/network/api/chat_api.dart")
        method = re.search(
            r"Future<Response> recoverableDelete\(.*?^  }",
            code,
            flags=re.MULTILINE | re.DOTALL,
        )
        if method is None:
            self.fail("expected method is missing")
        body = method.group(0)
        self.assertIn('dio.post(', body)
        self.assertIn('"${_svc.apiRoot}/chat/$guid/delete/recoverable"', body)
        self.assertNotIn('dio.delete(', body)
        self.assertNotIn('"${_svc.apiRoot}/chat/$guid"', body)

    def test_service_waits_for_server_success_before_local_soft_delete(self) -> None:
        code = source("lib/services/ui/chat/chats_service.dart")
        method = re.search(
            r"Future<bool> recoverablyDeleteChat\(.*?^  }",
            code,
            flags=re.MULTILINE | re.DOTALL,
        )
        if method is None:
            self.fail("expected method is missing")
        body = method.group(0)
        remote = body.index("await HttpSvc.chat.recoverableDelete(chat.guid)")
        local = body.index("await softDeleteChatLocalOnly(chat)")
        catch = body.index("catch (")
        self.assertLess(remote, local)
        self.assertLess(local, catch)
        self.assertIn("return true;", body[:catch])
        failure = body[catch:]
        self.assertIn("return false;", failure)
        self.assertNotIn("softDeleteChatLocalOnly", failure)
        self.assertIn("Conversation not deleted", failure)

    def test_all_user_deletion_entry_points_use_central_orchestration(self) -> None:
        callsites = [
            "lib/app/layouts/conversation_list/dialogs/conversation_peek_view.dart",
            "lib/app/layouts/conversation_list/widgets/footer/samsung_footer.dart",
            "lib/app/layouts/conversation_list/widgets/header/material_header.dart",
            "lib/app/layouts/conversation_list/widgets/tile/list_item.dart",
            "lib/app/layouts/conversation_view/widgets/header/material_header.dart",
            "lib/helpers/ui/ui_helpers.dart",
        ]
        for path in callsites:
            with self.subTest(path=path):
                code = source(path)
                self.assertIn("ChatsSvc.recoverablyDeleteChat(", code)
                self.assertNotIn("ChatsSvc.softDeleteChat", code)
                self.assertNotIn("ChatsSvc.removeChat", code)

    def test_no_ui_code_can_bypass_recoverable_orchestration(self) -> None:
        for directory in [ROOT / "lib/app", ROOT / "lib/helpers/ui"]:
            for path in directory.rglob("*.dart"):
                code = path.read_text()
                with self.subTest(path=path.relative_to(ROOT)):
                    self.assertNotIn("ChatsSvc.softDeleteChatLocalOnly(", code)
                    self.assertNotIn("HttpSvc.chat.delete(", code)

    def test_confirmation_copy_names_recently_deleted_on_apple_device(self) -> None:
        expected = "moved to Recently Deleted on your Apple devices"
        for path in [
            "lib/app/layouts/conversation_list/dialogs/conversation_peek_view.dart",
            "lib/app/layouts/conversation_view/widgets/header/material_header.dart",
            "lib/helpers/ui/ui_helpers.dart",
        ]:
            with self.subTest(path=path):
                self.assertIn(expected, source(path))

    def test_confirmation_closes_before_the_request_and_repeats_are_dropped(self) -> None:
        peek = source("lib/app/layouts/conversation_list/dialogs/conversation_peek_view.dart")
        pop = peek.index("Navigator.of(context, rootNavigator: true).pop();\n                    ChatsSvc.recoverablyDeleteChat(")
        self.assertGreater(pop, 0)
        service = source("lib/services/ui/chat/chats_service.dart")
        self.assertIn("if (!pendingDeletes.add(chat.guid)) return false;", service)
        self.assertIn("pendingDeletes.remove(chat.guid);", service.split("} finally {", 1)[1])
        tile = source("lib/app/layouts/conversation_list/widgets/tile/list_item.dart")
        self.assertIn("ChatsSvc.pendingDeletes.contains(chat.guid)", tile)
        self.assertIn("IgnorePointer(", tile)

    def test_local_only_soft_delete_is_explicitly_named(self) -> None:
        code = source("lib/services/ui/chat/chats_service.dart")
        self.assertIn("Future<void> softDeleteChatLocalOnly(Chat chat)", code)
        self.assertNotIn("Future<void> softDeleteChat(Chat chat)", code)


if __name__ == "__main__":
    unittest.main()
