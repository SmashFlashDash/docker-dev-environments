# docker-dev-environments
This is docker-compose preset for develop, it got:
- Prometheus   
  Data sources by networks: 
  host: localhost:8080
  bridge: dev-service
- Grafana:  
  Security off, have some Spring dashboards.
- Postgres
- Kafka + Zookeeper
- Flink