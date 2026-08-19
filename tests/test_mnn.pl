:- begin_tests(mnn).
:- use_module('../src/robot').
:- use_module('../src/mnn').
:- use_module('../src/mnn_activation').
:- use_module('../src/state_utils').
:- use_module('../src/optimisation').
:- use_module('../src/learning').

test(node_activation) :-
    default_mnn(MNN),
    activate_mnn([intent(alex, greet, hello)], MNN, Activations),
    member(rule_activation(greet_person, _, _, _, _), Activations).

test(positive_association) :-
    default_mnn(MNN),
    activate_mnn([requested_object_visible], MNN, Activations),
    member(link_activation(grasp_object, supports, 0.80, requested_object_visible), Activations).

test(inhibition) :-
    default_mnn(MNN),
    activate_mnn([obstacle_detected], MNN, Activations),
    member(link_activation(move_forward, inhibits, 0.95, obstacle_detected), Activations).

test(optimisation) :-
    default_mnn(MNN0),
    optimise_mnn(MNN0, [], _MNN, Report),
    _ = Report.removed_rules.

test(learning_update_link) :-
    new_robot(S0),
    update_link_strength(test_source, test_dest, 0.2, S0, S1),
    get_mnn(S1, mnn(_, Links, _, _)),
    member(mnn_link(test_source, test_dest, supports, 0.7), Links).

:- end_tests(mnn).
