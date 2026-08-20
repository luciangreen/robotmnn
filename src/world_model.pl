:- module(world_model,
    [ update_world_model/3,
      add_belief/5,
      beliefs_for_query/3,
      object_location/3,
      person_location/3,
      current_location/2,
      visible_objects/2,
      state_inputs/2,
      detect_conflicts/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(simulator).

update_world_model([], State, State).
update_world_model([Percept|Rest], State0, State2) :-
    update_one(Percept, State0, State1),
    update_world_model(Rest, State1, State2).

update_one(sensor_event(camera, object(Object, Location)), State0, State1) :-
    add_belief(observed(object_at(Object, Location)), 0.95, observed(camera), State0, S1),
    get_env(S1, Env0),
    env_set_object_location(Object, Location, Env0, Env),
    set_env(S1, Env, State1).
update_one(sensor_event(camera, person(Person, Location)), State0, State1) :-
    add_belief(observed(person_at(Person, Location)), 0.95, observed(camera), State0, S1),
    get_env(S1, Env0),
    simulator:simulate_sensor(sensor_event(camera, person(Person, Location)), Env0, Env),
    set_env(S1, Env, State1).
update_one(sensor_event(proximity, obstacle(Path)), State0, State1) :-
    add_belief(observed(obstacle(Path)), 1.0, observed(proximity), State0, S1),
    get_env(S1, Env0),
    env_add_obstacle(Path, Env0, Env),
    set_env(S1, Env, State1).
update_one(sensor_event(proximity, clear(Path)), State0, State1) :-
    get_semantic(State0, Semantic0),
    exclude(obstacle_belief_for(Path), Semantic0, Semantic),
    set_semantic(State0, Semantic, S1),
    get_env(S1, Env0),
    env_remove_obstacle(Path, Env0, Env),
    set_env(S1, Env, State1).
update_one(sensor_event(battery, level(Level)), State0, State1) :-
    add_belief(observed(battery(Level)), 1.0, observed(battery), State0, S1),
    get_env(S1, Env0),
    env_set_battery(Env0, Level, Env),
    set_env(S1, Env, State1).
update_one(intent(Speaker, Type, Payload), State0, State1) :-
    add_belief(reported(intent(Speaker, Type, Payload)), 0.9, reported_by_human(Speaker), State0, State1).
update_one(speech(Speaker, Text), State0, State1) :-
    add_belief(reported(speech(Speaker, Text)), 0.8, reported_by_human(Speaker), State0, State1).
update_one(_, State, State).

add_belief(Fact, Confidence, Provenance, State0, State1) :-
    get_semantic(State0, Semantic0),
    append(Semantic0, [semantic_fact(Fact, Confidence, Provenance)], Semantic),
    set_semantic(State0, Semantic, State1).

beliefs_for_query(Query, State, Matches) :-
    get_semantic(State, Semantic),
    include(matches_query(Query), Semantic, RawMatches),
    limit_list(100, RawMatches, Matches).

matches_query(location(Object), semantic_fact(observed(object_at(Object, _)), _, _)).
matches_query(location(Object), semantic_fact(learned(object_at(Object, _)), _, _)).
matches_query(current_task, semantic_fact(current_task(_), _, _)).
matches_query(Query, semantic_fact(Query, _, _)).

object_location(State, Object, Location) :-
    get_env(State, Env),
    env_object_location(Env, Object, Location), !.
object_location(State, Object, Location) :-
    get_semantic(State, Semantic),
    member(semantic_fact(observed(object_at(Object, Location)), _, _), Semantic), !.
object_location(State, Object, Location) :-
    get_semantic(State, Semantic),
    member(semantic_fact(learned(object_at(Object, Location)), _, _), Semantic).

person_location(State, Person, Location) :-
    get_env(State, Env),
    env_person_location(Env, Person, Location), !.
person_location(State, Person, Location) :-
    get_semantic(State, Semantic),
    member(semantic_fact(observed(person_at(Person, Location)), _, _), Semantic).

current_location(State, Location) :-
    get_env(State, Env),
    env_robot_location(Env, Location).

visible_objects(State, Objects) :-
    current_location(State, Location),
    findall(Object, object_location(State, Object, Location), Raw),
    sort(Raw, Objects).

state_inputs(State, Inputs) :-
    get_percepts(State, Percepts),
    get_goals(State, Goals),
    get_semantic(State, Semantic),
    get_env(State, Env),
    env_battery(Env, Battery),
    battery_inputs(Battery, BatteryInputs),
    maplist(wrap_goal, Goals, GoalInputs),
    findall(Item, (member(Fact, Semantic), semantic_input(Fact, Item)), SemanticInputs),
    append([Percepts, GoalInputs, SemanticInputs, BatteryInputs], Flat),
    flatten_once(Flat, Inputs0),
    sort(Inputs0, Inputs).

wrap_goal(goal(_, Goal, _, _, Status), goal(Goal, Status)).
semantic_input(semantic_fact(Fact, Confidence, Provenance), belief(Fact, Confidence, Provenance)).
semantic_input(semantic_fact(observed(obstacle(Path)), _, _), obstacle(Path)).
semantic_input(semantic_fact(observed(object_at(Object, Location)), _, _), object_at(Object, Location)).
semantic_input(semantic_fact(observed(person_at(Person, Location)), _, _), person_at(Person, Location)).
semantic_input(semantic_fact(learned(object_at(Object, Location)), _, _), object_at(Object, Location)).

battery_inputs(Battery, [battery_level(Battery)|Rest]) :-
    ( Battery < 20 -> Rest = [battery_low] ; Rest = [] ).

detect_conflicts(State, Conflicts) :-
    get_semantic(State, Semantic),
    findall(conflict(object_at(Object, A), object_at(Object, B), [ProvA, ProvB]),
        ( member(semantic_fact(FactA, _, ProvA), Semantic),
          member(semantic_fact(FactB, _, ProvB), Semantic),
          extract_object_location(FactA, Object, A),
          extract_object_location(FactB, Object, B),
          A \= B ),
        Raw),
    sort(Raw, Conflicts).

extract_object_location(observed(object_at(Object, Location)), Object, Location).
extract_object_location(learned(object_at(Object, Location)), Object, Location).
extract_object_location(object_at(Object, Location), Object, Location).

obstacle_belief_for(Path, semantic_fact(observed(obstacle(Path)), _, _)).

flatten_once(Lists, Flat) :-
    findall(Item, (member(L, Lists), (is_list(L) -> member(Item, L) ; Item = L)), Flat).

limit_list(N, List, Limited) :-
    length(Prefix, N), append(Prefix, _, List), !, Limited = Prefix.
limit_list(_, List, List).
