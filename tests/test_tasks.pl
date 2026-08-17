:- begin_tests(tasks).
:- use_module('../src/robot').
:- use_module('../src/tasks').

test(goal_creation) :-
    new_robot(S0),
    create_task(alex, deliver(red_book, alex), S0, S1),
    tasks(S1, [task(_, alex, deliver(red_book, alex), _, pending, _)]).

test(task_completion) :-
    new_robot(S0),
    create_task(alex, deliver(red_book, alex), S0, S1),
    complete_task(task_1, S1, S2),
    tasks(S2, [task(task_1, alex, deliver(red_book, alex), _, completed, _)]).

:- end_tests(tasks).
