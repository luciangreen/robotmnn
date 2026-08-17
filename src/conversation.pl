:- module(conversation,
    [ hear/4,
      reply/3,
      current_task_description/2
    ]).

:- use_module(library(lists)).
:- use_module(language).
:- use_module(goals).
:- use_module(tasks).
:- use_module(memory).
:- use_module(world_model).
:- use_module(state_utils).
:- use_module(safety).

hear(Speaker, Text, State0, State1) :-
    parse_utterance(Speaker, Text, State0, Intent),
    get_percepts(State0, Percepts0),
    append(Percepts0, [speech(Speaker, Text), Intent], Percepts),
    set_percepts(State0, Percepts, S1),
    update_world_model([speech(Speaker, Text), Intent], S1, S2),
    update_dialogue(Speaker, Text, Intent, S2, S3),
    add_episode(dialogue(heard(Speaker, Text)), [intent(Intent)], S3, S4),
    handle_intent(Intent, S4, State1).

update_dialogue(Speaker, Text, Intent, State0, State1) :-
    get_dialogue(State0, dialogue_context(Participants0, Topic0, Recent0, Open0, Referents0, _)),
    sort([Speaker|Participants0], Participants),
    append(Recent0, [turn(Speaker, Text, Intent)], Recent1),
    recent_limit(Recent1, Recent),
    dialogue_topic(Intent, Topic0, Topic),
    intent_open_questions(Intent, Open0, Open),
    referents_from_intent(Intent, NewReferents),
    append(Referents0, NewReferents, Referents1),
    sort(Referents1, Referents),
    set_dialogue(State0, dialogue_context(Participants, Topic, Recent, Open, Referents, Intent), State1).

recent_limit(Recent0, Recent) :-
    length(Recent0, N),
    ( N =< 10 -> Recent = Recent0
    ; Start is N - 10, length(_, Start), append(_, Recent, Recent0)
    ).

dialogue_topic(intent(_, question, location(Object)), _, location(Object)).
dialogue_topic(intent(_, request, deliver(Object, _)), _, deliver(Object)).
dialogue_topic(intent(_, clarify, object(Category, _, _)), _, clarification(Category)).
dialogue_topic(_, Topic, Topic).

intent_open_questions(intent(_, clarify, object(Category, Candidates, deliver)), Open0, Open) :-
    append(Open0, [clarify(Category, Candidates)], Open).
intent_open_questions(_, Open, Open).

referents_from_intent(intent(_, question, location(Object)), [Object]).
referents_from_intent(intent(_, request, deliver(Object, _)), [Object]).
referents_from_intent(_, []).

handle_intent(intent(Speaker, request, deliver(Object, Speaker)), State0, State1) :-
    add_goal(deliver(Object, Speaker), 85, human_request, pending, State0, S1),
    create_task(Speaker, deliver(Object, Speaker), S1, S2),
    set_last_reply(S2, pending(confirm(deliver(Object, Speaker))), State1).
handle_intent(intent(_, request, stop), State0, State1) :-
    emergency_stop(human_stop_command, State0, State1).
handle_intent(intent(Speaker, greet, hello), State0, State1) :-
    set_last_reply(State0, pending(reply_to(greeting, Speaker)), State1).
handle_intent(intent(_, question, robot_identity(name)), State0, State1) :-
    set_last_reply(State0, pending(inform(robot_identity("MNN-1"))), State1).
handle_intent(intent(_, question, current_task), State0, State1) :-
    current_task_description(State0, Task),
    set_last_reply(State0, pending(inform(current_task(Task))), State1).
handle_intent(intent(_, question, location(Object)), State0, State1) :-
    ( object_location(State0, Object, Location) ->
        set_last_reply(State0, pending(answer(location(Object, Location), 0.90)), State1)
    ; set_last_reply(State0, pending(answer(location_unknown(Object))), State1)
    ).
handle_intent(intent(_, clarify, object(Category, Candidates, deliver)), State0, State1) :-
    set_last_reply(State0, pending(ask_clarification(Category, Candidates)), State1).
handle_intent(_, State, State).

reply(State0, Reply, State1) :-
    get_last_reply(State0, pending(Goal)), !,
    formulate_reply(Goal, State0, Reply),
    set_last_reply(State0, Reply, State1).
reply(State, Reply, State) :-
    get_last_reply(State, Reply),
    Reply \= none,
    Reply \= pending(_), !.
reply(State, "", State).

current_task_description(State, Description) :-
    ( tasks:current_task(State, Goal) -> Description = Goal ; Description = none ).
