:- begin_tests(safety).
:- use_module('../src/robot').
:- use_module('../src/safety').
:- use_module('../src/actions').
:- use_module('../src/simulator').
:- use_module('../src/state_utils').

test(safety_rejection) :-
    new_robot(S0),
    get_env(S0, Env0),
    env_add_obstacle(front_path, Env0, Env),
    set_env(S0, Env, S1),
    safe_action(move_to(office), S1, deny, _).

test(emergency_stop) :-
    new_robot(S0),
    emergency_stop(test_reason, S0, S1),
    safe_action(move_to(office), S1, deny, _).

test(action_failure_from_safety) :-
    new_robot(S0),
    get_env(S0, Env0),
    env_add_obstacle(front_path, Env0, Env),
    set_env(S0, Env, S1),
    execute_action(move_to(office), S1, action_result(move_to(office), failure, safety_denied(_)), _).

:- end_tests(safety).
