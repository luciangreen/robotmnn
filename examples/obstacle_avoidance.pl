:- use_module('../src/robot').

demo :-
    new_robot(S0),
    robot_cycle([sensor_event(proximity, obstacle(front_path))], S0, Output, _),
    writeln(Output).
