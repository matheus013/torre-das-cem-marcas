import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("resume_probe", Path(__file__).resolve().parents[1] / "tools/bench/resume_build_probe.py")
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)


class ResumeProbeTests(unittest.TestCase):
    def log(self, done=True, missing=False):
        lines = [f"POWER test d{level} boss=100 pack=200 boss_share=0.001 pack_share=0.002 health=300" for level in range(2, 6)]
        lines.append('BUILD test {"character":"eloa","gear":{"weapon":"test"}}')
        for level in range(1, 6):
            for floor in [16, 51, 100, 30, 75, 99]:
                if missing and level == 5 and floor == 99:
                    continue
                lines.append(f'EVAL test d{level} floor={floor} ' + json.dumps({"floor": floor, "pass": True}))
        if done:
            lines.append("DONE test in 100s")
        return "\n".join(lines)

    def recover(self, text, existing=None):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)
            (path / "part_0.log").write_text(text)
            return PROBE.recover_logs(path, existing or {}, {"active_gems": [{"id": "test", "element": "ice"}]})

    def test_recovers_completed_summary_without_fabricating_gear(self):
        report = self.recover(self.log())["test"]
        self.assertEqual(report["element"], "ice")
        self.assertIsNone(report["stages"]["2"]["build"])
        self.assertEqual(report["stages"]["5"]["build"]["character"], "eloa")
        self.assertTrue(report["provenance"]["rounded_power"])
        self.assertEqual(len(report["evaluation"]["5"]), 6)

    def test_ignores_unfinished_study(self):
        self.assertEqual(self.recover(self.log(done=False)), {})

    def test_preserves_full_json_over_log_summary(self):
        self.assertEqual(self.recover(self.log(), {"test": {}}), {})

    def test_rejects_missing_checkpoint(self):
        with self.assertRaises(ValueError):
            self.recover(self.log(missing=True))

    def test_rejects_legacy_power_schema(self):
        with self.assertRaises(ValueError):
            self.recover(self.log().replace(" boss_share=0.001 pack_share=0.002", ""))

    def test_atomic_checkpoint_can_replace_previous(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "checkpoint.json"
            PROBE.save(path, [1])
            PROBE.save(path, [1, 2])
            self.assertEqual(json.loads(path.read_text()), [1, 2])
            self.assertFalse(path.with_suffix(".json.tmp").exists())

    def test_fingerprint_tracks_measurement_inputs(self):
        previous = PROBE.ROOT
        try:
            with tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                (root / "src").mkdir()
                (root / "data").mkdir()
                (root / "tools/bench").mkdir(parents=True)
                (root / "tools/bench/build_lab.gd").write_text("laboratory")
                source = root / "src/game.gd"
                source.write_text("before")
                PROBE.ROOT = root
                first = PROBE.measurement_hash()
                self.assertEqual(first, PROBE.measurement_hash())
                source.write_text("after")
                self.assertNotEqual(first, PROBE.measurement_hash())
        finally:
            PROBE.ROOT = previous


if __name__ == "__main__":
    unittest.main()
