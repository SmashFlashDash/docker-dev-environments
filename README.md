# DOCKER-DEV-ENVIRONMENTS
This is docker-compose preset with:
- Prometheus. Set to datasources: 
  - host-driver: localhost:8080
  - bridge-driver: dev-service:8080
- Grafana. Security off, exist some Spring dashboards.
- Postgres
- Kafka + Zookeeper
- Flink, forked https://github.com/mbode/flink-prometheus-example
- ELK stack, forked https://github.com/deviantony/docker-elk

## RUN
Run all services by
- `docker compose up -d` - run all containers with default profiles set in `.env` file, by `COMPOSE_PROFILES` value. 
Run services selectively by profiles:
- `docker compose --profile prometheus-grafana up -d`
- `docker compose --profile kafka up -d`
- `docker compose --profile postgres up -d`
- `docker compose --profile flink build` - Build Flink image.  
- `docker compose --profile flink up -d` - Flink cluster: 1 jobmanger, 1 taskamanger.
- `docker compose --profile flink --profile flink-sql up -d` - Flink sql-client  
- `docker compose --profile elk-setup --profile elk up -d`
- `docker compose --profile develop up -d`


## UI
http://localhost:9090/ - prometheus  
http://localhost:3000/ - grafana, sign in for edit dashboards  
http://localhost:8081/ - flink jobmanager ui  
http://localhost:5601/ - kibana ui  


## Flink submit job
Taskmanagers can be scaled `docker compose scale flink-taskmanager=<N>` or use `scale` parameter in compose file.
You can submit a job to session cluster by few ways:
- flink Monitoring plugin via IJIdea Ultimate
- flink REST API, build your jar and deploy it with [submit_flink_job.sh](configs/flink/submit_flink_job.sh)
- manually copy the JAR to the JobManager container and submit the job using the CLI from there:
  Example with example dist jar
  ```shell
  docker exec flink-jobmanager  flink run --detached /opt/flink/examples/streaming/WordCount.jar
  ```
  Example add
  ```shell
  JOB_CLASS_NAME="com.job.ClassName"
  JM_CONTAINER=$(docker ps --filter name=jobmanager --format={{.ID}}))
  docker cp path/to/jar "${JM_CONTAINER}":/job.jar
  docker exec -t -i "${JM_CONTAINER}" flink run -d -c ${JOB_CLASS_NAME} /job.jar
  ```

## TROUBLE_SHOOT
Tune some `.wslconfig` for manage resources [configure-wslconfig](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configure-global-options-with-wslconfig)


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
`docker compose --profile flink --profile prometheus-grafana up -d`  
`docker-compose --profile flink build` - rebuild image
`docker-compose --profile flink down -v`  
`docker image history --no-trunc flink-built > tmp.txt` - watch dockerfile history  

