:- begin_tests(dialogue).
:- use_module('../src/robot').
:- use_module('../src/conversation').

test(command_interpretation) :-
    new_robot(S0),
    hear(alex, "Please bring me the red book.", S0, S1),
    current_task_description(S1, deliver(red_book, alex)).

test(question_answering) :-
    new_robot(S0),
    hear(alex, "Where is the red book?", S0, S1),
    reply(S1, Reply, _),
    sub_string(Reply, _, _, _, "red_book").

test(ambiguous_commands) :-
    new_robot(S0),
    hear(alex, "Please bring me the cup.", S0, S1),
    reply(S1, Reply, _),
    sub_string(Reply, 0, 5, _, "Which").

test(denied_request_is_not_a_request) :-
    new_robot(S0),
    hear(alex, "Please do not bring me the red book.", S0, S1),
    current_task_description(S1, none),
    reply(S1, Reply, _),
    sub_string(Reply, _, _, _, "will not bring").

test(contracted_denial) :-
    new_robot(S0),
    hear(alex, "Don't bring me the red book.", S0, S1),
    current_task_description(S1, none).

test(denial_cancels_earlier_request) :-
    new_robot(S0),
    hear(alex, "Please bring me the red book.", S0, S1),
    hear(alex, "Do not bring me the red book.", S1, S2),
    assertion(\+ goals:next_goal(S2, deliver(red_book, alex))),
    assertion(current_task_description(S2, _)).


test(unknown_command_gets_reply) :-
    new_robot(S0),
    hear(alex, "Put the red book in the bin.", S0, S1),
    reply(S1, Reply, _),
    sub_string(Reply, _, _, _, "do not know how").

:- end_tests(dialogue).
