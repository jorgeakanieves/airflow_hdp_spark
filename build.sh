#!/bin/bash
docker build --rm -t aidoc/airflow:1.9.0 .
docker pull postgres:9.6
docker tag postgres:9.6 aidoc/postgres:9.6
docker rmi postgres:9.6
