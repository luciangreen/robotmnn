:- begin_tests(integration).
:- use_module('../src/robot').
:- use_module('../src/state_utils').
:- use_module('../src/simulator').

test(conversation_scenario) :-
    new_robot(S0),
    hear(alex, "What is your name?", S0, S1),
    robot_cycle([], S1, cycle_output(_, _, _, _, Reply, _), _),
    sub_string(Reply, _, _, _, "MNN-1").

test(delivery_scenario) :-
    new_robot(S0),
    hear(alex, "Please bring me the red book.", S0, S1),
    robot_steps(8, [], S1, S2),
    get_env(S2, Env),
    env_object_location(Env, red_book, office).

test(ambiguity_scenario) :-
    new_robot(S0),
    hear(alex, "Please bring me the cup.", S0, S1),
    robot_cycle([], S1, cycle_output(_, _, _, _, Reply, _), _),
    sub_string(Reply, _, _, _, "Which cup").

test(safety_scenario) :-
    new_robot(S0),
    robot_cycle([sensor_event(proximity, obstacle(front_path))], S0, cycle_output(_, Thought, Action, Result, _, _), _),
    Thought = thought(concern, collision_possible(front_path), _),
    Action = stop,
    Result = action_result(stop, success, stopped).

test(reflection_scenario) :-
    new_robot(S0),
    execute_action(grasp(red_book), S0, _, S1),
    execute_action(grasp(red_book), S1, _, S2),
    robot_cycle([], S2, cycle_output(_, Thought, _, _, _, _), _),
    Thought = thought(reflection, repeated_action(grasp(red_book), _), _).

:- end_tests(integration).
