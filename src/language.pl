:- module(language,
    [ parse_utterance/4,
      formulate_reply/3,
      resolve_referent/4,
      normalise_text/2,
      object_alias/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(world_model).

object_alias(red_book, [red, book]).
object_alias(blue_book, [blue, book]).
object_alias(red_cup, [red, cup]).
object_alias(blue_cup, [blue, cup]).

category_tokens(book, [book]).
category_tokens(cup, [cup]).

normalise_text(Text, Tokens) :-
    string_lower(Text, Lower),
    split_string(Lower, " ?!.,:'\"", " ?!.,:'\"", StringTokens),
    exclude(=(""), StringTokens, Strings),
    maplist(atom_string, Tokens, Strings).

parse_utterance(Speaker, Text, State, Intent) :-
    normalise_text(Text, Tokens),
    classify_tokens(Speaker, Tokens, State, Intent), !.
parse_utterance(Speaker, Text, _, intent(Speaker, statement, Text)).

classify_tokens(Speaker, Tokens, _, intent(Speaker, greet, hello)) :-
    memberchk(hello, Tokens) ; memberchk(hi, Tokens).
classify_tokens(Speaker, Tokens, _, intent(Speaker, question, robot_identity(name))) :-
    phrase_match([what, is, your, name], Tokens) ; phrase_match([who, are, you], Tokens).
classify_tokens(Speaker, Tokens, _, intent(Speaker, question, current_task)) :-
    phrase_match([what, are, you, doing], Tokens).
classify_tokens(Speaker, Tokens, State, intent(Speaker, question, location(Object))) :-
    memberchk(where, Tokens), memberchk(is, Tokens),
    resolve_referent(Tokens, State, Object, unique), !.
classify_tokens(Speaker, Tokens, State, intent(Speaker, request, deliver(Object, Speaker))) :-
    delivery_tokens(Tokens),
    resolve_referent(Tokens, State, Object, unique), !.
classify_tokens(Speaker, Tokens, State, intent(Speaker, clarify, object(Category, Candidates, deliver))) :-
    delivery_tokens(Tokens),
    resolve_referent(Tokens, State, Category, ambiguous(Candidates)), !.
classify_tokens(Speaker, Tokens, _, intent(Speaker, request, stop)) :-
    memberchk(stop, Tokens).

delivery_tokens(Tokens) :- memberchk(bring, Tokens) ; memberchk(fetch, Tokens).

phrase_match(Phrase, Tokens) :- append(_, Rest, Tokens), append(Phrase, _, Rest).

resolve_referent(Tokens, State, Object, unique) :-
    findall(Candidate, (object_alias(Candidate, Alias), includes_all(Tokens, Alias), object_location(State, Candidate, _)), Candidates),
    sort(Candidates, [Object]), !.
resolve_referent(Tokens, State, Category, ambiguous(Candidates)) :-
    category_tokens(Category, CategoryTokens),
    includes_all(Tokens, CategoryTokens),
    findall(Candidate, (object_alias(Candidate, Alias), includes_all(Alias, CategoryTokens), object_location(State, Candidate, _)), Raw),
    sort(Raw, Candidates),
    Candidates = [_,_|_].

includes_all(Tokens, Needed) :- forall(member(Token, Needed), memberchk(Token, Tokens)).

formulate_reply(reply_to(greeting, Speaker), _, Text) :-
    format(string(Text), "Hello, ~w.", [Speaker]).
formulate_reply(inform(robot_identity(Name)), _, Text) :-
    format(string(Text), "My name is ~w. I am an MNN humanoid robot.", [Name]).
formulate_reply(inform(current_task(none)), _, "I am currently idle.").
formulate_reply(inform(current_task(Task)), _, Text) :-
    format(string(Text), "I am currently ~w.", [Task]).
formulate_reply(answer(location(Object, Location), Confidence), _, Text) :-
    format(string(Text), "The ~w is at ~w. Confidence ~2f.", [Object, Location, Confidence]).
formulate_reply(answer(location_unknown(Object)), _, Text) :-
    format(string(Text), "I do not know where the ~w is.", [Object]).
formulate_reply(ask_clarification(Category, Candidates), _, Text) :-
    atomic_list_concat(Candidates, ', ', CandidateText),
    format(string(Text), "Which ~w do you mean: ~w?", [Category, CandidateText]).
formulate_reply(confirm(deliver(Object, Person)), _, Text) :-
    format(string(Text), "I will bring the ~w to ~w.", [Object, Person]).
formulate_reply(inform(completed(deliver(Object, Person))), _, Text) :-
    format(string(Text), "I delivered the ~w to ~w.", [Object, Person]).
formulate_reply(refuse(Reason), _, Text) :-
    format(string(Text), "I cannot do that safely: ~w.", [Reason]).
formulate_reply(inform(status(Text0)), _, Text0).
formulate_reply(explain(Text), _, Text).
