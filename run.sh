#!/bin/bash
#docker-compose -f docker-compose-airflow.yml up -d
docker stack deploy -c docker-compose-airflow.yml airflow