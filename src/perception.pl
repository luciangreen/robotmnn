:- module(perception,
    [ perceive/4,
      normalize_inputs/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(world_model).

normalize_inputs([], []).
normalize_inputs([H|T], [N|Rest]) :- !,
    normalize_input(H, N),
    normalize_inputs(T, Rest).
normalize_inputs(Input, [N]) :- normalize_input(Input, N).

normalize_input(speech(Speaker, Text), intent(Speaker, statement, Text)).
normalize_input(sensor_event(Sensor, Data), sensor_event(Sensor, Data)).
normalize_input(Event, Event).

perceive(SensorInput, State0, Percepts, State1) :-
    normalize_inputs(SensorInput, Normalised),
    get_percepts(State0, Existing),
    append(Existing, Normalised, Percepts),
    set_percepts(State0, Percepts, S1),
    update_world_model(Normalised, S1, State1).
