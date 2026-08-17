:- module(learning,
    [ update_link_strength/5,
      learn_from_result/4
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(memory).

update_link_strength(Source, Destination, Delta, State0, State1) :-
    get_mnn(State0, mnn(Nodes, Links0, Rules, Meta)),
    adjust_links(Source, Destination, Delta, Links0, Links),
    set_mnn(State0, mnn(Nodes, Links, Rules, Meta), State1).

adjust_links(Source, Destination, Delta, [mnn_link(Source, Destination, Relation, Strength0)|Rest], [mnn_link(Source, Destination, Relation, Strength)|Rest]) :-
    Strength is max(0.0, min(1.0, Strength0 + Delta)), !.
adjust_links(Source, Destination, Delta, [Link|Rest0], [Link|Rest]) :-
    adjust_links(Source, Destination, Delta, Rest0, Rest).
adjust_links(Source, Destination, Delta, [], [mnn_link(Source, Destination, supports, Strength)]) :-
    Strength is max(0.0, min(1.0, 0.5 + Delta)).

learn_from_result(Action, action_result(Action, success, Evidence), State0, State1) :-
    learn_success(Action, Evidence, State0, State1), !.
learn_from_result(Action, action_result(Action, failure, Cause), State0, State1) :-
    add_semantic_fact(learned(action_failed(Action, Cause)), 0.8, learning, State0, State1).
learn_from_result(_, _, State, State).

learn_success(locate(Object), located(Object, Location), State0, State1) :-
    add_semantic_fact(learned(object_at(Object, Location)), 0.95, learning, State0, State1).
learn_success(release(Object), released(Object, Location), State0, State1) :-
    add_semantic_fact(learned(object_at(Object, Location)), 0.9, learning, State0, State1).
learn_success(Action, Evidence, State0, State1) :-
    add_episode(learned(Action), [Evidence], State0, State1).
