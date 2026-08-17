:- module(state_utils,
    [ initial_state/1,
      empty_dialogue_context/1,
      get_percepts/2,
      set_percepts/3,
      get_working_memory/2,
      set_working_memory/3,
      get_dialogue/2,
      set_dialogue/3,
      get_tasks/2,
      set_tasks/3,
      get_last_reply/2,
      set_last_reply/3,
      get_traces/2,
      set_traces/3,
      get_ltm/2,
      set_ltm/3,
      get_episodic/2,
      set_episodic/3,
      get_semantic/2,
      set_semantic/3,
      get_mnn/2,
      set_mnn/3,
      get_goals/2,
      set_goals/3,
      get_plans/2,
      set_plans/3,
      get_drives/2,
      set_drives/3,
      get_status/2,
      set_status/3,
      get_env/2,
      set_env/3,
      add_log/4,
      log_events/2,
      next_cycle/2,
      cycle_count/2,
      identity_name/2
    ]).

:- use_module(library(lists)).
:- use_module(mnn, [default_mnn/1]).
:- use_module(simulator, [default_environment/1]).

empty_dialogue_context(dialogue_context([], none, [], [], [], none)).

initial_state(
    robot_state(
        [],
        working_memory(Dialogue, none, [], [], none),
        long_term_memory([], Semantic, MNN, []),
        [],
        [],
        [],
        [drive(curiosity, 0.5), drive(safety, 1.0)],
        robot_status(running, safe, none, [],
            robot_identity(name("MNN-1"), type(humanoid), architecture(mnn), version("0.1")),
            [permission(alex, request, general), permission(technician1, enter_mode, maintenance)],
            0),
        Env
    )) :-
    empty_dialogue_context(Dialogue),
    default_environment(Env),
    default_mnn(MNN),
    Semantic = [
        semantic_fact(robot_name("MNN-1"), 1.0, configured(identity)),
        semantic_fact(robot_architecture(mnn), 1.0, configured(identity)),
        semantic_fact(robot_type(humanoid), 1.0, configured(identity)),
        semantic_fact(observed(object_at(red_book, study)), 0.95, configured(simulator)),
        semantic_fact(observed(object_at(blue_book, library)), 0.95, configured(simulator)),
        semantic_fact(observed(object_at(red_cup, kitchen)), 0.95, configured(simulator)),
        semantic_fact(observed(object_at(blue_cup, office)), 0.95, configured(simulator)),
        semantic_fact(observed(person_at(alex, office)), 0.95, configured(simulator)),
        semantic_fact(observed(person_at(sam, hallway)), 0.95, configured(simulator))
    ].

