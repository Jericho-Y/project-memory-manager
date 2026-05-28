# Verifier Recipes

Purpose: Suggested verifier choices for common `pmm` task types.
Read when: Defining the Verifier section of `active-task.md` or reviewing completion evidence.
Skip when: The project has a more specific verifier-map entry for the task.

## Default Rule

A verifier must be specific enough to fail. "Looks good" is not a verifier.

## Recipes

| Task type | Minimum verifier | Stronger verifier |
| --- | --- | --- |
| Skill or docs change | line-budget check, link/file existence checks, public safety script | install sync smoke test, release-note consistency check |
| Shell script change | shell syntax check, targeted dry run where safe | public safety script plus isolated smoke test |
| Frontend UI | page opens, core flow works, desktop/mobile visual check | browser screenshot, accessibility pass, interaction test |
| Backend/API | endpoint or unit test, validation path check | success/failure/auth tests plus log check |
| Database | migration dry run or schema inspection | backup/rollback plan and staging validation |
| Auth/payment/permissions | explicit risk review and confirmation boundary | success/failure/abuse path tests plus rollback notes |
| Deployment/release | release checklist, version consistency, rollback path | staged rollout, public artifact verification |
| Recovery | recovery-status helper, workspace inspection | resume from active task and verify no duplicate side effects |
| Agent compatibility | adapter file review, startup path description | run or simulate each target agent's entry path |

## Evidence Format

Record evidence in `active-task.md`:

```text
Verification Evidence:
- Check:
- Result:
- Command or method:
- Remaining risk:
```

If evidence is manual, describe exactly what was inspected.

## False-Pass Checks

Before marking done, ask:
- Did the verifier run after the final change?
- Did any check get deleted or weakened?
- Did the task only update docs while behavior needed implementation?
- Did the task only update implementation while docs/API/contracts changed?
- Did the evidence come from real behavior rather than assumed state?
- Did high-risk work receive the required confirmation?
