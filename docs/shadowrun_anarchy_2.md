# Shadowrun Anarchy 2.0 dice bot

This fork adds `ShadowRunAnarchy2` to BCDice. It is based on upstream
`db4287ba536d650717a54b0e2d6a3c7868d78585`. The implementation is written
for BCDice; no Foundry code, rulebook text, or PDF is included.

## Commands

`nSRA[r][@q][A|D]`

- `n`: total dice pool, at least 1.
- `r`: dice replaced with risk dice, from 0 through n.
- `q`: risk reduction (RR), from 0 through 3; defaults to 0.
- `A`: advantage; `D`: disadvantage; omit for a normal test.
- If r is omitted, use the normal-risk recommendation for RR: 2/5/8/12,
  capped at the total pool. Explicit 0 means no risk dice.

Examples: `8SRA`, `8SRA0`, `8SRA3@1`, `8SRA3@1A`, `8SRA3@1D`.
BCDice's standard secret-roll prefix is supported, e.g. `S8SRA3@1`.

The output shows each group of dice sorted separately, total hits, risk-die
ones before and after RR, and complication severity. It reports hits rather
than assigning success/failure flags: no difficulty is supplied and the GM
adjudicates complications. A disaster explicitly warns that the test normally
fails regardless of hits. Severe complications can also cause a GM-imposed
failure. Neither severity is mapped to BCDice critical/fumble flags.

## Rule references

Verified against the French *Shadowrun Anarchy 2.0 — Livre de base*, using
printed page numbers (PDF viewer page numbers are two higher):

| Pages | Implemented rule |
| --- | --- |
| 64–65 | d6 pool; normal hits on 5–6, advantage on 4–6, disadvantage on 6 |
| 70 | Risk dice replace normal dice; hits count twice; only risk-die ones generate complications |
| 70–71 | After RR, 0/1/2/3+ ones mean none/minor/severe/disaster; GM adjudication |
| 71 | RR stacks up to 3; risk dice are freely chosen from 0 to the entire pool; normal-risk recommendations |

Additional scope decisions:

- The input is the final pool; attributes, skills, specializations, wounds,
  range, Essence and equipment are not calculated. In particular, the official
  specialization bonus is +2 dice (p. 64).
- No automatic success or opposed-test resolution is attempted (pp. 64–65).
- The optional alternative risk rule (p. 72) is not implemented.
- This is an initial-roll command. Anarchy rerolls retain the original
  complication, pool, risk-dice count and mode (p. 77). Calling the command
  again computes a new complication and is not a complete Anarchy reroll.
- NPC fixed values (p. 81) and complication suggestion tables are not implemented.
- Japanese complication labels follow the current sra2-ja UI terminology;
  these are not claimed to be an official Japanese translation.

## Validation

```sh
bundle install
bundle exec rake test:dicebots target=ShadowRunAnarchy2,ShadowRun,ShadowRun4,ShadowRun5
bundle exec rubocop
bundle exec rake test
```

`test/data/ShadowRunAnarchy2.toml` contains deterministic cases for success
boundaries in all modes, mixed and all-risk pools, recommended defaults,
RR cancellation, each complication severity, invalid inputs, lowercase input,
secret rolls and common-command compatibility.
