:- use_module('../src/robot').

demo :-
    new_robot(S0),
    hear(alex, "Hello.", S0, S1),
    robot_cycle([], S1, Output, _),
    writeln(Output).
