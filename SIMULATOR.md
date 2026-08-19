# Simulator

The simulator provides a deterministic environment with rooms, people, objects, battery state, sensors, restricted areas and obstacles.

Example facts in the default environment:
- red book in the study
- Alex in the office
- two cups for ambiguity tests

Use `scripted_sensor_sequence/2` or direct `sensor_event(...)` inputs with `robot_cycle/4`.
