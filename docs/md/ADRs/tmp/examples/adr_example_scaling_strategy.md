# ADR Example: Scaling Strategy

Status: proposed
Date: 2025-11-05

## Context
Traffic is projected to grow 10x in next two quarters. Current single-node Postgres will become a bottleneck for read-heavy queries.

## Decision
Introduce read replicas behind a logical replication setup; keep writes on primary. Abstract data access through a read-optimized query layer to enable future caching.

## Alternatives Considered
- Sharding: Too early; operational complexity high.
- Vertical scaling only: Limited headroom; cost grows non-linearly.
- Full caching layer now: Premature; unclear hot set.

## Consequences
Positive: Improves read throughput. Low impact on existing write flows.
Negative: Replica lag risks stale reads for highly volatile data.
Follow-up: Add replica lag monitoring and stale read mitigation for critical paths.

## Implementation Notes
Provision 2 replicas. Update connection pool config to route read-only transactions. Introduce read_router module.

## Validation & Metrics
Monitor replica lag, read query latency p95, primary CPU utilization.

## Open Questions
Should we add automatic query retry on detected lag? When to introduce Redis?

## References
- Growth forecast spreadsheet
- Current DB performance dashboards

