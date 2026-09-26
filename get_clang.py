#!/usr/bin/env python3

"""
Greenforce Clang Installer
"""

import json
import os
import platform
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request
from pathlib import Path


OWNER = "greenforce-project"
REPO = "greenforce_clang"
VERSION = "1.0.0"

INSTALL_DIR = Path(
    os.getenv(
        "GREENFORCE_INSTALL_DIR",
        Path.home() / ".local/greenforce-clang"
    )
)

MAX_RETRIES = 3

def banner():
    print("""
╔══════════════════════════════════════════╗
║          GREENFORCE CLANG                ║
║        LLVM TOOLCHAIN INSTALLER          ║
║              Python Edition              ║
╚══════════════════════════════════════════╝
""")

def section(name):
    print()
    print(name)
    print("-" * 42)

def ok(msg):
    print(f"✔ {msg}")

def info(msg):
    print(f"➜ {msg}")

def fail(msg):
    print(f"✘ {msg}")
    sys.exit(1)

def release_info():
    url = (
        f"https://api.github.com/repos/"
        f"{OWNER}/{REPO}/releases/latest"
    )

    try:
        with urllib.request.urlopen(url) as r:
            return json.load(r)
    except Exception as e:
        fail(f"Release lookup failed: {e}")

def find_archive(release):
    for asset in release.get("assets", []):
        name = asset["name"].lower()

        if name.endswith((".tar.gz", ".tgz")):
            return asset

    fail("No clang archive found")

def download(url, path):
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            info(f"Downloading archive ({attempt}/{MAX_RETRIES})")
            urllib.request.urlretrieve(url, path)
            return
        except Exception:
            if attempt == MAX_RETRIES:
                fail("Download failed")
            time.sleep(2)

def extract(path):
    INSTALL_DIR.mkdir(parents=True, exist_ok=True)

    with tarfile.open(path, "r:gz") as tar:
        tar.extractall(INSTALL_DIR)

def verify():
    clang = INSTALL_DIR / "bin/clang"

    if not clang.exists():
        fail("clang binary not found")

    version = subprocess.check_output(
        [str(clang), "--version"],
        text=True
    )

    return version.splitlines()[0]

def setup_github_path():
    github_path = os.getenv("GITHUB_PATH")

    if github_path:
        with open(github_path, "a") as f:
            f.write(str(INSTALL_DIR / "bin") + "\n")

def main():
    banner()

    section("SYSTEM")
    print(f"OS           : {platform.system()}")
    print(f"Architecture : {platform.machine()}")
    print(f"Python       : {platform.python_version()}")

    release = release_info()

    section("RELEASE")
    print(f"Version      : {release.get('tag_name')}")

    asset = find_archive(release)
    print(f"Asset        : {asset['name']}")

    archive = tempfile.mktemp(suffix=".tar.gz")

    section("DOWNLOAD")
    download(asset["browser_download_url"], archive)
    ok("Download completed")

    section("INSTALL")
    extract(archive)
    ok("Extraction completed")

    section("VERIFY")
    version = verify()
    ok("clang detected")
    print(version)

    setup_github_path()

    section("RESULT")
    print("Greenforce Clang installed")
    print(f"Path: {INSTALL_DIR}")


if __name__ == "__main__":
    main()
