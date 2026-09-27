#!/usr/bin/env python3
"""Validate release metadata; record provenance without claiming that tests ran."""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tomllib

ROOT = Path(__file__).resolve().parents[1]
VERSION = r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"
SHA = r"[0-9a-f]{40}"


def git(*args, root=ROOT):
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def metadata(root=ROOT, tag=None):
    config = tomllib.loads((root / "lakefile.toml").read_text())
    version = config["version"]
    if not re.fullmatch(VERSION, version):
        raise ValueError("Package version must be MAJOR.MINOR.PATCH")
    package = json.loads((root / "docs/package.json").read_text())
    lock = json.loads((root / "docs/package-lock.json").read_text())
    if any(v != version for v in (package["version"], lock["version"], lock["packages"][""]["version"])):
        raise ValueError("Lake and documentation package/lock versions differ")
    toolchain = (root / "lean-toolchain").read_text().strip()
    if not re.fullmatch(r"leanprover/lean4:v\d+\.\d+\.\d+(?:-rc\d+)?", toolchain):
        raise ValueError("Pin a released Lean toolchain")
    manifest = json.loads((root / "lake-manifest.json").read_text())
    deps = {p["name"]: p for p in manifest["packages"]}
    for required in config["require"]:
        if not re.fullmatch(SHA, required["rev"]):
            raise ValueError(f"Direct dependency must use a full commit: {required['name']}")
        if deps[required["name"]]["rev"] != required["rev"]:
            raise ValueError(f"Manifest disagrees with lakefile: {required['name']}")
    for dep in deps.values():
        if dep["type"] != "git" or not re.fullmatch(SHA, dep["rev"]):
            raise ValueError(f"Dependency must be locked to a Git commit: {dep['name']}")
    changelog = (root / "CHANGELOG.md").read_text()
    if "## [Unreleased]" not in changelog:
        raise ValueError("CHANGELOG.md needs an Unreleased section")
    notes = ""
    if tag:
        if tag != f"v{version}":
            raise ValueError(f"Tag must match package version: v{version}")
        match = re.search(rf"^## \[{re.escape(version)}\] - (\d{{4}}-\d{{2}}-\d{{2}})\n(.*?)(?=^## |\Z)",
                          changelog, re.M | re.S)
        if not match or not match[2].strip():
            raise ValueError("Release needs a dated, nonempty CHANGELOG section")
        if date.fromisoformat(match[1]) > date.today():
            raise ValueError("Release date cannot be in the future")
        notes = match[2].strip()
    hashes = {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in (
        "lakefile.toml", "lean-toolchain", "lake-manifest.json", "docs/package-lock.json",
        "tests/mfglib/reference.json", "docs/app/docs/verification/page.mdx", "CHANGELOG.md")}
    return {"version": version, "tag": tag, "lean": toolchain,
            "dependencies": {n: d["rev"] for n, d in sorted(deps.items())},
            "sha256": hashes}, notes


def provenance(root=ROOT, tag=None, require_tag=False):
    info, notes = metadata(root=root, tag=tag)
    info["commit"] = git("rev-parse", "HEAD", root=root)
    info["dirty"] = bool(git("status", "--porcelain", "--untracked-files=normal", root=root))
    if tag:
        if info["dirty"]:
            raise ValueError("Release candidates require a clean checkout")
        result = subprocess.run(["git", "merge-base", "--is-ancestor", "HEAD", "origin/main"], cwd=root)
        if result.returncode:
            raise ValueError("Release commit must be on origin/main")
    if require_tag:
        if not tag:
            raise ValueError("--require-tag needs --tag")
        if git("cat-file", "-t", f"refs/tags/{tag}", root=root) != "tag":
            raise ValueError("Release tag must be annotated")
        if git("rev-parse", f"{tag}^{{commit}}", root=root) != info["commit"]:
            raise ValueError("Tag and checked-out commit differ")
    return info, notes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag")
    parser.add_argument("--require-tag", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--notes", type=Path)
    args = parser.parse_args()
    info, notes = provenance(tag=args.tag, require_tag=args.require_tag)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(info, indent=2) + "\n")
    if args.notes:
        args.notes.parent.mkdir(parents=True, exist_ok=True)
        args.notes.write_text(notes + f'\n\nCommit: `{info["commit"]}`\n\n'
            "See `source.json` for pinned dependencies and input hashes, and the CI run for verification logs.\n"
            "Known limitations and proof/test coverage are recorded in docs/app/docs/verification/page.mdx at this commit.\n")
    print(f'PASS: version {info["version"]}; pinned dependencies; changelog; commit {info["commit"]}')


if __name__ == "__main__":
    main()
