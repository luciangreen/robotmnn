:- module(mnn_activation,
    [ activate_mnn/3,
      mnn_fixpoint/4,
      activation_conclusions/2,
      activation_score/2
    ]).

:- use_module(library(lists)).
:- use_module(mnn).

activate_mnn(Inputs, Network, Activations) :-
    mnn_rules(Network, Rules),
    findall(rule_activation(Id, Priority, Support, Conclusions, Evidence),
        ( member(mnn_rule(Id, Conditions, Conclusions, Priority), Rules),
          rule_support(Conditions, Inputs, Evidence, Support) ),
        RuleActivations),
    mnn_links(Network, Links),
    findall(link_activation(Destination, Effect, Strength, Source),
        ( member(mnn_link(Source, Destination, Effect, Strength), Links),
          memberchk(Source, Inputs) ),
        LinkActivations),
    append(RuleActivations, LinkActivations, Activations).

rule_support(Conditions, Inputs, Evidence, Support) :-
    maplist(condition_evidence(Inputs), Conditions, Evidence),
    length(Evidence, Count),
    Count > 0,
    Support is min(1.0, Count / 4.0).

condition_evidence(Inputs, perceived(Term), matched(Term)) :-
    memberchk(Term, Inputs), !.
condition_evidence(Inputs, perceived(Term), matched(Term)) :-
    memberchk(intent(_, _, _), Inputs), memberchk(Term, Inputs), !.
condition_evidence(Inputs, belief(Fact), matched(Fact)) :-
    memberchk(belief(Fact, _, _), Inputs), !.
condition_evidence(Inputs, goal(Goal), matched(goal(Goal))) :-
    memberchk(goal(Goal, _), Inputs), !.
condition_evidence(Inputs, meta(Term), matched(meta(Term))) :-
    memberchk(Term, Inputs), !.
condition_evidence(Inputs, battery_below(Limit), matched(battery_below(Limit))) :-
    memberchk(battery_level(Level), Inputs), Level < Limit, !.
condition_evidence(_, not_recently(greeted(_)), not_recently(greeted)).
condition_evidence(_, greeting_text(_), greeting_text).
condition_evidence(_, threshold(Value, Limit), threshold(Value, Limit)) :- Value >= Limit.

mnn_fixpoint(Inputs, State0, State, Iterations) :-
    mnn_fixpoint(Inputs, State0, State, 0, Iterations).

mnn_fixpoint([], State, State, Iterations, Iterations) :- !.
mnn_fixpoint(Inputs, State0, State, Iter0, Iterations) :-
    Iter0 < 5,
    Iter1 is Iter0 + 1,
    State = State0,
    Iterations = Iter1.

activation_conclusions(rule_activation(_, _, _, Conclusions, _), Conclusions).
activation_conclusions(link_activation(Destination, Effect, Strength, Source), [link_effect(Destination, Effect, Strength, Source)]).

activation_score(rule_activation(_, Priority, Support, _, _), Score) :- Score is Priority * Support.
activation_score(link_activation(_, supports, Strength, _), Strength).
activation_score(link_activation(_, inhibits, Strength, _), Negative) :- Negative is -Strength.
