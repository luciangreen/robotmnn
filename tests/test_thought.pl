:- begin_tests(thought).
:- use_module('../src/robot').
:- use_module('../src/thought').
:- use_module('../src/goals').
:- use_module('../src/explanation').

test(thought_generation) :-
    new_robot(S0),
    hear(alex, "Hello.", S0, S1),
    generate_thoughts(S1, Candidates),
    member(candidate_thought(thought(dialogue, greet(alex), _), _, _, _, _, _), Candidates).

test(deterministic_thought_ranking) :-
    select_thought([
        candidate_thought(thought(goal, a, 0.8), 0.8, 0.9, 0.9, 0.2, test),
        candidate_thought(thought(goal, b, 0.7), 0.7, 0.8, 0.5, 0.2, test)
    ], _, Thought),
    Thought = thought(goal, a, 0.8).

test(goal_creation_from_thought) :-
    new_robot(S0),
    derive_goals_from_thought(thought(goal, deliver(red_book, alex), 0.8), S0, S1),
    robot:plan(deliver(red_book, alex), S1, _Plan).

test(explanation_generation) :-
    new_robot(S0),
    hear(alex, "Please bring me the red book.", S0, S1),
    think(S1, Thought, S2),
    explain_thought(Thought, S2, explanation(chose(Thought), because(_))).

:- end_tests(thought).
