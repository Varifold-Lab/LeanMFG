"""Exercise version/pin/changelog gates without creating a release."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("release_check", ROOT / "scripts/check_release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class MetadataTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for name in ("lakefile.toml", "lean-toolchain", "lake-manifest.json", "CHANGELOG.md",
                     "docs/app/docs/verification/page.mdx", "docs/package.json", "docs/package-lock.json",
                     "tests/mfglib/reference.json"):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        self.version = tomllib.loads((self.root / "lakefile.toml").read_text())["version"]
        (self.root / "CHANGELOG.md").write_text("# Changelog\n\n## [Unreleased]\n\n- Pending.\n")

    def edit_json(self, name, edit):
        path = self.root / name
        data = json.loads(path.read_text())
        edit(data)
        path.write_text(json.dumps(data))

    def test_development_metadata(self):
        info, notes = release.metadata(self.root)
        self.assertEqual(info["version"], self.version)
        self.assertFalse(notes)
        self.assertIn("floatlib", info["dependencies"])

    def test_candidate_entry(self):
        path = self.root / "CHANGELOG.md"
        path.write_text(path.read_text() + f"\n## [{self.version}] - 2026-01-01\n\n### Added\n\n- Example.\n")
        info, notes = release.metadata(self.root, f"v{self.version}")
        self.assertEqual(info["tag"], f"v{self.version}")
        self.assertIn("Example", notes)

    def test_missing_release_entry(self):
        with self.assertRaisesRegex(ValueError, "dated"):
            release.metadata(self.root, f"v{self.version}")

    def test_tag_mismatch(self):
        with self.assertRaisesRegex(ValueError, "Tag must match"):
            release.metadata(self.root, "not-a-version")

    def test_docs_version_drift(self):
        self.edit_json("docs/package.json", lambda d: d.update(version="mismatch"))
        with self.assertRaisesRegex(ValueError, "versions differ"):
            release.metadata(self.root)

    def test_lock_version_drift(self):
        self.edit_json("docs/package-lock.json", lambda d: d["packages"][""].update(version="mismatch"))
        with self.assertRaisesRegex(ValueError, "versions differ"):
            release.metadata(self.root)

    def test_dependency_drift(self):
        self.edit_json("lake-manifest.json", lambda d: d["packages"][0].update(rev="0" * 40))
        with self.assertRaisesRegex(ValueError, "Manifest disagrees"):
            release.metadata(self.root)

    def test_unpinned_direct_dependency(self):
        path = self.root / "lakefile.toml"
        revision = tomllib.loads(path.read_text())["require"][0]["rev"]
        path.write_text(path.read_text().replace(revision, "main"))
        with self.assertRaisesRegex(ValueError, "full commit"):
            release.metadata(self.root)


if __name__ == "__main__":
    unittest.main()
