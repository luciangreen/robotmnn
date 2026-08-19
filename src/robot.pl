:- module(robot,
    [ new_robot/1,
      robot_cycle/4,
      robot_steps/4,
      hear/4,
      think/3,
      plan/3,
      execute_action/4,
      recall/3,
      explain_thought/3,
      explain_action/3,
      save_robot_state/2,
      load_robot_state/2
    ]).

:- use_module(state_utils).
:- use_module(cognitive_cycle, [robot_cycle/4, robot_steps/4]).
:- use_module(conversation, [hear/4]).
:- use_module(thought, [think/3]).
:- use_module(planner, [plan/3]).
:- use_module(actions, [execute_action/4]).
:- use_module(memory, [recall/3]).
:- use_module(explanation, [explain_thought/3, explain_action/3]).

new_robot(State) :- initial_state(State).

save_robot_state(File, State) :-
    setup_call_cleanup(open(File, write, Stream),
        writeq(Stream, State),
        close(Stream)).

load_robot_state(File, State) :-
    setup_call_cleanup(open(File, read, Stream),
        read(Stream, State),
        close(Stream)).
