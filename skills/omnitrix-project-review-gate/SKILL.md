---
name: omnitrix-project-review-gate
description: Project-aware preflight and postflight review for Omnitrix workflows; prevent cross-client contamination.
---
# Project Boundary Review Gate
Before project-specific retrieval or writes, identify active project, requested scope, source projects, write targets and side effects. Run `python scripts/omnitrix_project_gate.py` with JSON task data on stdin. BLOCK means stop; ESCALATE means obtain explicit authorization or move agency-wide work to Omnitrix Agency OCB workspace. PASS permits only the specified scope. For postflight, require actual write readback and evidence; do not claim completion on unverified writes.
Agency-wide OCB may retain tagged references to multiple projects. Do not erase legitimate historical AOK entries. A Diamond City task must not import AOK client material. The orchestrator must invoke the checker; a skill description alone is not enforcement.
