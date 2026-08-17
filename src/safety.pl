:- module(safety,
    [ safe_action/4,
      emergency_stop/3
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(simulator).
:- use_module(world_model).

safe_action(Action, State, deny, [emergency_stop(Reason)]) :-
    get_status(State, robot_status(_, _, emergency(Reason), _, _, _, _)),
    physical_action(Action), !.
safe_action(move_to(Location), State, deny, [restricted_area(Location)]) :-
    get_env(State, Env), env_restricted(Env, Location), !.
safe_action(move_to(_), State, deny, [collision_risk(front_path)]) :-
    get_env(State, Env), env_has_obstacle(Env, front_path), !.
safe_action(move_to(_), State, deny, [sensor_unavailable(proximity)]) :-
    get_env(State, Env), env_sensor_state(Env, proximity, unavailable), !.
safe_action(grasp(Object), State, deny, [unsafe_gripping(Object)]) :-
    get_semantic(State, Semantic),
    member(semantic_fact(restricted_grasp(Object), _, _), Semantic), !.
safe_action(Action, State, require_confirmation, [low_battery]) :-
    physical_action(Action),
    get_env(State, Env), env_battery(Env, Battery), Battery < 15, !.
safe_action(Action, _, allow, [clear]) :- physical_action(Action), !.
safe_action(_, _, allow, [non_physical]).

physical_action(move_to(_)).
physical_action(turn(_)).
physical_action(grasp(_)).
physical_action(release(_)).
physical_action(stop).

emergency_stop(Reason, State0, State1) :-
    get_status(State0, robot_status(_, Safety, _, Logs, Identity, Permissions, Cycle)),
    set_status(State0, robot_status(stopped, Safety, emergency(Reason), Logs, Identity, Permissions, Cycle), S1),
    add_log(S1, safety, emergency_stop(Reason), State1).
