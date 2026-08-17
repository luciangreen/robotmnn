:- use_module('../src/robot').

demo :-
    new_robot(S0),
    hear(alex, "Please bring me the red book.", S0, S1),
    robot_steps(6, [], S1, S2),
    writeln(S2).
