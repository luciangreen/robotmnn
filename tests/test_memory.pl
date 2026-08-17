:- begin_tests(memory).
:- use_module('../src/robot').
:- use_module('../src/memory').
:- use_module('../src/world_model').

test(memory_insertion) :-
    new_robot(S0),
    add_semantic_fact(test_fact(foo), 0.9, unit_test, S0, S1),
    recall(test_fact(foo), S1, Memories),
    member(test_fact(foo), Memories).

test(memory_recall) :-
    new_robot(S0),
    recall(location(red_book), S0, Memories),
    Memories \= [].

test(contradictions) :-
    new_robot(S0),
    add_belief(observed(object_at(red_book, study)), 0.9, camera1, S0, S1),
    add_belief(observed(object_at(red_book, office)), 0.9, camera2, S1, S2),
    contradictions(S2, Conflicts),
    Conflicts \= [].

:- end_tests(memory).
