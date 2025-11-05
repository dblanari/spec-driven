# Meeting Notes: Architecture Decision on Payment Notifications

**Date:** 2025-09-15  
**Attendees:** Denis B., Anna K. (Lead Engineer), Mark S. (Product), Security Rep

**Agenda:** Review options for asynchronous notifications.

### Discussion Points
- Anna: "REST callbacks too fragile under load."
- Mark: "We need guaranteed delivery for regulatory compliance."
- Denis: "Kafka provides replay and durability, RabbitMQ does not."
- Security Rep: "Kafka supports encryption and ACLs, aligns with compliance."

### Decision
Consensus to proceed with Kafka-based event-driven architecture.

### Action Items
- Denis: Draft ADR.
- Anna: Kick off training session for devs.
- Ops team: Investigate Confluent Cloud pricing.  