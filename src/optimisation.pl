:- module(optimisation,
    [ optimise_mnn/4,
      optimise_until_stable/3,
      benchmark_mnn/3
    ]).

:- use_module(library(lists)).
:- use_module(mnn).

optimise_mnn(mnn(Nodes0, Links0, Rules0, Meta), _TrainingExamples, mnn(Nodes, Links, Rules, Meta), Report) :-
    sort(Nodes0, Nodes),
    sort(Links0, Links),
    sort(Rules0, Rules),
    length(Nodes0, N0), length(Nodes, N1),
    length(Rules0, R0), length(Rules, R1),
    (N0 =:= N1, R0 =:= R1 -> Changed = false ; Changed = true),
    Report = optimisation_report{removed_nodes:N0-N1, removed_rules:R0-R1, removed_links:0, changed:Changed}.

optimise_until_stable(MNN0, MNN, Passes) :-
    optimise_until_stable(MNN0, MNN, 0, Passes).

optimise_until_stable(MNN, MNN, Passes, Passes) :- Passes >= 1, !.
optimise_until_stable(MNN0, MNN, Pass0, Passes) :-
    Pass1 is Pass0 + 1,
    optimise_mnn(MNN0, [], MNN1, Report),
    ( Report.changed == false -> MNN = MNN1, Passes = Pass1
    ; Pass1 >= 3 -> MNN = MNN1, Passes = Pass1
    ; optimise_until_stable(MNN1, MNN, Pass1, Passes)
    ).

benchmark_mnn(MNN, Activations, Benchmark) :-
    mnn_stats(MNN, Stats),
    length(Activations, ActivationCount),
    Benchmark = benchmark{nodes:Stats.nodes, links:Stats.links, rules:Stats.rules, activations:ActivationCount}.
