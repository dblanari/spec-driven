# Exploration Document: Modernizing Payment Notification Processing (RFC-style)

**Date:** 2025-09-10  
**Author:** Denis Blanari  
**Audience:** Architecture Guild, Payment Platform Team  

## Problem
The legacy monolith processes notifications synchronously:
- High latency for downstream services (fraud detection, reporting).
- Frequent failures during peak loads.
- No reliable replay mechanism.

## Goals
- Decouple services via asynchronous messaging.
- Provide guaranteed delivery & audit trail.
- Enable scaling independently for producers/consumers.

## Options
1. **Continue with synchronous REST callbacks**  
   - Pros: Simple, minimal new infra.  
   - Cons: Still fragile, doesn’t scale.  

2. **RabbitMQ**  
   - Pros: Team has prior experience, lightweight.  
   - Cons: No built-in replay, limited scalability.  

3. **Kafka (event-driven)**  
   - Pros: Partitioning, replay, strong ecosystem, proven in FinTech.  
   - Cons: Steeper learning curve, more infra to manage.  

## Early Analysis
Kafka aligns with long-term strategy of microservices adoption. Managed Kafka (e.g., Confluent Cloud) can mitigate infra burden.  