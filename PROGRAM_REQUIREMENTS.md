# Program Requirements

This repository implements the 84-section SWI-Prolog humanoid robot specification from `pr1.txt`.

Implemented areas:
- explicit `robot_state/9` state threading
- inspectable MNN nodes, links, rules, bounded activation propagation and basic duplicate-removal optimisation
- cognitive cycle: perceive, think, plan, act, learn
- symbolic thoughts, goals, plans, tasks, memories and beliefs
- dialogue understanding, replies, clarifications and status answers
- safety kernel, emergency stop and conservative movement checks
- simulation-first execution and hardware adapter interface
- explanation traces, logging, persistence and examples
- deterministic unit and integration tests

## Remaining unfinished specification areas

- Metacognitive interventions, complete action-failure recovery/replanning, and task lifecycle integration with plan outcomes.
- Explicit choice packets/splicing and broader deterministic alternative evaluation before action commitment.
- Authority/permission checks for human requests, and structured errors with recovery guidance.
- General contradiction resolution; current detection is limited to conflicting object locations.
- Provenance-bearing learned rules; current learning records associations and facts rather than reusable rules.
- Full route planning and action pre/postconditions, retries, alternatives, and replanning.
- Emergency-stop recovery conditions and a complete simulated safety model for the specified hazards and physical limits.
- Broader sensor simulation, state-aware dialogue/reference resolution, and remaining required multi-turn interaction cases.
- Advanced Loop2/PLOP/Detlog transformations and complete benchmarking (runtime, memory, candidates, and optimisation impact).
- Dependency annotations for future scheduling; optional Starlog and Spec-to-Algorithm tooling.
- Configurable resource limits and complete error diagnostics when limits are exhausted.

These items describe specification work not completed by the current implementation; optional future-compatibility items are not required for the initial runtime.
