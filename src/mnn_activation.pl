:- module(mnn_activation,
    [ activate_mnn/3,
      mnn_fixpoint/4,
    activate_mnn_fixpoint/4,
    activation_conclusions/2,
    activation_score/2
    ]).

:- use_module(library(lists)).
:- use_module(mnn).
:- use_module(state_utils, [get_mnn/2]).

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
    member(Term, Inputs).
condition_evidence(Inputs, belief(Fact), matched(Fact)) :-
    member(belief(Fact, _, _), Inputs).
condition_evidence(Inputs, goal(Goal), matched(goal(Goal))) :-
    member(goal(Goal, _), Inputs).
condition_evidence(Inputs, meta(Term), matched(meta(Term))) :-
    member(Term, Inputs).
condition_evidence(Inputs, battery_below(Limit), matched(battery_below(Limit))) :-
    memberchk(battery_level(Level), Inputs), Level < Limit, !.
condition_evidence(_, not_recently(greeted(_)), not_recently(greeted)).
condition_evidence(_, greeting_text(_), greeting_text).
condition_evidence(_, threshold(Value, Limit), threshold(Value, Limit)) :- Value >= Limit.

mnn_fixpoint(Inputs, State0, State, Iterations) :-
    get_mnn(State0, Network),
    activate_mnn_fixpoint(Inputs, Network, Activations, Iterations),
    activated_thoughts(Activations, NewThoughts),
    state_thoughts(State0, ExistingThoughts),
    append_unique(NewThoughts, ExistingThoughts, Thoughts),
    set_state_thoughts(State0, Thoughts, State).

activate_mnn_fixpoint(Inputs, Network, Activations, Iterations) :-
    sort(Inputs, Inputs0),
    activate_until_stable(Inputs0, Network, [], 0, Activations, Iterations).

activate_until_stable(Inputs, Network, Previous, Iteration0, Activations, Iterations) :-
    mnn_iteration_limit(Limit),
    Iteration0 < Limit,
    Iteration is Iteration0 + 1,
    activate_mnn(Inputs, Network, Current),
    append(Previous, Current, All0),
    sort(All0, All),
    activation_inputs(Current, Derived0),
    sort(Derived0, Derived),
    subtract(Derived, Inputs, NewInputs),
    ( NewInputs == [] ->
        Activations = All,
        Iterations = Iteration
    ; append(Inputs, NewInputs, Inputs1),
      sort(Inputs1, Inputs2),
      ( Iteration >= Limit ->
          Activations = All,
          Iterations = Iteration
      ; activate_until_stable(Inputs2, Network, All, Iteration, Activations, Iterations)
      )
    ).

mnn_iteration_limit(5).

activation_inputs([], []).
activation_inputs([rule_activation(_, _, _, Conclusions, _)|Rest], Inputs) :-
    activation_inputs(Rest, RestInputs),
    append(Conclusions, RestInputs, Inputs).
activation_inputs([link_activation(Destination, supports, Strength, Source)|Rest],
        [Destination, link_effect(Destination, supports, Strength, Source)|Inputs]) :- !,
    activation_inputs(Rest, Inputs).
activation_inputs([link_activation(Destination, Effect, Strength, Source)|Rest],
        [link_effect(Destination, Effect, Strength, Source)|Inputs]) :-
    activation_inputs(Rest, Inputs).

activated_thoughts(Activations, Thoughts) :-
    findall(Thought,
        ( member(Activation, Activations),
          activation_thought(Activation, Thought) ),
        Thoughts0),
    sort(Thoughts0, Thoughts).

activation_thought(rule_activation(_, _, _, Conclusions, _), thought(Type, Content, Confidence)) :-
    member(thought(Type, Content, Confidence), Conclusions).
activation_thought(rule_activation(_, _, Support, Conclusions, _), thought(goal, Goal, Support)) :-
    member(candidate_goal(Goal), Conclusions).
activation_thought(rule_activation(_, _, Support, Conclusions, _), thought(action, Action, Support)) :-
    member(candidate_action(Action), Conclusions).
activation_thought(link_activation(Destination, supports, Strength, Source),
        thought(prediction, link_support(Source, Destination), Strength)).
activation_thought(link_activation(Destination, inhibits, Strength, Source),
        thought(concern, inhibited(Source, Destination), Strength)).

state_thoughts(robot_state(_, _, _, Thoughts, _, _, _, _, _), Thoughts).

set_state_thoughts(
        robot_state(Percepts, Working, LongTerm, _, Goals, Plans, Drives, Status, Environment),
        Thoughts,
        robot_state(Percepts, Working, LongTerm, Thoughts, Goals, Plans, Drives, Status, Environment)).

append_unique([], Accumulator, Accumulator).
append_unique([Item|Rest], Accumulator0, Accumulator) :-
    ( memberchk(Item, Accumulator0) ->
        Accumulator1 = Accumulator0
    ; append(Accumulator0, [Item], Accumulator1)
    ),
    append_unique(Rest, Accumulator1, Accumulator).

activation_conclusions(rule_activation(_, _, _, Conclusions, _), Conclusions).
activation_conclusions(link_activation(Destination, Effect, Strength, Source), [link_effect(Destination, Effect, Strength, Source)]).

activation_score(rule_activation(_, Priority, Support, _, _), Score) :- Score is Priority * Support.
activation_score(link_activation(_, supports, Strength, _), Strength).
activation_score(link_activation(_, inhibits, Strength, _), Negative) :- Negative is -Strength.
