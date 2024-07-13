# DOCKER-DEV-ENVIRONMENTS
This is docker-compose preset with:
- Prometheus. Set to datasources: 
  - host: localhost:8080
  - bridge: dev-service
- Grafana. Security off, exist some Spring dashboards.
- Postgres
- Kafka + Zookeeper
- Flink
- ELK stack, forked https://github.com/deviantony/docker-elk

## RUN
Run all services by
- `docker compose up -d` - run all containers with default profiles set in `.env` file, by `COMPOSE_PROFILES` value. 
Run services selectively by profiles:
- `docker compose --profile prometheus-grafana up -d`
- `docker compose --profile kafka up -d`
- `docker compose --profile postgres up -d`
- `docker compose --profile elk-setup --profile elk up -d`
- `docker compose --profile develop up -d`

http://localhost:5601/ - kibana ui
http://localhost:3000/ - grafana
http://localhost:9090/ - prometheus

## USEFUL COMMANDS
`docker login`  
`docker-compose down -v`  
`docker container ls`  
`docker container prune`  
`docker volume ls`  
`docker volume prune`  
`docker volume prune -a`  
`docker network ls`  
`docker network prune`  
`docker system prune -a`  

