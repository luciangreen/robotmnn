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

test(mnn_fixpoint_propagates_rule_conclusions) :-
    new_robot(State0),
    Network = mnn([], [], [
        mnn_rule(seed_rule, [perceived(seed)], [middle], 10),
        mnn_rule(middle_rule, [perceived(middle)], [thought(goal, finish, 0.9)], 10)
    ], meta(test, version(1))),
    set_mnn(State0, Network, State1),
    mnn_fixpoint([seed], State1, State2, Iterations),
    Iterations =:= 3,
    get_mnn(State2, Network),
    State2 = robot_state(_, _, _, Thoughts, _, _, _, _, _),
    memberchk(thought(goal, finish, 0.9), Thoughts).

test(mnn_fixpoint_stops_when_no_new_conclusions) :-
    new_robot(State0),
    Network = mnn([], [], [mnn_rule(unmatched, [perceived(other)], [unused], 10)], meta(test, version(1))),
    set_mnn(State0, Network, State1),
    mnn_fixpoint([seed], State1, State2, Iterations),
    Iterations =:= 1,
    State2 = State1.

test(inhibitory_link_does_not_activate_its_destination) :-
    Network = mnn([], [mnn_link(obstacle, move_forward, inhibits, 0.95)], [
        mnn_rule(move_when_enabled, [perceived(move_forward)], [candidate_action(move_forward)], 10)
    ], meta(test, version(1))),
    activate_mnn_fixpoint([obstacle], Network, Activations, _),
    member(link_activation(move_forward, inhibits, 0.95, obstacle), Activations),
    \+ member(rule_activation(move_when_enabled, _, _, _, _), Activations).

test(mnn_fixpoint_bounds_cycles) :-
    new_robot(State0),
    Network = mnn([], [], [
        mnn_rule(first, [perceived(seed)], [middle], 10),
        mnn_rule(second, [perceived(middle)], [seed], 10)
    ], meta(test, version(1))),
    set_mnn(State0, Network, State1),
    mnn_fixpoint([seed], State1, _, Iterations),
    Iterations =< 5.

test(mnn_fixpoint_honors_iteration_limit) :-
    new_robot(State0),
    Network = mnn([], [],
        [ mnn_rule(first, [perceived(seed)], [stage1], 10),
          mnn_rule(second, [perceived(stage1)], [stage2], 10),
          mnn_rule(third, [perceived(stage2)], [stage3], 10),
          mnn_rule(fourth, [perceived(stage3)], [stage4], 10),
          mnn_rule(fifth, [perceived(stage4)], [stage5], 10),
          mnn_rule(sixth, [perceived(stage5)], [stage6], 10)
        ],
        meta(test, version(1))),
    set_mnn(State0, Network, State1),
    mnn_fixpoint([seed], State1, _, Iterations),
    Iterations =:= 5.

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
