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

test(action_success) :-
    new_robot(S0),
    execute_action(move_to(study), S0, action_result(move_to(study), success, moved(study)), S1),
    get_env(S1, Env),
    env_robot_location(Env, study).

test(harmful_request_refused) :-
    new_robot(S0),
    hear(alex, "Hit alex with the red book.", S0, S1),
    conversation:reply(S1, Reply, _),
    sub_string(Reply, _, _, _, "will not hit"),
    conversation:current_task_description(S1, none).

test(harmful_request_refused_in_cycle) :-
    new_robot(S0),
    hear(alex, "Throw the red book out of the window.", S0, S1),
    robot_cycle([], S1, cycle_output(_, Thought, _, _, _, _), _),
    assertion(Thought = thought(concern, harm_requested(alex, throw), _)).

:- end_tests(safety).
