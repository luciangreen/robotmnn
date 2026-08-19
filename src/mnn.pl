:- module(mnn,
    [ default_mnn/1,
      mnn_nodes/2,
      mnn_links/2,
      mnn_rules/2,
      mnn_stats/2
    ]).

default_mnn(mnn(Nodes, Links, Rules, meta(name(default), version(1)))) :-
    Nodes = [
        mnn_node(heard_greeting, percept, intent(_, greet, hello), thought(dialogue, greet(_), 0.95)),
        mnn_node(heard_identity_question, percept, intent(_, question, robot_identity(name)), thought(dialogue, answer_name, 0.96)),
        mnn_node(heard_task_question, percept, intent(_, question, current_task), thought(dialogue, answer_current_task, 0.90)),
        mnn_node(heard_location_question, percept, intent(_, question, location(_)), thought(dialogue, answer_location(_), 0.90)),
        mnn_node(heard_delivery_request, percept, intent(_, request, deliver(_, _)), thought(goal, deliver(_, _), 0.92)),
        mnn_node(heard_ambiguous_request, percept, intent(_, clarify, object(_, _, _)), thought(question, clarification(_), 0.93)),
        mnn_node(obstacle_detected, percept, obstacle(_), thought(concern, collision_possible(_), 0.98)),
        mnn_node(low_battery, percept, battery_low, thought(concern, low_battery, 0.97)),
        mnn_node(repeated_failure, meta, repeated_failure(_, _), thought(reflection, repeated_action(_, _), 0.88)),
        mnn_node(move_forward, action, move_to(_), candidate_action(move_to(_)))
    ],
    Links = [
        mnn_link(obstacle_detected, move_forward, inhibits, 0.95),
        mnn_link(requested_object_visible, grasp_object, supports, 0.80),
        mnn_link(heard_delivery_request, delivery_goal, supports, 0.90),
        mnn_link(low_battery, wait_action, supports, 0.70)
    ],
    Rules = [
        mnn_rule(greet_person,
            [perceived(intent(Speaker, greet, hello)), not_recently(greeted(Speaker))],
            [thought(dialogue, greet(Speaker), 0.95), candidate_action(say(Speaker, greeting(Speaker)))],
            70),
        mnn_rule(answer_name,
            [perceived(intent(Speaker, question, robot_identity(name)))],
            [thought(dialogue, answer_name(Speaker), 0.96), candidate_action(say(Speaker, answer(robot_name)))],
            75),
        mnn_rule(answer_current_task,
            [perceived(intent(Speaker, question, current_task))],
            [thought(dialogue, answer_current_task(Speaker), 0.90), candidate_action(say(Speaker, answer(current_task)))],
            74),
        mnn_rule(answer_location,
            [perceived(intent(Speaker, question, location(Object)))],
            [thought(dialogue, answer_location(Speaker, Object), 0.91), candidate_action(say(Speaker, answer(location(Object))))],
            76),
        mnn_rule(propose_delivery_goal,
            [perceived(intent(Speaker, request, deliver(Object, Speaker)))],
            [thought(goal, deliver(Object, Speaker), 0.92), candidate_goal(deliver(Object, Speaker))],
            80),
        mnn_rule(ambiguous_request,
            [perceived(intent(Speaker, clarify, object(Category, Candidates, deliver)))],
            [thought(question, clarify_object(Speaker, Category, Candidates), 0.94), candidate_action(say(Speaker, ask_clarification(Category, Candidates)))],
            88),
        mnn_rule(safety_stop,
            [perceived(obstacle(Path))],
            [thought(concern, collision_possible(Path), 0.98), candidate_action(stop)],
            100),
        mnn_rule(low_battery_pause,
            [battery_below(20)],
            [thought(concern, low_battery, 0.97), candidate_action(wait(1))],
            95),
        mnn_rule(repeated_failure_help,
            [meta(repeated_failure(Action, Count)), threshold(Count, 2)],
            [thought(reflection, repeated_action(Action, Count), 0.88), candidate_action(say(operator, request_assistance(Action)))],
            72)
    ].

mnn_nodes(mnn(Nodes, _, _, _), Nodes).
mnn_links(mnn(_, Links, _, _), Links).
mnn_rules(mnn(_, _, Rules, _), Rules).

mnn_stats(mnn(Nodes, Links, Rules, _), stats{nodes:NodeCount, links:LinkCount, rules:RuleCount}) :-
    length(Nodes, NodeCount),
    length(Links, LinkCount),
    length(Rules, RuleCount).
