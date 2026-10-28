"""Omnitrix project scope gate. Python 3.10+; stdin JSON, stdout JSON."""
import json
import sys

def review(task):
    active = task.get("active_project")
    scope = task.get("requested_scope")
    if not active or scope not in ("single-project", "agency-wide"):
        return {"status": "BLOCK", "reasons": ["Missing active project or valid scope"]}
    reasons = []
    if scope == "agency-wide" and active != "Omnitrix Agency OCB":
        reasons.append("Agency-wide work in a client workspace")
    if scope == "single-project":
        foreign = [p for p in task.get("source_projects", []) if p != active]
        if foreign:
            reasons.append("Foreign project sources: " + ", ".join(foreign))
    for target in task.get("write_targets", []):
        project = target.get("project")
        if project and project != active and not (active == "Omnitrix Agency OCB" and target.get("agency_shared")):
            reasons.append("Foreign write target: " + project)
    if task.get("phase") == "postflight" and task.get("writes_performed") and not task.get("readback_verified"):
        return {"status": "BLOCK", "reasons": ["Write readback missing"] + reasons}
    return {"status": "ESCALATE" if reasons else "PASS", "reasons": reasons}

if __name__ == "__main__":
    print(json.dumps(review(json.load(sys.stdin)), indent=2))
