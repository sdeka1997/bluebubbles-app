#!/usr/bin/env python3
"""Guarded local Android release builder/publisher for BubbleBeam."""

import argparse
import http.client
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REPOSITORY = "sdeka1997/bluebubbles-app"
ORIGIN_URLS = {
    "https://github.com/sdeka1997/bluebubbles-app.git",
    "git@github.com:sdeka1997/bluebubbles-app.git",
}
PACKAGE_ID = "com.bluebubbles.messaging.alpha"
SIGNER_SHA256 = "f2aa29d940eb58a4667f64d3aa4eddd9bbb158af84dd2fe2084dd4a90a660fa0"
VERSION_CODE_OFFSET = 20002000
MIN_FREE_BYTES = 15 * 1024**3
APK = Path("build/app/outputs/flutter-apk/app-alpha-release.apk")


class ReleaseError(RuntimeError):
    pass


class ReleaseConfig:
    def __init__(self, version_name, build_number, publish=False):
        if not re.fullmatch(r"[0-9A-Za-z][0-9A-Za-z._-]*", version_name):
            raise ReleaseError("version name may contain only letters, digits, '.', '_' and '-'")
        if not isinstance(build_number, int) or build_number <= 0:
            raise ReleaseError("Flutter build number must be a positive integer")
        self.version_name = version_name
        self.build_number = build_number
        self.publish = publish

    @property
    def version_code(self):
        return VERSION_CODE_OFFSET + self.build_number

    @property
    def tag(self):
        return "v{}+android.{}".format(self.version_name, self.version_code)

    @property
    def asset_name(self):
        return "BubbleBeam-{}-alpha.apk".format(self.tag)


class CommandRunner:
    def run(self, command, *, env=None, capture=True):
        try:
            result = subprocess.run(
                [str(part) for part in command],
                check=True,
                text=True,
                stdout=subprocess.PIPE if capture else None,
                stderr=subprocess.STDOUT if capture else None,
                env=env,
            )
        except (OSError, subprocess.CalledProcessError) as error:
            output = getattr(error, "stdout", None)
            detail = ": {}".format(output.strip()) if output else ""
            raise ReleaseError("command failed: {}{}".format(" ".join(map(str, command)), detail))
        return result.stdout or ""


class GitHubClient:
    def __init__(self, token=None, repository=REPOSITORY):
        self.token = token
        self.repository = repository

    def _request(self, method, path, payload=None, expected=(200,)):
        headers = {
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "BubbleBeam-local-release",
        }
        if self.token:
            headers["Authorization"] = "Bearer {}".format(self.token)
        data = None
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            headers["Content-Type"] = "application/json"
        request = urllib.request.Request(
            "https://api.github.com{}".format(path), data=data, headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(request) as response:
                body = response.read()
                if response.status not in expected:
                    raise ReleaseError("GitHub API returned HTTP {}".format(response.status))
                return json.loads(body.decode("utf-8")) if body else None
        except urllib.error.HTTPError as error:
            if error.code in expected:
                return None
            raise ReleaseError("GitHub API returned HTTP {} for {}".format(error.code, path))
        except urllib.error.URLError as error:
            raise ReleaseError("GitHub API request failed: {}".format(error.reason))

    def assert_available(self, tag):
        encoded = urllib.parse.quote(tag, safe="")
        for kind, path in (
            ("tag", "/repos/{}/git/ref/tags/{}".format(self.repository, encoded)),
            ("release", "/repos/{}/releases/tags/{}".format(self.repository, encoded)),
        ):
            result = self._request("GET", path, expected=(200, 404))
            if result is not None:
                raise ReleaseError("GitHub {} already exists: {}".format(kind, tag))

    def publish(self, *, tag, asset, asset_name, target):
        if not self.token:
            raise ReleaseError("--publish requires GH_TOKEN in the environment")
        try:
            asset_size = asset.stat().st_size
        except OSError as error:
            raise ReleaseError("cannot read APK for upload: {}".format(error))
        release = self._request(
            "POST",
            "/repos/{}/releases".format(self.repository),
            payload={
                "tag_name": tag,
                "target_commitish": target,
                "name": tag,
                "body": "BubbleBeam Android alpha release {}.".format(tag),
                "draft": False,
                "prerelease": False,
                "generate_release_notes": True,
            },
            expected=(201,),
        )
        upload_url = release["upload_url"].split("{")[0]
        parsed = urllib.parse.urlparse(upload_url)
        path = "{}?{}".format(
            parsed.path,
            urllib.parse.urlencode({"name": asset_name}),
        )
        connection = http.client.HTTPSConnection(parsed.hostname)
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": "Bearer {}".format(self.token),
            "Content-Type": "application/vnd.android.package-archive",
            "Content-Length": str(asset_size),
            "User-Agent": "BubbleBeam-local-release",
            "X-GitHub-Api-Version": "2022-11-28",
        }
        try:
            with asset.open("rb") as apk_file:
                connection.request("POST", path, body=apk_file, headers=headers)
                response = connection.getresponse()
                response.read()
                if response.status != 201:
                    raise ReleaseError("GitHub asset upload returned HTTP {}".format(response.status))
        except OSError as error:
            raise ReleaseError("GitHub asset upload failed: {}".format(error))
        finally:
            connection.close()

        encoded = urllib.parse.quote(tag, safe="")
        verified = self._request(
            "GET", "/repos/{}/releases/tags/{}".format(self.repository, encoded)
        )
        asset_names = {item.get("name") for item in verified.get("assets", [])}
        if (
            verified.get("tag_name") != tag
            or verified.get("draft") is not False
            or verified.get("prerelease") is not False
            or asset_name not in asset_names
        ):
            raise ReleaseError("published GitHub release did not pass read-back verification")
        self._request("GET", "/repos/{}/git/ref/tags/{}".format(self.repository, encoded))


