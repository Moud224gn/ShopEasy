<!--
Thank you for contributing to ShopEasy.
This template mirrors the Definition of Done (CLAUDE.md §18).
Every box should be intentionally checked, not skipped.
-->

## Description

<!-- What does this PR do? Why is it needed? Reference issue(s). -->

Closes #

## Type of change

<!-- Mark with [x] -->

- [ ] `feat` — New feature (user-facing or internal capability)
- [ ] `fix` — Bug fix (no behavior change other than fixing the bug)
- [ ] `refactor` — Code restructuring without behavior change
- [ ] `perf` — Performance improvement with measured baseline
- [ ] `docs` — Documentation only
- [ ] `test` — Test additions or corrections
- [ ] `chore` / `build` / `ci` — Infrastructure or tooling
- [ ] `security` — Security fix or hardening

## Definition of Done — Self-checklist

<!-- Required. Tick only what is genuinely true. If something is N/A, write "N/A" with a one-line justification. -->

### Code & Tests
- [ ] Tests written **before** implementation (TDD — CLAUDE.md §11.1)
- [ ] Local coverage on touched modules ≥ 85% (or justified deviation)
- [ ] All tests pass locally (`make test-api` + `make test-web`)
- [ ] No new `TODO` / `FIXME` without linked GitHub issue
- [ ] No new `any` (TypeScript) without inline justification
- [ ] No new `print()` / `console.log()` left in code
- [ ] No new hardcoded value: currency, locale, magic number, secret

### Documentation
- [ ] Public APIs documented (docstrings, drf-spectacular descriptions)
- [ ] User-facing changes documented in `docs/` if applicable
- [ ] ADR added or updated for non-trivial architectural decisions
- [ ] Runbook updated for operational changes (`docs/runbooks/`)

### Internationalization (i18n)
- [ ] No hardcoded user-facing strings (validated by `make i18n-check`)
- [ ] Both FR and EN translations present for any new key
- [ ] Dates, numbers, currencies formatted via `useFormatter` / `intl`
- [ ] No hardcoded currency code or symbol

### Accessibility (a11y)
- [ ] WCAG 2.1 AA respected on new UI (semantic HTML, ARIA, keyboard, contrast)
- [ ] Tested with screen reader perspective in mind
- [ ] axe-core violations: 0 (validated by `make test-a11y`)
- [ ] Lighthouse a11y score ≥ 95 on affected routes

### Right-to-Left (RTL)
- [ ] Logical properties used (`ms-*`, `me-*`, `text-start`) — no `ml-*`, `mr-*`, `text-left`
- [ ] Directional icons handled (`rtl:rotate-180` where applicable)
- [ ] Snapshots `make test-rtl` not regressed

### Security
- [ ] Input validation on all new endpoints and forms
- [ ] No new secret in code (verified by `make security`)
- [ ] AuthN/AuthZ checks on new sensitive operations
- [ ] Audit log emitted on relevant business changes

### Performance
- [ ] Bundle JS impact measured if frontend (acceptable under `< 150kB` first paint budget)
- [ ] No new N+1 query (verified by Django Debug Toolbar or `make perf-audit`)
- [ ] Cache strategy applied where appropriate

### Validation
- [ ] `make pre-push` passes locally (marker `.pre-push-pass` recent)
- [ ] PR scope is minimal — touches only what's needed (no scope creep)
- [ ] Commits follow Conventional Commits format (CLAUDE.md §13)
- [ ] Self-review done via [`code-reviewer`](.claude/agents/code-reviewer.md) agent

## How to test

<!-- Step-by-step manual verification. Include URLs, credentials, scenarios. -->

1.
2.
3.

## Screenshots / Videos

<!-- For UI changes. Include before/after when applicable. Include RTL screenshot if frontend. -->

## Risk assessment

<!-- What could break? What's the rollback strategy? -->

- **Blast radius**:
- **Rollback strategy**:
- **Monitoring**: 

## Reviewer notes

<!-- Anything the reviewer should focus on or be aware of. -->

---

<sub>This PR template is enforced. Skipping checks without justification is grounds for review rejection.</sub>
