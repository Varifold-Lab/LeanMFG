"""Exercise publication gates in disposable Git repositories, without pushing."""
import unittest
import test_metadata

release = test_metadata.release


class ProvenanceTests(unittest.TestCase):
    # Reuse fixtures, without running the metadata cases again.
    def setUp(self):
        test_metadata.MetadataTests.setUp(self)
        self.tag = f"v{self.version}"
        path = self.root / "CHANGELOG.md"
        path.write_text(path.read_text() + f"\n## [{self.version}] - 2026-01-01\n\n- Candidate.\n")
        self.git("init", "--quiet")
        self.git("config", "user.name", "Release gate test")
        self.git("config", "user.email", "check@localhost")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "tag.gpgsign", "false")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "Candidate")
        self.git("update-ref", "refs/remotes/origin/main", "HEAD")

    def git(self, *args):
        return release.git(*args, root=self.root)

    def test_annotated_tag_at_candidate(self):
        self.git("tag", "-a", self.tag, "-m", "Candidate")
        info, _ = release.provenance(self.root, self.tag, True)
        self.assertEqual(info["commit"], self.git("rev-parse", "HEAD"))
        self.assertFalse(info["dirty"])

    def test_dirty_candidate(self):
        (self.root / "new-file").write_text("uncommitted")
        with self.assertRaisesRegex(ValueError, "clean checkout"):
            release.provenance(self.root, self.tag)

    def test_commit_outside_main(self):
        self.git("commit", "--allow-empty", "--quiet", "-m", "Unmerged")
        with self.assertRaisesRegex(ValueError, "origin/main"):
            release.provenance(self.root, self.tag)

    def test_lightweight_tag(self):
        self.git("tag", self.tag)
        with self.assertRaisesRegex(ValueError, "annotated"):
            release.provenance(self.root, self.tag, True)

    def test_tag_points_elsewhere(self):
        self.git("tag", "-a", self.tag, "-m", "Earlier")
        self.git("commit", "--allow-empty", "--quiet", "-m", "Later")
        self.git("update-ref", "refs/remotes/origin/main", "HEAD")
        with self.assertRaisesRegex(ValueError, "commit differ"):
            release.provenance(self.root, self.tag, True)
