:- use_module('../src/robot').

demo :-
    new_robot(S0),
    hear(alex, "What is your name?", S0, S1),
    robot_cycle([], S1, Output1, S2),
    writeln(Output1),
    hear(alex, "Please bring me the red book.", S2, S3),
    robot_steps(6, [], S3, S4),
    writeln(S4).
