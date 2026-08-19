:- module(tasks,
    [ create_task/4,
      start_task/3,
      advance_task/3,
      complete_task/3,
      fail_task/4,
      cancel_task/3,
      tasks/2,
      current_task/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).

create_task(RequestedBy, Goal, State0, State1) :-
    get_tasks(State0, Tasks0),
    length(Tasks0, N),
    succ(N, M),
    format(atom(Id), 'task_~d', [M]),
    append(Tasks0, [task(Id, RequestedBy, Goal, [], pending, 50)], Tasks),
    set_tasks(State0, Tasks, State1).

start_task(TaskId, State0, State1) :-
    set_task_status(TaskId, running, State0, State1).

advance_task(TaskId, State0, State1) :-
    get_tasks(State0, Tasks0),
    maplist(advance_one(TaskId), Tasks0, Tasks),
    set_tasks(State0, Tasks, State1).

advance_one(TaskId, task(TaskId, R, G, P, pending, Pri), task(TaskId, R, G, P, ready, Pri)) :- !.
advance_one(TaskId, task(TaskId, R, G, P, ready, Pri), task(TaskId, R, G, P, running, Pri)) :- !.
advance_one(_, Task, Task).

complete_task(TaskId, State0, State1) :-
    set_task_status(TaskId, completed, State0, State1).

fail_task(TaskId, Reason, State0, State1) :-
    get_tasks(State0, Tasks0),
    maplist(fail_one(TaskId, Reason), Tasks0, Tasks),
    set_tasks(State0, Tasks, State1).

fail_one(TaskId, Reason, task(TaskId, R, G, P, _, Pri), task(TaskId, R, G, P, failed(Reason), Pri)) :- !.
fail_one(_, _, Task, Task).

cancel_task(TaskId, State0, State1) :-
    set_task_status(TaskId, cancelled, State0, State1).

set_task_status(TaskId, Status, State0, State1) :-
    get_tasks(State0, Tasks0),
    maplist(status_one(TaskId, Status), Tasks0, Tasks),
    set_tasks(State0, Tasks, State1).

status_one(TaskId, Status, task(TaskId, R, G, P, _, Pri), task(TaskId, R, G, P, Status, Pri)) :- !.
status_one(_, _, Task, Task).

tasks(State, Tasks) :- get_tasks(State, Tasks).

current_task(State, Goal) :-
    get_tasks(State, Tasks0),
    member(task(_, _, Goal, _, Status, _), Tasks0),
    memberchk(Status, [running, ready, pending]), !.
current_task(_, none).
