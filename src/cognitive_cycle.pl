:- module(cognitive_cycle,
    [ robot_cycle/4,
      robot_steps/4,
      robot_loop/1
    ]).

:- use_module(library(lists)).
:- use_module(perception).
:- use_module(conversation).
:- use_module(thought).
:- use_module(goals).
:- use_module(planner).
:- use_module(actions).
:- use_module(memory).
:- use_module(learning).
:- use_module(explanation).
:- use_module(state_utils).

robot_cycle(Input, State0, cycle_output(Percepts, Thought, Action, Result, Reply, Diagnostics), StateFinal) :-
    next_cycle(State0, S01),
    ingest_input(Input, S01, Percepts, S1),
    maybe_reply_goal(S1, ReplyGoal),
    think(S1, Thought, S2),
    derive_goals_from_thought(Thought, S2, S3),
    ensure_plan(S3, S4),
    select_action(ReplyGoal, Thought, S4, Action, S5),
    execute_action(Action, S5, Result, S6),
    learn_from_result(Action, Result, S6, S7),
    maybe_emit_reply(ReplyGoal, S7, Reply, S8),
    diagnostics(Thought, Action, Result, S8, Diagnostics),
    record_action_trace(Action, Thought, Result, Diagnostics, S8, StateFinal).

ingest_input([], State, [], State).
ingest_input(Inputs, State0, Percepts, State1) :-
    normalize_inputs(Inputs, _),
    process_inputs(Inputs, State0, [], Percepts, State1).

process_inputs([], State, Acc, Percepts, State) :- reverse(Acc, Percepts).
process_inputs([speech(Speaker, Text)|Rest], State0, Acc, Percepts, StateN) :-
    hear(Speaker, Text, State0, State1),
    process_inputs(Rest, State1, [speech(Speaker, Text)|Acc], Percepts, StateN).
process_inputs([sensor_event(Sensor, Data)|Rest], State0, Acc, Percepts, StateN) :-
    perceive(sensor_event(Sensor, Data), State0, _, State1),
    process_inputs(Rest, State1, [sensor_event(Sensor, Data)|Acc], Percepts, StateN).
process_inputs([Other|Rest], State0, Acc, Percepts, StateN) :-
    perceive(Other, State0, _, State1),
    process_inputs(Rest, State1, [Other|Acc], Percepts, StateN).

maybe_reply_goal(State, Goal) :-
    get_last_reply(State, pending(Goal)), !.
maybe_reply_goal(_, none).

ensure_plan(State0, State1) :-
    next_goal(State0, Goal),
    get_plans(State0, Plans0),
    \+ member(plan_record(Goal, _, _), Plans0), !,
    plan(Goal, State0, Steps),
    append(Plans0, [plan_record(Goal, Steps, pending)], Plans),
    set_plans(State0, Plans, State1).
ensure_plan(State, State).

select_action(Goal, _, State, Action, State) :-
    Goal \= none,
    reply_action(Goal, Action), !.
select_action(_, thought(concern, collision_possible(_), _), State, stop, State) :- !.
select_action(_, thought(concern, low_battery, _), State, wait(1), State) :- !.
select_action(_, thought(action, Action, _), State0, Action, State1) :- !,
    State1 = State0.
select_action(_, thought(goal, Goal, _), State0, Action, State1) :-
    planner:next_plan_action(Goal, State0, Action, State1),
    Action \= none, !.
select_action(_, _, State0, Action, State1) :-
    next_goal(State0, Goal),
    planner:next_plan_action(Goal, State0, Action, State1),
    Action \= none, !.
select_action(_, _, State, wait(1), State).

maybe_emit_reply(none, State, Reply, State) :-
    conversation:reply(State, Reply, _), !.
maybe_emit_reply(_, State, Reply, State) :-
    get_last_reply(State, Reply).

reply_action(reply_to(greeting, Speaker), say(Speaker, greeting(Speaker))).
reply_action(inform(robot_identity(_)), say(user, answer(robot_name))).
reply_action(inform(current_task(_)), say(user, answer(current_task))).
reply_action(answer(location(Object, _), _), say(user, answer(location(Object)))).
reply_action(answer(location_unknown(Object)), say(user, answer(location(Object)))).
reply_action(ask_clarification(Category, Candidates), say(user, ask_clarification(Category, Candidates))).
reply_action(confirm(deliver(Object, Person)), say(Person, confirm(deliver(Object, Person)))).
reply_action(Other, say(user, Other)).

diagnostics(Thought, Action, Result, State, diagnostics{thought:Thought, action:Action, result:Result, logs:Logs}) :-
    log_events(State, Logs).

record_action_trace(Action, Thought, Result, Diagnostics, State0, State1) :-
    Explanation = explanation(chose(Action), because([selected_from(Thought), result(Result), diagnostics(Diagnostics)])),
    record_trace(action, Action, Explanation, State0, State1).

robot_steps(0, _, State, State).
robot_steps(N, Inputs, State0, State) :-
    N > 0,
    next_input(Inputs, Input, RestInputs),
    robot_cycle(Input, State0, _, State1),
    N1 is N - 1,
    robot_steps(N1, RestInputs, State1, State).

next_input([], [], []).
next_input([Input|Rest], Input, Rest) :- !.
next_input(Input, Input, []).

robot_loop(State) :-
    robot_cycle([], State, _, State1),
    robot_loop(State1).
