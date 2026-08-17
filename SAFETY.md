# Safety

The safety kernel is independent from ordinary goals.

Current checks include:
- emergency-stop lockout
- obstacle-based movement denial
- restricted-area denial
- unavailable proximity sensor denial
- unsafe grasp denial via semantic facts
- low-battery confirmation requirement

`emergency_stop/3` stops new physical movement, preserves diagnostics and records a structured safety log.
