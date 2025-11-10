# Decision
Implement a Redis memory cache cluster as a distributed caching solution for frequently accessed data in the banking application.

Redis will be deployed as a high-availability cluster with:
- Primary-Replica setup for fault tolerance
- Cluster mode enabled for horizontal scalability

Cache invalidation will be managed through:
- Time-to-Live (TTL) policies for short-lived data.
- Event-based data eviction - maybe in the future.