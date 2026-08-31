#!/usr/bin/env python3
"""Wait until Helm chart images are published and pullable.

Agent release PRs bump Chart.yaml appVersion before the matching image has
finished building/pushing to public ECR. Chart-testing then fails with
ImagePullBackOff. This script polls until every referenced tag exists and
includes linux/amd64 (the architecture used by CI).
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

TIMEOUT_SECONDS = int(os.environ.get("IMAGE_WAIT_TIMEOUT_SECONDS", "2700"))
POLL_INTERVAL_SECONDS = int(os.environ.get("IMAGE_WAIT_POLL_INTERVAL_SECONDS", "30"))
REQUIRED_OS = os.environ.get("IMAGE_WAIT_OS", "linux")
REQUIRED_ARCH = os.environ.get("IMAGE_WAIT_ARCH", "amd64")

PUBLIC_ECR_HOST = "public.ecr.aws"
MANIFEST_ACCEPT = (
    "application/vnd.oci.image.index.v1+json,"
    "application/vnd.docker.distribution.manifest.list.v2+json,"
    "application/vnd.oci.image.manifest.v1+json,"
    "application/vnd.docker.distribution.manifest.v2+json"
)

ROOT_DIR = Path(__file__).resolve().parents[3]
_TOKEN_CACHE: dict[str, str] = {}
_extra_backoff_seconds = 0


def collect_images() -> list[str]:
    images: set[str] = set()
    for chart in sorted((ROOT_DIR / "charts").glob("*/Chart.yaml")):
        text = chart.read_text()
        values = (chart.parent / "values.yaml").read_text()
        repo_match = re.search(r'^  repository:\s*"([^"]+)"', values, re.M)
        if not repo_match:
            raise SystemExit(f"could not find image.repository in {chart.parent / 'values.yaml'}")
        repo = repo_match.group(1)

        app_match = re.search(r"^appVersion:\s*(\S+)", text, re.M)
        if app_match:
            images.add(f"{repo}:{app_match.group(1)}")

        stable_match = re.search(r"appVersionStable:\s*(\S+)", text)
        if stable_match:
            images.add(f"{repo}:{stable_match.group(1)}")

    # Used by the playground cluster that backs the benchmark chart tests.
    images.add("public.ecr.aws/warpstream-labs/warpstream_agent:latest")
    return sorted(images)


def split_image(image: str) -> tuple[str, str, str]:
    if "/" not in image or ":" not in image.rsplit("/", 1)[-1]:
        raise SystemExit(f"unsupported image reference {image!r}")
    host, remainder = image.split("/", 1)
    repo, tag = remainder.rsplit(":", 1)
    return host, repo, tag


def ecr_token(repo: str) -> str:
    if repo in _TOKEN_CACHE:
        return _TOKEN_CACHE[repo]
    url = (
        "https://public.ecr.aws/token/"
        f"?service=public.ecr.aws&scope=repository:{urllib.parse.quote(repo)}:pull"
    )
    with urllib.request.urlopen(url, timeout=30) as resp:
        payload = json.loads(resp.read().decode())
    token = payload.get("token")
    if not token:
        raise RuntimeError(f"public ECR token response missing token for {repo}")
    _TOKEN_CACHE[repo] = token
    return token


def index_has_platform(manifest: dict, os_name: str, arch: str) -> bool:
    manifests = manifest.get("manifests") or []
    if not manifests:
        # Single-arch image manifest is pullable as-is.
        return True
    for entry in manifests:
        platform = entry.get("platform") or {}
        if platform.get("os") == os_name and platform.get("architecture") == arch:
            return True
    return False


def image_is_ready(image: str) -> bool:
    global _extra_backoff_seconds
    host, repo, tag = split_image(image)
    if host != PUBLIC_ECR_HOST:
        raise SystemExit(f"unsupported registry {host} for {image}")

    try:
        token = ecr_token(repo)
    except Exception as exc:
        print(f"  token error for {image}: {exc}", file=sys.stderr)
        _TOKEN_CACHE.pop(repo, None)
        return False

    request = urllib.request.Request(
        f"https://{host}/v2/{repo}/manifests/{urllib.parse.quote(tag, safe='')}",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": MANIFEST_ACCEPT,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as resp:
            manifest = json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        if exc.code in (401, 403):
            _TOKEN_CACHE.pop(repo, None)
        if exc.code == 429:
            retry_after = exc.headers.get("Retry-After")
            try:
                _extra_backoff_seconds = max(_extra_backoff_seconds, int(retry_after))
            except (TypeError, ValueError):
                _extra_backoff_seconds = max(_extra_backoff_seconds, 60)
            print(
                f"  rate limited checking {image}; backing off {_extra_backoff_seconds}s",
                file=sys.stderr,
            )
            return False
        if exc.code in (404, 401, 403):
            return False
        print(f"  manifest error for {image}: HTTP {exc.code}", file=sys.stderr)
        return False
    except Exception as exc:
        print(f"  manifest error for {image}: {exc}", file=sys.stderr)
        return False

    return index_has_platform(manifest, REQUIRED_OS, REQUIRED_ARCH)


def utc_now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def main() -> int:
    global _extra_backoff_seconds
    images = collect_images()
    if not images:
        print("no chart images found to wait for", file=sys.stderr)
        return 1

    print(
        f"Waiting up to {TIMEOUT_SECONDS}s for images "
        f"(need {REQUIRED_OS}/{REQUIRED_ARCH}):"
    )
    for image in images:
        print(f"  - {image}")

    pending = list(images)
    started = time.monotonic()

    while pending:
        still_pending: list[str] = []
        for image in pending:
            if image_is_ready(image):
                print(f"{utc_now()} ready: {image}")
            else:
                still_pending.append(image)

        if not still_pending:
            print("all chart images are available")
            return 0

        elapsed = int(time.monotonic() - started)
        if elapsed >= TIMEOUT_SECONDS:
            print(f"timed out after {elapsed}s waiting for:", file=sys.stderr)
            for image in still_pending:
                print(f"  - {image}", file=sys.stderr)
            return 1

        print(f"{utc_now()} still waiting ({elapsed}s elapsed): {' '.join(still_pending)}")
        pending = still_pending
        sleep_for = max(POLL_INTERVAL_SECONDS, _extra_backoff_seconds)
        _extra_backoff_seconds = 0
        time.sleep(sleep_for)

    return 0


if __name__ == "__main__":
    sys.exit(main())
