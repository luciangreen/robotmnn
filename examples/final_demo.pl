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
    once(robot_cycle([], S1, cycle_output(_, _, _, _, Reply1, _), S2)),
    format("Alex:~n  Hello.~n"),
    format("Robot:~n  ~w~n~n", [Reply1]),

    % --- Delivery request ---
    hear(alex, "Can you bring me the red book from the study?", S2, S3),
    once(robot_cycle([], S3, cycle_output(_, Thought1, _, _, Reply2, _), S4)),
    format("Alex:~n  Can you bring me the red book from the study?~n"),
    format("Robot thought:~n  ~w~n", [Thought1]),
    format("Robot:~n  ~w~n~n", [Reply2]),

    % --- Person appears in path before robot starts moving ---
    get_env(S4, Env4),
    env_add_obstacle(front_path, Env4, Env4b),
    set_env(S4, Env4b, S4b),
    once(robot_cycle([sensor_event(proximity, obstacle(front_path))], S4b,
                     cycle_output(_, Thought3, Action3, _, _, _), S5)),
    format("Robot thought:~n  ~w~n", [Thought3]),
    (Action3 = stop
    ->  format("Robot safety decision:~n  Do not move forward.~n"),
        format("Robot:~n  Someone is in my path. I will wait.~n~n")
    ;   format("[Robot action: ~w]~n~n", [Action3])
    ),

    % --- Path clears; send clear sensor event and recover from emergency stop ---
    get_status(S5, robot_status(_, Safety, _, Logs, Identity, Perms, Cycle)),
    set_status(S5, robot_status(running, Safety, none, Logs, Identity, Perms, Cycle), S5a),
    once(robot_cycle([sensor_event(proximity, clear(front_path))], S5a,
                     cycle_output(_, _, _, _, _, _), S5c)),
    format("[Path clears.]~n"),
    format("Robot:~n  The path is clear now.~n~n"),

    % --- Resume and complete delivery ---
    robot_steps(8, [], S5c, S7),

    % --- Report outcome ---
    get_env(S7, Env7),
    % Alex is at office per the default simulator; the book is released there after delivery.
    ( env_object_location(Env7, red_book, office)
    ->  format("Robot thought:~n  The delivery task is complete.~n"),
        format("[Robot enters study, grasps red book, moves to Alex, releases it.]~n"),
        format("Robot:~n  Here is the red book.~n"),
        format("Task:~n  completed~n")
    ;   format("[Delivery in progress after 8 steps.]~n")
    ),

    % --- Explanation trace (section 65) ---
    nl,
    format("--- Explanation trace (selected thought) ---~n"),
    ( explain_thought(Thought1, S4, Expl)
    ->  format("  ~w~n", [Expl])
    ;   true
    ).

