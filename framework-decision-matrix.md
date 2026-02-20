# Framework Decision Matrix

Use this sheet to compare LOVE2D, WxLua, and any alternatives with the same standards.

## How to use

1. Set a weight (1-5) for each criterion based on project importance.
2. Score each framework from 1-5 per criterion.
3. Multiply `weight x score` for weighted points.
4. Add short evidence notes with links, test results, or developer feedback.
5. Recalculate after new findings.

## Candidate frameworks

- LOVE2D
- WxLua
- Alternative 1: ____________________
- Alternative 2: ____________________

## Scoring scale

- 1 = poor fit / major gaps
- 2 = weak fit
- 3 = acceptable
- 4 = strong fit
- 5 = excellent fit

## Weighted matrix

| Criterion | Weight (1-5) | LOVE2D Score (1-5) | LOVE2D Points | WxLua Score (1-5) | WxLua Points | Alt 1 Score | Alt 1 Points | Notes / Evidence |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| Beginner install + first-run success |  |  |  |  |  |  |  |  |
| Developer install + package workflow (`require("tlc")`) |  |  |  |  |  |  |  |  |
| Runtime performance (animation, input responsiveness) |  |  |  |  |  |  |  |  |
| Graphics flexibility (drawing model, effects, canvas/export) |  |  |  |  |  |  |  |  |
| UI needs (native controls, text entry, menus, dialogs) |  |  |  |  |  |  |  |  |
| Hot reload / rapid iteration loop |  |  |  |  |  |  |  |  |
| Error visibility + debugging quality |  |  |  |  |  |  |  |  |
| Cross-platform reliability (macOS/Windows/Linux) |  |  |  |  |  |  |  |  |
| Distribution options (app bundle, LuaRocks, Homebrew) |  |  |  |  |  |  |  |  |
| Long-term maintenance risk (ecosystem activity, API stability) |  |  |  |  |  |  |  |  |
| Testability + CI automation fit |  |  |  |  |  |  |  |  |
| Educational UX (classroom constraints, learning curve) |  |  |  |  |  |  |  |  |
| Total |  |  |  |  |  |  |  |  |

## Evidence log

Record concrete findings here so scoring decisions stay traceable.

| Date | Source / Test | Finding | Affects criterion |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |
|  |  |  |  |

## Risk register

| Risk | Framework(s) affected | Severity (Low/Med/High) | Mitigation |
|---|---|---|---|
|  |  |  |  |
|  |  |  |  |

## Decision gate

Fill this out once scores stabilize.

- Current top option: ____________________
- Confidence (1-5): ____________________
- Biggest unresolved unknown: ____________________
- Next test to de-risk decision: ____________________
- Decision date target: ____________________

## Optional weighting baseline

If you want a default starting point, use these and adjust:

- Beginner install + first-run success: 5
- Developer install + package workflow: 4
- Runtime performance: 4
- Graphics flexibility: 4
- UI needs: 3
- Hot reload / iteration loop: 4
- Error visibility + debugging: 4
- Cross-platform reliability: 5
- Distribution options: 4
- Long-term maintenance risk: 5
- Testability + CI: 3
- Educational UX: 5
