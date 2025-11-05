# PoC Results: Kafka-based Payment Notifications

**Setup:**
- Local Kafka cluster using Docker.
- PaymentService publishes events.
- Consumers: NotificationService, FraudService.

**Findings:**
- **Latency:** End-to-end notification delivery avg. 180 ms (vs. 600+ ms in monolith).
- **Reliability:** Messages persisted, replay possible even after consumer crash.
- **Throughput:** Sustained 1,500 msgs/sec without errors.

**Challenges:**
- Developers required training to use Kafka consumer groups.
- Ops complexity higher than RabbitMQ, but manageable with Confluent Cloud.

**Conclusion:**  
PoC supports Kafka as the recommended approach.  