# Optimisation

`optimise_mnn/4` performs deterministic normalisation by removing duplicates from nodes, links and rules.

`optimise_until_stable/3` repeats optimisation until a small bounded fixpoint. The design keeps alternatives explicit and side effects late, making the system suitable for future deterministic compilation work.
