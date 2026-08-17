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

:- end_tests(dialogue).
