# ADR 001: Initial Service Architecture

Status: accepted
Date: 2025-11-05

## Context
We need a modular service architecture enabling incremental domain expansion. Constraints: small team, need rapid iteration, prefer language-agnostic boundaries, low operational overhead.

## Decision
Adopt a hexagonal architecture with clear inbound (HTTP/CLI) adapters and outbound (DB/external API) ports. Use Postgres as primary store. Introduce a lightweight domain layer with explicit value objects.

## Alternatives Considered
- Monolithic layered architecture: simpler initially, but risks tight coupling and hard domain isolation.
- Microservices: high operational overhead for current team size.
- Serverless functions: fast to start, but harder to express rich domain invariants and transactionality.

## Consequences
Positive: Clear domain boundaries, testable ports, easier future extraction of services.
Negative: Slight upfront complexity. Requires discipline around port abstractions.
Trade-offs: Accept a moderate abstraction cost now for long-term modularity.

## Implementation Notes
Directory layout: /domain, /adapters/http, /adapters/db.
Ports: Repository interfaces defined in domain layer.
Migration: Seed schema via versioned SQL migrations.

## Validation & Metrics
Track deployment lead time, change failure rate, and test coverage of domain layer.

## Open Questions
Should we introduce CQRS for read scalability? How to model cross-cutting concerns (audit, metrics)?

## References
- Prior design spike doc
- Evolution roadmap

