:- module(planner,
    [ plan/3,
      preconditions/3,
      next_plan_action/4
    ]).

:- use_module(library(lists)).
:- use_module(world_model).
:- use_module(state_utils).

plan(deliver(Object, Person), State, Plan) :-
    object_location(State, Object, ObjectLoc),
    person_location(State, Person, PersonLoc),
    Plan = [move_to(ObjectLoc), locate(Object), grasp(Object), move_to(PersonLoc), release(Object), report_completion(deliver(Object, Person))].
plan(location(Object), State, [report_location(Object, Location)]) :-
    object_location(State, Object, Location).
plan(stop, _, [stop]).
plan(Goal, _, [defer(Goal)]).

preconditions(move_to(Location), State, ok) :-
    get_env(State, environment(_, _, _, _, Rooms, _, _, _, _, _)),
    memberchk(Location, Rooms), !.
preconditions(move_to(Location), _, precondition_failed(unknown_location(Location))).

preconditions(locate(Object), State, ok) :- object_location(State, Object, _), !.
preconditions(locate(Object), _, precondition_failed(unknown_object_location(Object))).

preconditions(grasp(Object), State, ok) :-
    current_location(State, Location),
    object_location(State, Object, Location),
    get_env(State, environment(_, none, _, _, _, _, _, _, Sensors, _)),
    memberchk(gripper-available, Sensors), !.
preconditions(grasp(Object), _, precondition_failed(object_not_reachable(Object))).

preconditions(release(_), State, ok) :-
    get_env(State, environment(_, Holding, _, _, _, _, _, _, _, _)),
    Holding \= none, !.
preconditions(release(_), _, precondition_failed(nothing_held)).

preconditions(report_completion(_), _, ok).
preconditions(report_location(_, _), _, ok).
preconditions(say(_, _), _, ok).
preconditions(wait(_), _, ok).
preconditions(stop, _, ok).
preconditions(_, _, ok).

next_plan_action(Goal, State, Action, State1) :-
    get_plans(State, Plans0),
    select(plan_record(Goal, [Action|Rest], Status), Plans0, Plans1),
    memberchk(Status, [pending, running]), !,
    append(Plans1, [plan_record(Goal, Rest, running)], Plans),
    set_plans(State, Plans, State1).
next_plan_action(_, State, none, State).
