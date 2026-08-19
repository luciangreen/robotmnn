# Architecture

The system is split into pure symbolic modules and execution modules.

- `robot.pl`: public API
- `cognitive_cycle.pl`: bounded cognitive loop
- `mnn*.pl`: explicit neuronet representation and activation
- `conversation.pl` / `language.pl`: symbolic dialogue handling
- `world_model.pl` / `memory.pl`: beliefs and recall
- `goals.pl` / `tasks.pl` / `planner.pl`: goal-task-plan pipeline
- `actions.pl` / `safety.pl`: explicit action selection and guarded execution
- `learning.pl` / `optimisation.pl`: symbolic adaptation and deterministic cleanup
- `simulator.pl` / `hardware_adapter.pl`: environment and adapter boundary

State is threaded through all major predicates; no hidden mutable cognition is required.
