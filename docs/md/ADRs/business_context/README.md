# Business Context

Purpose:
Provide domain background so ADR decisions align with real constraints and goals.

## Solution Context: AI-Powered ADR Generation and Validation Assistant
Goal: Automate high-quality, template-compliant ADRs via CustomGPT with faster turnaround, explicit assumptions, and full traceability.

Drivers:
- Manual ADRs slow / inconsistent.
- Missing assumptions & validation.
- Stale docs hurt onboarding & governance.
- Hard to enforce uniform quality.

Stakeholders: Architecture (govern), Engineering squads (produce/use), Compliance/Risk (audit), Product (visibility), ML/Platform (model ops).

Operational Modes:
1. Input Analysis – Parse artifacts (prompts, diffs, tickets) → extract context, constraints, quality attributes, risks.
2. ADR Drafting – Generate structured ADR (Title, Status, Context, Decision, Consequences, Assumptions) + inferred assumptions.
3. Validation – Compare to exemplars → score completeness, template conformity, terminology consistency → produce Validation Summary.

Lifecycle: Input Package → Parsed Context → Draft ADR → Validated ADR → Published ADR → Archived (superseded). Assumptions catalog accumulates reusable assumptions.

Non-functional Priorities:
- Accuracy (constraint extraction).
- Latency <10s typical set.
- Availability ≥99.5%.
- Traceability (artifact hashes).
- Data isolation (sandboxed model).
- Observability (gen + validation metrics).

Compliance:
- Secure handling of proprietary artifacts.
- Audit log (input, output, scores).
- Explainability (source snippet links).

Risks & Mitigations:
- Prompt injection / artifact poisoning → sanitization + controlled retrieval.
- Hallucinated assumptions → source citation + reviewer flag.
- Template drift → version tagging + regression tests.

KPIs:
- Generation time reduction.
- Template compliance ≥95%.
- Validation precision.
- Assumptions detected / ADR.
- Adoption ratio.
- Freshness (% ADRs updated within SLA).
- Lightweight satisfaction score.

Integration Boundaries:
- VCS (diffs, PR metadata)
- Ticketing (Jira/Linear)
- ADR repository (exemplars)
- Policy/Secrets store
- Notification (Slack)

Pain Points (condensed):
- Siloed tacit knowledge.
- Undocumented reasoning → rework.
- Format inconsistency.
- Low discoverability.

Guidelines:
- Keep business focus; exclude low-level implementation.
- Update modes if workflow changes.
- Review KPIs quarterly; retire unused.
