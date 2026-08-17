:- module(self_monitor,
    [ self_monitor_thoughts/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(simulator).

self_monitor_thoughts(State, Thoughts) :-
    get_env(State, Env),
    env_battery(Env, Battery),
    battery_thoughts(Battery, BatteryThoughts),
    repeated_failure_thoughts(State, FailureThoughts),
    append(BatteryThoughts, FailureThoughts, Thoughts).

battery_thoughts(Battery, [candidate_thought(thought(concern, low_battery, 0.97), 0.97, 0.95, 1.0, 0.1, self_monitor)]) :-
    Battery < 20, !.
battery_thoughts(_, []).

repeated_failure_thoughts(State, [candidate_thought(thought(reflection, repeated_action(Action, Count), 0.88), 0.88, 0.85, 0.75, 0.2, self_monitor)]) :-
    log_events(State, Logs),
    include(is_failure_log, Logs, Failures),
    length(Failures, Count),
    Count >= 2,
    member(log_event(_, action, failed(Action, _)), Failures), !.
repeated_failure_thoughts(_, []).

is_failure_log(log_event(_, action, failed(_, _))).