class ReleaseTool:
    def __init__(self, config, *, runner=None, github=None, disk_usage=None):
        self.config = config
        self.runner = runner or CommandRunner()
        self.github = github or GitHubClient(token=os.environ.get("GH_TOKEN"))
        self.disk_usage = disk_usage or shutil.disk_usage

    def check_git_state(self, fetch=True):
        if self.runner.run(["git", "status", "--porcelain"]).strip():
            raise ReleaseError("working tree is not clean")
        branch = self.runner.run(["git", "branch", "--show-current"]).strip()
        if branch != "main":
            raise ReleaseError("release must run from branch main")
        origin = self.runner.run(["git", "remote", "get-url", "origin"]).strip()
        if origin not in ORIGIN_URLS:
            raise ReleaseError("origin is not the BubbleBeam fork")
        if fetch:
            self.runner.run(["git", "fetch", "--quiet", "origin", "main"], capture=False)
        head = self.runner.run(["git", "rev-parse", "HEAD"]).strip()
        remote = self.runner.run(["git", "rev-parse", "origin/main"]).strip()
        if head != remote:
            raise ReleaseError("HEAD does not equal origin/main")
        return head

    def check_disk_space(self):
        free = self.disk_usage(Path.cwd()).free
        if free < MIN_FREE_BYTES:
            raise ReleaseError("at least 15 GiB of free disk space is required")

    def build_environment(self):
        environment = os.environ.copy()
        home = Path.home()
        tool_paths = [
            home / "BlueBubbles-Alpha-Build/toolchain/flutter/bin",
            home / "BlueBubbles-Alpha-Build/toolchain/jdk21/Contents/Home/bin",
            home / "BlueBubbles-Alpha-Build/toolchain/gradle-8.14/bin",
        ]
        environment["PATH"] = os.pathsep.join(map(str, tool_paths)) + os.pathsep + environment.get("PATH", "")
        environment.setdefault(
            "JAVA_HOME", str(home / "BlueBubbles-Alpha-Build/toolchain/jdk21/Contents/Home")
        )
        environment.setdefault("ANDROID_HOME", str(home / "Library/Android/sdk"))
        environment["BB_REQUIRE_RELEASE_SIGNING"] = "true"
        return environment

    def run_quality_and_build(self):
        Path(".env").touch(exist_ok=True)
        environment = self.build_environment()
        self.runner.run(["flutter", "test"], env=environment, capture=False)
        self.runner.run(
            ["flutter", "analyze", "--no-fatal-infos"], env=environment, capture=False
        )
        self.runner.run(
            [
                "flutter", "build", "apk", "--flavor", "alpha", "--release",
                "--build-name={}".format(self.config.version_name),
                "--build-number={}".format(self.config.build_number),
            ],
            env=environment,
            capture=False,
        )

    def cleanup_flutter_noise(self):
        self.runner.run(
            ["git", "restore", "--", "macos/Flutter/Flutter-*.xcconfig"], capture=False
        )
        for path in (
            Path(".env"),
            Path("ios/Flutter/ephemeral/.swift_pm.lock"),
            Path("macos/Podfile"),
            Path("ios/Flutter/ephemeral/Packages"),
        ):
            if path.is_dir():
                shutil.rmtree(path)
            elif path.exists():
                path.unlink()

    def find_android_tools(self):
        android_home = Path(self.build_environment()["ANDROID_HOME"])
        candidates = []
        for directory in (android_home / "build-tools").glob("*"):
            if (directory / "aapt2").is_file() and (directory / "apksigner").is_file():
                numbers = tuple(int(part) for part in re.findall(r"\d+", directory.name))
                candidates.append((numbers, directory))
        if not candidates:
            raise ReleaseError("Android SDK aapt2/apksigner were not found")
        directory = max(candidates)[1]
        return directory / "aapt2", directory / "apksigner"

    def validate_apk(self, apk, aapt2, apksigner):
        badging = self.runner.run([str(aapt2), "dump", "badging", str(apk)])
        match = re.search(
            r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'",
            badging,
        )
        if not match:
            raise ReleaseError("could not parse APK package metadata")
        package_id, version_code, version_name = match.groups()
        if package_id != PACKAGE_ID:
            raise ReleaseError("APK package ID is {}, expected {}".format(package_id, PACKAGE_ID))
        if version_name != self.config.version_name:
            raise ReleaseError("APK versionName is {}, expected {}".format(version_name, self.config.version_name))
        if version_code != str(self.config.version_code):
            raise ReleaseError("APK versionCode is {}, expected {}".format(version_code, self.config.version_code))
        certificates = self.runner.run(
            [str(apksigner), "verify", "--print-certs", str(apk)]
        )
        digest_match = re.search(r"SHA-256 digest:\s*([0-9a-fA-F]+)", certificates)
        digest = digest_match.group(1).lower() if digest_match else ""
        if digest != SIGNER_SHA256:
            raise ReleaseError("APK signer SHA-256 digest does not match the staged signer")

    def finish(self, apk, head):
        self.github.assert_available(self.config.tag)
        if not self.config.publish:
            print("Dry run complete; release was not published.")
            print("Tag: {}".format(self.config.tag))
            print("Asset: {}".format(self.config.asset_name))
            return
        self.github.publish(
            tag=self.config.tag,
            asset=apk,
            asset_name=self.config.asset_name,
            target=head,
        )
        print("Published {} with asset {}".format(self.config.tag, self.config.asset_name))

    def run(self):
        self.check_git_state()
        self.check_disk_space()
        self.github.assert_available(self.config.tag)
        try:
            self.run_quality_and_build()
            if not APK.is_file():
                raise ReleaseError("expected APK was not produced: {}".format(APK))
            aapt2, apksigner = self.find_android_tools()
            self.validate_apk(APK, aapt2, apksigner)
        finally:
            self.cleanup_flutter_noise()
        head = self.check_git_state()
        self.finish(APK, head)


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Build, validate, and optionally publish a BubbleBeam Android alpha release."
    )
    parser.add_argument("version_name", help="exact Flutter/Android versionName")
    parser.add_argument("build_number", type=int, help="Flutter build number")
    parser.add_argument(
        "--publish",
        action="store_true",
        help="create a non-draft public GitHub release and upload the APK",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    os.chdir(Path(__file__).resolve().parents[1])
    try:
        ReleaseTool(
            ReleaseConfig(args.version_name, args.build_number, args.publish)
        ).run()
    except ReleaseError as error:
        print("release failed: {}".format(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
