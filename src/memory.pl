:- module(memory,
    [ add_episode/4,
      add_semantic_fact/5,
      recall/3,
      contradictions/2
    ]).

:- use_module(library(lists)).
:- use_module(state_utils).
:- use_module(world_model, [detect_conflicts/2]).

add_episode(Event, Context, State0, State1) :-
    get_episodic(State0, Episodic0),
    length(Episodic0, N),
    Id is N + 1,
    get_time(Now),
    stamp_date_time(Now, DateTime, 'UTC'),
    format_time(atom(Time), '%FT%TZ', DateTime),
    append(Episodic0, [episode(Id, Time, Event, Context, recorded)], Episodic),
    set_episodic(State0, Episodic, State1).

add_semantic_fact(Fact, Confidence, Provenance, State0, State1) :-
    get_semantic(State0, Semantic0),
    append(Semantic0, [semantic_fact(Fact, Confidence, Provenance)], Semantic),
    set_semantic(State0, Semantic, State1).

recall(Query, State, Memories) :-
    get_episodic(State, Episodic),
    get_semantic(State, Semantic),
    findall(match(Score, semantic, Fact),
        ( member(semantic_fact(Fact, Confidence, _), Semantic),
          memory_match(Query, Fact, BaseScore),
          Score is BaseScore + Confidence ),
        SemanticMatches),
    findall(match(Score, episodic, Event),
        ( member(episode(_, _, Event, Context, _), Episodic),
          ( memory_match(Query, Event, BaseScore)
          ; memory_match(Query, Context, BaseScore)
          ),
          Score is BaseScore + 0.2 ),
        EpisodeMatches),
    append(SemanticMatches, EpisodeMatches, Raw),
    sort(1, @>=, Raw, Sorted),
    findall(Item, member(match(_, _, Item), Sorted), Items0),
    prefix_limit(100, Items0, Memories).

memory_match(location(Object), observed(object_at(Object, _)), 1.0).
memory_match(location(Object), learned(object_at(Object, _)), 0.9).
memory_match(current_task, current_task(_), 1.0).
memory_match(Fact, Fact, 1.0).
memory_match(Term, Context, 0.6) :-
    sub_term(Term, Context), !.

prefix_limit(N, List, Prefix) :-
    length(Prefix, N), append(Prefix, _, List), !.
prefix_limit(_, List, List).

contradictions(State, Conflicts) :-
    detect_conflicts(State, Conflicts).
