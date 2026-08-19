:- module(actions,
    [ execute_action/4
    ]).

:- use_module(library(lists)).
:- use_module(planner).
:- use_module(safety).
:- use_module(state_utils).
:- use_module(simulator).
:- use_module(world_model).
:- use_module(memory).
:- use_module(language).
:- use_module(tasks).

execute_action(Action, State0, Result, State1) :-
    preconditions(Action, State0, Preconditions),
    execute_with_preconditions(Preconditions, Action, State0, Result, State1).

execute_with_preconditions(ok, Action, State0, Result, State1) :-
    safe_action(Action, State0, Decision, Reasons),
    execute_safe_action(Decision, Reasons, Action, State0, Result, State1).
execute_with_preconditions(precondition_failed(Reason), Action, State0,
    action_result(Action, failure, Reason), State1) :-
    add_log(State0, action, failed(Action, Reason), State1).

execute_safe_action(deny, Reasons, Action, State0, action_result(Action, failure, safety_denied(Reasons)), State1) :-
    add_log(State0, safety, denied(Action, Reasons), State1).
execute_safe_action(require_confirmation, Reasons, Action, State0, action_result(Action, failure, confirmation_required(Reasons)), State1) :-
    add_log(State0, safety, require_confirmation(Action, Reasons), State1).
execute_safe_action(require_replan, Reasons, Action, State0, action_result(Action, failure, replan_required(Reasons)), State1) :-
    add_log(State0, safety, require_replan(Action, Reasons), State1).
execute_safe_action(allow, _, Action, State0, Result, State1) :-
    perform_action(Action, State0, Result, State1).

perform_action(move_to(Location), State0, action_result(move_to(Location), success, moved(Location)), State1) :-
    get_env(State0, Env0),
    env_set_robot_location(Env0, Location, Env),
    set_env(State0, Env, S1),
    add_episode(action(move_to(Location)), [location(Location)], S1, S2),
    add_log(S2, action, moved_to(Location), State1).
perform_action(locate(Object), State0, action_result(locate(Object), success, located(Object, Location)), State1) :-
    object_location(State0, Object, Location),
    add_episode(action(locate(Object)), [location(Location)], State0, S1),
    add_log(S1, action, located(Object, Location), State1).
perform_action(grasp(Object), State0, action_result(grasp(Object), success, grasped(Object)), State1) :-
    get_env(State0, environment(Location, none, Objects0, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)),
    memberchk(Object-Location, Objects0),
    select(Object-Location, Objects0, Objects1),
    Env = environment(Location, Object, Objects1, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery),
    set_env(State0, Env, S1),
    add_episode(action(grasp(Object)), [location(Location)], S1, S2),
    add_log(S2, action, grasped(Object), State1).
perform_action(grasp(Object), State0, action_result(grasp(Object), failure, object_out_of_reach), State1) :-
    add_log(State0, action, failed(grasp(Object), object_out_of_reach), State1).
perform_action(release(Object), State0, action_result(release(Object), success, released(Object, Location)), State1) :-
    get_env(State0, environment(Location, Object, Objects0, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery)),
    append(Objects0, [Object-Location], Objects1),
    Env = environment(Location, none, Objects1, People, Rooms, Connections, Obstacles, Restricted, Sensors, Battery),
    set_env(State0, Env, S1),
    add_episode(action(release(Object)), [location(Location)], S1, S2),
    add_log(S2, action, released(Object, Location), State1).
perform_action(stop, State0, action_result(stop, success, stopped), State1) :-
    emergency_stop(obstacle_detected, State0, State1).
perform_action(wait(Duration), State0, action_result(wait(Duration), success, waited(Duration)), State1) :-
    add_log(State0, action, waited(Duration), State1).
perform_action(report_location(Object, Location), State0, action_result(report_location(Object, Location), success, spoke(Text)), State1) :-
    formulate_reply(answer(location(Object, Location), 0.90), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(report_completion(Goal), State0, action_result(report_completion(Goal), success, spoke(Text)), State1) :-
    formulate_reply(inform(completed(Goal)), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, greeting(Person)), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    formulate_reply(reply_to(greeting, Person), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, answer(robot_name)), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    identity_name(State0, Name),
    formulate_reply(inform(robot_identity(Name)), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, answer(current_task)), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    current_task_text(State0, TaskText),
    formulate_reply(inform(current_task(TaskText)), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, answer(location(Object))), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    ( object_location(State0, Object, Location) ->
        formulate_reply(answer(location(Object, Location), 0.90), State0, Text)
    ; formulate_reply(answer(location_unknown(Object)), State0, Text)
    ),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, ask_clarification(Category, Candidates)), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    formulate_reply(ask_clarification(Category, Candidates), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, confirm(deliver(Object, Person))), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    formulate_reply(confirm(deliver(Object, Person)), State0, Text),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(Person, request_assistance(Action)), State0, action_result(say(Person, Text), success, spoke(Text)), State1) :-
    format(string(Text), "I need assistance with ~w.", [Action]),
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(say(_, Text), State0, action_result(say(Text), success, spoke(Text)), State1) :-
    set_last_reply(State0, Text, S1),
    add_episode(action(say(Text)), [dialogue], S1, S2),
    add_log(S2, dialogue, spoke(Text), State1).
perform_action(call_service(Service, Request), State0, action_result(call_service(Service, Request), failure, unauthorised_service), State1) :-
    add_log(State0, action, denied_service(Service, Request), State1).
perform_action(Action, State0, action_result(Action, success, noop), State1) :-
    add_log(State0, action, noop(Action), State1).

current_task_text(State, none) :-
    \+ tasks:current_task(State, _), !.
current_task_text(State, Text) :-
    tasks:current_task(State, Goal),
    format(atom(Text), '~w', [Goal]).
