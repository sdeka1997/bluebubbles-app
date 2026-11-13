import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "release_android.py"
spec = importlib.util.spec_from_file_location("release_android", SCRIPT)
release_android = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_android)


class FakeRunner:
    def __init__(self, responses=None):
        self.responses = responses or {}
        self.calls = []

    def run(self, command, *, env=None, capture=True):
        command = tuple(str(part) for part in command)
        self.calls.append((command, dict(env or {})))
        response = self.responses.get(command, "")
        if isinstance(response, Exception):
            raise response
        return response


class FakeGitHub:
    def __init__(self):
        self.checked = []
        self.published = []

    def assert_available(self, tag):
        self.checked.append(tag)

    def publish(self, **kwargs):
        self.published.append(kwargs)


class ReleaseAndroidTest(unittest.TestCase):
    def config(self, publish=False):
        return release_android.ReleaseConfig(
            version_name="2.1.2-seq.56",
            build_number=60008999,
            publish=publish,
        )

    def test_tag_and_asset_include_computed_android_version_code(self):
        config = self.config()
        self.assertEqual(config.version_code, 80010999)
        self.assertEqual(config.tag, "v2.1.2-seq.56+android.80010999")
        self.assertEqual(
            config.asset_name,
            "BubbleBeam-v2.1.2-seq.56+android.80010999-alpha.apk",
        )

    def test_dirty_tree_is_rejected_before_build(self):
        runner = FakeRunner({("git", "status", "--porcelain"): " M lib/main.dart\n"})
        tool = release_android.ReleaseTool(self.config(), runner=runner)
        with self.assertRaisesRegex(release_android.ReleaseError, "working tree is not clean"):
            tool.check_git_state()
        self.assertEqual(runner.calls, [(('git', 'status', '--porcelain'), {})])

    def test_head_must_equal_origin_main(self):
        runner = FakeRunner({
            ("git", "status", "--porcelain"): "",
            ("git", "branch", "--show-current"): "main\n",
            ("git", "remote", "get-url", "origin"): "https://github.com/sdeka1997/bluebubbles-app.git\n",
            ("git", "rev-parse", "HEAD"): "aaaa\n",
            ("git", "rev-parse", "origin/main"): "bbbb\n",
        })
        tool = release_android.ReleaseTool(self.config(), runner=runner)
        with self.assertRaisesRegex(release_android.ReleaseError, "HEAD does not equal origin/main"):
            tool.check_git_state(fetch=False)

    def test_requires_at_least_15_gib_free(self):
        runner = FakeRunner()
        usage = mock.Mock(free=15 * 1024**3 - 1)
        tool = release_android.ReleaseTool(
            self.config(), runner=runner, disk_usage=lambda _: usage
        )
        with self.assertRaisesRegex(release_android.ReleaseError, "15 GiB"):
            tool.check_disk_space()

    def test_apk_metadata_and_signer_are_exact(self):
        runner = FakeRunner({
            ("aapt2", "dump", "badging", "app.apk"): (
                "package: name='com.bluebubbles.messaging.alpha' "
                "versionCode='80010999' versionName='2.1.2-seq.56'\n"
            ),
            ("apksigner", "verify", "--print-certs", "app.apk"): (
                "Signer #1 certificate SHA-256 digest: "
                "f2aa29d940eb58a4667f64d3aa4eddd9bbb158af84dd2fe2084dd4a90a660fa0\n"
            ),
        })
        tool = release_android.ReleaseTool(self.config(), runner=runner)
        tool.validate_apk(Path("app.apk"), Path("aapt2"), Path("apksigner"))

    def test_wrong_package_is_rejected(self):
        runner = FakeRunner({
            ("aapt2", "dump", "badging", "app.apk"): (
                "package: name='com.bluebubbles.messaging' "
                "versionCode='80010999' versionName='2.1.2-seq.56'\n"
            ),
        })
        tool = release_android.ReleaseTool(self.config(), runner=runner)
        with self.assertRaisesRegex(release_android.ReleaseError, "package ID"):
            tool.validate_apk(Path("app.apk"), Path("aapt2"), Path("apksigner"))

    def test_dry_run_checks_name_but_never_publishes(self):
        github = FakeGitHub()
        tool = release_android.ReleaseTool(self.config(), runner=FakeRunner(), github=github)
        tool.finish(Path("app.apk"), "abc123")
        self.assertEqual(github.checked, [self.config().tag])
        self.assertEqual(github.published, [])

    def test_publish_requires_gh_token(self):
        github = release_android.GitHubClient(token=None)
        with self.assertRaisesRegex(release_android.ReleaseError, "GH_TOKEN"):
            github.publish(
                tag="v1+android.20002001",
                asset=Path("missing.apk"),
                asset_name="x.apk",
                target="abc123",
            )

    def test_build_sets_release_signing_guard_and_expected_flutter_args(self):
        runner = FakeRunner()
        tool = release_android.ReleaseTool(self.config(), runner=runner)
        tool.run_quality_and_build()
        commands = [call[0] for call in runner.calls]
        self.assertEqual(commands[0], ("flutter", "test"))
        self.assertEqual(commands[1], ("flutter", "analyze", "--no-fatal-infos"))
        self.assertEqual(commands[2], (
            "flutter", "build", "apk", "--flavor", "alpha", "--release",
            "--build-name=2.1.2-seq.56", "--build-number=60008999",
        ))
        self.assertEqual(runner.calls[2][1]["BB_REQUIRE_RELEASE_SIGNING"], "true")

    def test_quality_run_creates_required_dotenv_asset(self):
        runner = FakeRunner()
        tool = release_android.ReleaseTool(self.config(), runner=runner)
        previous = Path.cwd()
        with tempfile.TemporaryDirectory() as directory:
            os.chdir(directory)
            try:
                tool.run_quality_and_build()
                self.assertTrue(Path(".env").is_file())
            finally:
                os.chdir(previous)

    def test_staged_signing_config_is_private_and_cleaned_up(self):
        previous = Path.cwd()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            keystore = root / "debug.keystore"
            keystore.write_bytes(b"test keystore")
            (root / "android").mkdir()
            os.chdir(root)
            try:
                tool = release_android.ReleaseTool(
                    self.config(), runner=FakeRunner(), staged_keystore=keystore
                )
                tool.run_quality_and_build()
                signing = root / "android/key.properties"
                self.assertTrue(signing.is_file())
                self.assertEqual(signing.stat().st_mode & 0o777, 0o600)
                self.assertIn("storeFile={}".format(keystore.resolve()), signing.read_text())
                self.assertIn("keyAlias=androiddebugkey", signing.read_text())
                tool.cleanup_flutter_noise()
                self.assertFalse(signing.exists())
            finally:
                os.chdir(previous)

    def test_missing_staged_keystore_is_rejected_before_build(self):
        previous = Path.cwd()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "android").mkdir()
            os.chdir(root)
            try:
                tool = release_android.ReleaseTool(
                    self.config(),
                    runner=FakeRunner(),
                    staged_keystore=root / "missing.keystore",
                )
                with self.assertRaisesRegex(release_android.ReleaseError, "staged signing keystore"):
                    tool.run_quality_and_build()
                self.assertEqual(tool.runner.calls, [])
            finally:
                os.chdir(previous)


if __name__ == "__main__":
    unittest.main()
