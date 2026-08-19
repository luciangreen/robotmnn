# MNN Format

MNN terms are explicit Prolog structures:

- `mnn_node(Id, Type, InputPattern, OutputPattern)`
- `mnn_link(Source, Destination, Relation, Strength)`
- `mnn_rule(Id, Conditions, Conclusions, Priority)`
- `mnn(Nodes, Links, Rules, Meta)`

Activation produces `rule_activation/5` and `link_activation/4` terms so every selected thought or action can be traced back to concrete symbolic support.
