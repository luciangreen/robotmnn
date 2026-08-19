:- begin_tests(simulator).
:- use_module('../src/simulator').

test(simulated_sensor_input) :-
    default_environment(Env0),
    simulate_sensor(sensor_event(proximity, obstacle(front_path)), Env0, Env1),
    env_has_obstacle(Env1, front_path).

test(simulated_movement) :-
    default_environment(Env0),
    env_set_robot_location(Env0, office, Env1),
    env_robot_location(Env1, office).

:- end_tests(simulator).
