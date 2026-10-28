import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from omnitrix_project_gate import review

class ProjectGateTests(unittest.TestCase):
    def test_diamond_city_agency_bootstrap(self):
        self.assertEqual(review({"active_project": "Diamond City", "requested_scope": "agency-wide", "source_projects": ["AOK Global Mart"]})["status"], "ESCALATE")
    def test_agency_ocb(self):
        self.assertEqual(review({"active_project": "Omnitrix Agency OCB", "requested_scope": "agency-wide", "source_projects": ["AOK Global Mart", "Diamond City"]})["status"], "PASS")
    def test_foreign_source(self):
        self.assertEqual(review({"active_project": "Diamond City", "requested_scope": "single-project", "source_projects": ["AOK Global Mart"]})["status"], "ESCALATE")
    def test_missing_scope(self):
        self.assertEqual(review({"active_project": "Diamond City"})["status"], "BLOCK")
    def test_unverified_write(self):
        self.assertEqual(review({"active_project": "Diamond City", "requested_scope": "single-project", "phase": "postflight", "writes_performed": True, "readback_verified": False})["status"], "BLOCK")

if __name__ == "__main__":
    unittest.main()
