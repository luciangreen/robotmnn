:- module(goals,
    [ add_goal/6,
      update_goal_status/4,
      next_goal/2,
      goal_priority/2,
      derive_goals_from_thought/3
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).

add_goal(Goal, Priority, Source, Status, State0, State1) :-
    get_goals(State0, Goals0),
    length(Goals0, N),
    atom_concat(goal_, N, Base),
    succ(N, M),
    format(atom(Id), '~w_~d', [Base, M]),
    append(Goals0, [goal(Id, Goal, Priority, Source, Status)], Goals),
    set_goals(State0, Goals, State1).

update_goal_status(GoalId, NewStatus, State0, State1) :-
    get_goals(State0, Goals0),
    maplist(update_goal_if_matches(GoalId, NewStatus), Goals0, Goals),
    set_goals(State0, Goals, State1).

update_goal_if_matches(Id, Status, goal(Id, Goal, Priority, Source, _), goal(Id, Goal, Priority, Source, Status)) :- !.
update_goal_if_matches(_, _, Goal, Goal).

next_goal(State, GoalTerm) :-
    get_goals(State, Goals),
    include(active_goal, Goals, Active),
    keysort_goals(Active, [goal(_, GoalTerm, _, _, _)|_]).

active_goal(goal(_, _, _, _, Status)) :- memberchk(Status, [pending, ready, running]).

goal_priority(goal(_, _, Priority, _, _), Priority).

keysort_goals(Goals, Sorted) :-
    findall(Key-Goal,
        ( member(Goal, Goals), goal_priority(Goal, Priority), Key is -Priority ),
        Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

pairs_values([], []).
pairs_values([_-V|Rest], [V|Vs]) :- pairs_values(Rest, Vs).

derive_goals_from_thought(thought(goal, Goal, Confidence), State0, State1) :-
    Priority is round(Confidence * 100),
    add_goal(Goal, Priority, derived_subgoal, pending, State0, State1).
derive_goals_from_thought(_, State, State).
