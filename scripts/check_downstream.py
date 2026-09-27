#!/usr/bin/env python3
"""Install LeanMFG in a fresh Git-dependent Lake project and run a complete client.

By default export the working tree to a temporary Git repository (the real
repository is never committed). --revision uses an existing commit instead.
Only exact-revision transitive dependency caches are reused; LeanMFG is rebuilt.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(*args, cwd, **kwargs):
    return subprocess.run(args, cwd=cwd, check=True, **kwargs)


def output(*args, cwd):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def check(revision=None):
    with tempfile.TemporaryDirectory(prefix="leanmfg-downstream-") as tmp:
        work = Path(tmp)
        source = ROOT
        if revision is None:
            source = work / "snapshot"
            source.mkdir()
            names = subprocess.check_output(
                ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT
            ).decode().split("\0")
            for name in set(names) - {""}:
                original = ROOT / name
                if not original.is_file():
                    continue  # A tracked deletion stays deleted in the snapshot.
                destination = source / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(original, destination)
            run("git", "init", "--quiet", cwd=source)
            run("git", "add", ".", cwd=source)
            run("git", "-c", "user.name=LeanMFG downstream check", "-c",
                "user.email=check@localhost", "-c", "commit.gpgsign=false", "commit",
                "--quiet", "-m", "Temporary working-tree snapshot", cwd=source)
            revision = output("git", "rev-parse", "HEAD", cwd=source)
        else:
            revision = output("git", "rev-parse", "--verify", f"{revision}^{{commit}}", cwd=ROOT)
        project = work / "client"
        project.mkdir()
        (project / "lean-toolchain").write_text((ROOT / "lean-toolchain").read_text())
        (project / "Main.lean").write_text((ROOT / "tests/downstream/Main.lean").read_text())
        (project / "lakefile.toml").write_text(
            'name = "leanmfg_client"\nversion = "0.0.0"\n'
            'defaultTargets = ["client"]\n\n[[require]]\nname = "leanmfg"\n'
            f'git = {json.dumps(source.as_uri())}\nrev = "{revision}"\n'
            '\n[[lean_exe]]\nname = "client"\nroot = "Main"\n'
        )
        packages = project / ".lake/packages"
        packages.mkdir(parents=True)
        expected = json.loads((ROOT / "lake-manifest.json").read_text())["packages"]
        for dependency in expected:
            cached = ROOT / ".lake/packages" / dependency["name"]
            if not cached.is_dir() or output("git", "rev-parse", "HEAD", cwd=cached) != dependency["rev"]:
                raise RuntimeError(f"Build the pinned dependency first: {dependency['name']}")
            (packages / dependency["name"]).symlink_to(cached, target_is_directory=True)
        env = dict(os.environ, MATHLIB_NO_CACHE_ON_UPDATE="1")
        print(f"Installing Git revision {revision} in {project}", flush=True)
        run("lake", "update", cwd=project, env=env)
        installed = packages / "leanmfg"
        if output("git", "rev-parse", "HEAD", cwd=installed) != revision:
            raise RuntimeError("Lake installed the wrong LeanMFG revision")
        manifest = json.loads((project / "lake-manifest.json").read_text())
        actual = {d["name"]: d.get("rev") for d in manifest["packages"]}
        for dependency in expected:
            if actual.get(dependency["name"]) != dependency["rev"]:
                raise RuntimeError(f"Downstream dependency drift: {dependency['name']}")
        if (installed / ".lake/build").exists():
            raise RuntimeError("LeanMFG must start without package build artifacts")
        run("lake", "build", cwd=project, env=env)
        run(str(project / ".lake/build/bin/client"), cwd=project, env=env)
        print("PASS: fresh Git installation; LeanMFG rebuilt with pinned transitive dependencies")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--revision", help="Install this existing commit instead of a working-tree snapshot")
    args = parser.parse_args()
    check(args.revision)
