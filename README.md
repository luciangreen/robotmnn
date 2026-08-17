# robotmnn

SWI-Prolog humanoid robot architecture built around explicit Manual Neuronets (MNNs).

## Quick start

```prolog
$ swipl
?- [src/robot].
?- new_robot(S0),
   hear(alex, "Please bring me the red book.", S0, S1),
   robot_steps(20, [], S1, S2).
```

Core API:
- `new_robot/1`
- `robot_cycle/4`
- `robot_steps/4`
- `hear/4`
- `think/3`
- `plan/3`
- `execute_action/4`
- `recall/3`
- `explain_thought/3`
- `explain_action/3`

Highlights:
- inspectable thoughts, goals, plans and action traces
- working, episodic and semantic memory
- dialogue, questions, commands and clarification handling
- simulator-backed action execution with an independent safety kernel
- deterministic unit and integration tests under `tests/`

Run tests:

```bash
swipl -q       -s tests/test_mnn.pl       -s tests/test_thought.pl       -s tests/test_dialogue.pl       -s tests/test_memory.pl       -s tests/test_planning.pl       -s tests/test_tasks.pl       -s tests/test_safety.pl       -s tests/test_learning.pl       -s tests/test_simulator.pl       -s tests/test_integration.pl       -g run_tests,halt
```
