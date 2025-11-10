Redis memory cache cluster

# Context

The banking application is experiencing high latency in handling frequent read operations, such as product catalog inquiries, campaigns reads, dictionary data reads.
The data is stored in a relational database (Oracle).

The issues of current architecture:
- Increased database load.
- Slower response times under high traffic.
- Difficulty to scale for a good user experience.

Note: Redis is used by other microservices of the bank's applications.