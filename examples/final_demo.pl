% Final demonstration — section 84 of pr1.txt
% Exercises conversation, thought, planning, safety, and delivery in a single scenario.
%
% Run from the repository root:
%   swipl -g "demo, halt" -l examples/final_demo.pl

:- use_module('../src/robot').
:- use_module('../src/state_utils').
:- use_module('../src/simulator').
:- use_module('../src/explanation').

demo :-
    new_robot(S0),

    % --- Greeting ---
    hear(alex, "Hello.", S0, S1),
    robot_cycle([], S1, cycle_output(_, _, _, _, Reply1, _), S2),
    format("Alex:~n  Hello.~n"),
    format("Robot:~n  ~w~n~n", [Reply1]),

    % --- Delivery request ---
    hear(alex, "Can you bring me the red book from the study?", S2, S3),
    robot_cycle([], S3, cycle_output(_, Thought1, _, _, Reply2, _), S4),
    format("Alex:~n  Can you bring me the red book from the study?~n"),
    format("Robot thought:~n  ~w~n", [Thought1]),
    format("Robot:~n  ~w~n~n", [Reply2]),

    % --- First movement step: robot picks up the delivery goal ---
    robot_cycle([], S4, cycle_output(_, Thought2, Action2, _, _, _), S5),
    format("Robot thought:~n  ~w~n", [Thought2]),
    (Action2 = move_to(Loc2)
    ->  format("[Robot moves toward ~w.]~n~n", [Loc2])
    ;   format("[Robot action: ~w]~n~n", [Action2])
    ),

    % --- Inject obstacle (person blocking the path) ---
    get_env(S5, Env5),
    env_add_obstacle(front_path, Env5, Env5b),
    set_env(S5, Env5b, S5b),
    robot_cycle([sensor_event(proximity, obstacle(front_path))], S5b,
                cycle_output(_, Thought3, stop, _, _, _), S6),
    format("Robot thought:~n  ~w~n", [Thought3]),
    format("Robot safety decision:~n  Do not move forward.~n"),
    format("Robot:~n  Someone is in my path. I will wait.~n~n"),

    % --- Clear the obstacle ---
    get_env(S6, Env6),
    env_remove_obstacle(front_path, Env6, Env6b),
    set_env(S6, Env6b, S6b),
    format("[Path clears.]~n"),
    format("Robot:~n  The path is clear now.~n~n"),

    % --- Resume delivery ---
    robot_steps(8, [], S6b, S7),

    % --- Report outcome ---
    get_env(S7, Env7),
    ( env_object_location(Env7, red_book, office)
    ->  format("Robot thought:~n  The delivery task is complete.~n"),
        format("[Robot returns to Alex and hands over the red book.]~n"),
        format("Robot:~n  Here is the red book.~n"),
        format("Task:~n  completed~n")
    ;   format("[Delivery in progress after ~w steps.]~n", [8])
    ),

    % --- Explanation trace (section 65) ---
    nl,
    format("--- Explanation trace (last thought) ---~n"),
    ( explain_thought(Thought1, S4, Expl)
    ->  format("  ~w~n", [Expl])
    ;   true
    ).
