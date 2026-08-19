:- begin_tests(learning).
:- use_module('../src/robot').
:- use_module('../src/learning').
:- use_module('../src/memory').

test(learning) :-
    new_robot(S0),
    learn_from_result(locate(red_book), action_result(locate(red_book), success, located(red_book, study)), S0, S1),
    recall(location(red_book), S1, Memories),
    Memories \= [].

:- end_tests(learning).