get_percepts(robot_state(Percepts, _, _, _, _, _, _, _, _), Percepts).
set_percepts(robot_state(_, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env), Percepts,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_working_memory(robot_state(_, WM, _, _, _, _, _, _, _), WM).
set_working_memory(robot_state(Percepts, _, LTM, Thoughts, Goals, Plans, Drives, Status, Env), WM,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_dialogue(State, Dialogue) :-
    get_working_memory(State, working_memory(Dialogue, _, _, _, _)).
set_dialogue(State0, Dialogue, State1) :-
    get_working_memory(State0, working_memory(_, Focus, Traces, Tasks, LastReply)),
    set_working_memory(State0, working_memory(Dialogue, Focus, Traces, Tasks, LastReply), State1).

get_tasks(State, Tasks) :-
    get_working_memory(State, working_memory(_, _, _, Tasks, _)).
set_tasks(State0, Tasks, State1) :-
    get_working_memory(State0, working_memory(Dialogue, Focus, Traces, _, LastReply)),
    set_working_memory(State0, working_memory(Dialogue, Focus, Traces, Tasks, LastReply), State1).

get_last_reply(State, Reply) :-
    get_working_memory(State, working_memory(_, _, _, _, Reply)).
set_last_reply(State0, Reply, State1) :-
    get_working_memory(State0, working_memory(Dialogue, Focus, Traces, Tasks, _)),
    set_working_memory(State0, working_memory(Dialogue, Focus, Traces, Tasks, Reply), State1).

get_traces(State, Traces) :-
    get_working_memory(State, working_memory(_, _, Traces, _, _)).
set_traces(State0, Traces, State1) :-
    get_working_memory(State0, working_memory(Dialogue, Focus, _, Tasks, LastReply)),
    set_working_memory(State0, working_memory(Dialogue, Focus, Traces, Tasks, LastReply), State1).

get_ltm(robot_state(_, _, LTM, _, _, _, _, _, _), LTM).
set_ltm(robot_state(Percepts, WM, _, Thoughts, Goals, Plans, Drives, Status, Env), LTM,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_episodic(State, Episodic) :-
    get_ltm(State, long_term_memory(Episodic, _, _, _)).
set_episodic(State0, Episodic, State1) :-
    get_ltm(State0, long_term_memory(_, Semantic, MNN, Learned)),
    set_ltm(State0, long_term_memory(Episodic, Semantic, MNN, Learned), State1).

get_semantic(State, Semantic) :-
    get_ltm(State, long_term_memory(_, Semantic, _, _)).
set_semantic(State0, Semantic, State1) :-
    get_ltm(State0, long_term_memory(Episodic, _, MNN, Learned)),
    set_ltm(State0, long_term_memory(Episodic, Semantic, MNN, Learned), State1).

get_mnn(State, MNN) :-
    get_ltm(State, long_term_memory(_, _, MNN, _)).
set_mnn(State0, MNN, State1) :-
    get_ltm(State0, long_term_memory(Episodic, Semantic, _, Learned)),
    set_ltm(State0, long_term_memory(Episodic, Semantic, MNN, Learned), State1).

get_goals(robot_state(_, _, _, _, Goals, _, _, _, _), Goals).
set_goals(robot_state(Percepts, WM, LTM, Thoughts, _, Plans, Drives, Status, Env), Goals,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_plans(robot_state(_, _, _, _, _, Plans, _, _, _), Plans).
set_plans(robot_state(Percepts, WM, LTM, Thoughts, Goals, _, Drives, Status, Env), Plans,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_drives(robot_state(_, _, _, _, _, _, Drives, _, _), Drives).
set_drives(robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, _, Status, Env), Drives,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_status(robot_state(_, _, _, _, _, _, _, Status, _), Status).
set_status(robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, _, Env), Status,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

get_env(robot_state(_, _, _, _, _, _, _, _, Env), Env).
set_env(robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, _), Env,
    robot_state(Percepts, WM, LTM, Thoughts, Goals, Plans, Drives, Status, Env)).

add_log(State0, Category, Event, State1) :-
    get_status(State0, robot_status(Mode, Safety, Emergency, Logs0, Identity, Permissions, Cycle)),
    get_time(Now),
    stamp_date_time(Now, DateTime, 'UTC'),
    format_time(atom(Timestamp), '%FT%TZ', DateTime),
    append(Logs0, [log_event(Timestamp, Category, Event)], Logs),
    set_status(State0, robot_status(Mode, Safety, Emergency, Logs, Identity, Permissions, Cycle), State1).

log_events(State, Logs) :-
    get_status(State, robot_status(_, _, _, Logs, _, _, _)).

cycle_count(State, Cycle) :-
    get_status(State, robot_status(_, _, _, _, _, _, Cycle)).

next_cycle(State0, State1) :-
    get_status(State0, robot_status(Mode, Safety, Emergency, Logs, Identity, Permissions, Cycle0)),
    Cycle is Cycle0 + 1,
    set_status(State0, robot_status(Mode, Safety, Emergency, Logs, Identity, Permissions, Cycle), State1).

identity_name(State, Name) :-
    get_status(State, robot_status(_, _, _, _, robot_identity(name(Name), _, _, _), _, _)).
