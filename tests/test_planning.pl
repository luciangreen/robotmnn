:- begin_tests(planning).
:- use_module('../src/robot').
:- use_module('../src/planner').

test(plan_creation) :-
    new_robot(S0),
    plan(deliver(red_book, alex), S0, Plan),
    Plan = [move_to(study), locate(red_book), grasp(red_book)|_].

test(precondition_failure) :-
    new_robot(S0),
    preconditions(grasp(red_book), S0, precondition_failed(object_not_reachable(red_book))).

test(replanning_fallback) :-
    new_robot(S0),
    plan(unknown_goal, S0, [defer(unknown_goal)]).

:- end_tests(planning).
