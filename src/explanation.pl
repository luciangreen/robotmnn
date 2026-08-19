:- module(explanation,
    [ record_trace/5,
      explain_thought/3,
      explain_action/3,
      trace_entries/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).

record_trace(Type, Key, Explanation, State0, State1) :-
    get_traces(State0, Traces0),
    append(Traces0, [trace(Type, Key, Explanation)], Traces),
    set_traces(State0, Traces, State1).

explain_thought(Thought, State, Explanation) :-
    get_traces(State, Traces),
    member(trace(thought, Thought, Explanation), Traces), !.
explain_thought(Thought, _, explanation(chose(Thought), because([no_trace_available]))).

explain_action(Action, State, Explanation) :-
    get_traces(State, Traces),
    member(trace(action, Action, Explanation), Traces), !.
explain_action(Action, _, explanation(chose(Action), because([no_trace_available]))).

trace_entries(State, Traces) :- get_traces(State, Traces).
