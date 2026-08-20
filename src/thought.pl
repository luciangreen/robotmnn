:- module(thought,
    [ generate_thoughts/2,
      select_thought/3,
      think/3,
      candidate_score/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(world_model).
:- use_module(mnn_activation).
:- use_module(self_monitor).
:- use_module(explanation).

generate_thoughts(State, Candidates) :-
    state_inputs(State, Inputs),
    get_mnn(State, MNN),
    activate_mnn(Inputs, MNN, Activations),
    findall(Candidate,
        ( member(Activation, Activations),
          activation_conclusions(Activation, Conclusions),
          member(Conclusion, Conclusions),
          conclusion_candidate(Activation, Conclusion, Candidate) ),
        MnnCandidates),
    goal_candidates(State, GoalCandidates),
    contradiction_candidates(State, ContradictionCandidates),
    self_monitor_thoughts(State, SelfMonitor),
    append([MnnCandidates, GoalCandidates, ContradictionCandidates, SelfMonitor], Raw),
    sort(Raw, Candidates).

conclusion_candidate(rule_activation(Id, Priority, Support, _, _), thought(Type, Content, Confidence),
    candidate_thought(thought(Type, Content, Confidence), Confidence, Support, Urgency, 0.1, mnn(Id, Priority))) :-
    urgency(Type, Urgency).
conclusion_candidate(rule_activation(Id, Priority, Support, _, _), candidate_goal(Goal),
    candidate_thought(thought(goal, Goal, Support), Support, Support, 0.8, 0.2, mnn(Id, Priority))).
conclusion_candidate(rule_activation(Id, Priority, Support, _, _), candidate_action(Action),
    candidate_thought(thought(action, Action, Support), Support, Support, 0.9, 0.1, mnn(Id, Priority))).
conclusion_candidate(link_activation(Dest, supports, Strength, Source), link_effect(Dest, supports, Strength, Source),
    candidate_thought(thought(prediction, link_support(Source, Dest), Strength), Strength, Strength, 0.4, 0.05, link(Source, Dest))).
conclusion_candidate(link_activation(Dest, inhibits, Strength, Source), link_effect(Dest, inhibits, Strength, Source),
    candidate_thought(thought(concern, inhibited(Source, Dest), Strength), Strength, 0.9, 0.95, 0.05, link(Source, Dest))).

urgency(concern, 1.0).
urgency(question, 0.9).
urgency(goal, 0.8).
urgency(action, 0.85).
urgency(dialogue, 0.75).
urgency(reflection, 0.65).
urgency(prediction, 0.6).
urgency(_, 0.5).

goal_candidates(State, Candidates) :-
    get_goals(State, Goals),
    findall(candidate_thought(thought(goal, Goal, Confidence), Confidence, Relevance, Urgency, 0.2, goal_system(Id)),
        ( member(goal(Id, Goal, Priority, _, Status), Goals),
          memberchk(Status, [pending, ready, running]),
          Confidence is Priority / 100.0,
          Relevance is Confidence,
          Urgency is min(1.0, Confidence + 0.1) ),
        Candidates).

contradiction_candidates(State, Candidates) :-
    detect_conflicts(State, Conflicts),
    findall(candidate_thought(thought(reflection, conflicting_beliefs(A, B), 0.8), 0.8, 0.9, 0.7, 0.2, contradiction),
        member(conflict(A, B, _), Conflicts), Candidates).

candidate_score(candidate_thought(_, Confidence, Relevance, Urgency, Cost, _), Score) :-
    Score is (Confidence * 0.35) + (Relevance * 0.3) + (Urgency * 0.4) - Cost.

select_thought(Candidates, State, Thought) :-
    include(is_concern_candidate, Candidates, Concerns),
    Concerns \= [], !,
    select_best_thought(Concerns, Thought).
select_thought(Candidates, _State, Thought) :-
    select_best_thought(Candidates, Thought).
select_thought([], _, thought(idle, wait, 1.0)).

is_concern_candidate(candidate_thought(thought(concern, _, _), _, _, _, _, _)).

select_best_thought(Candidates, Thought) :-
    findall(Key-candidate_thought(T, C, R, U, Cost, Source),
        ( member(candidate_thought(T, C, R, U, Cost, Source), Candidates),
          candidate_score(candidate_thought(T, C, R, U, Cost, Source), Score),
          Key is -Score ),
        Keyed),
    keysort(Keyed, [_-candidate_thought(Thought, _, _, _, _, _)|_]).

think(State0, Thought, State1) :-
    generate_thoughts(State0, Candidates),
    select_thought(Candidates, State0, Thought),
    get_thoughts(State0, Thoughts0),
    append(Thoughts0, [Thought], Thoughts),
    set_thoughts(State0, Thoughts, S1),
    explanation_for_selection(Thought, Candidates, Explanation),
    record_trace(thought, Thought, Explanation, S1, State1).

get_thoughts(robot_state(_, _, _, Thoughts, _, _, _, _, _), Thoughts).
set_thoughts(robot_state(Percepts, WM, LTM, _, Goals, Plans, Drives, Status, Env), Thoughts,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

explanation_for_selection(Thought, Candidates, explanation(chose(Thought), because(Reasons))) :-
    member(candidate_thought(Thought, Confidence, Relevance, Urgency, _, Source), Candidates), !,
    Reasons = [confidence(Confidence), relevance(Relevance), urgency(Urgency), source(Source)].
explanation_for_selection(Thought, _, explanation(chose(Thought), because([default_idle]))).
