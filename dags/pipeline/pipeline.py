import airflow
from airflow.operators.bash_operator import BashOperator
from airflow.models import DAG
from datetime import timedelta
import os
import configparser
config = configparser.RawConfigParser()
config.read(os.path.join(os.path.abspath(os.path.dirname(__file__)) + '/pipeline.dev.properties'))


args = {
    'owner': 'airflow',
    'start_date': airflow.utils.dates.days_ago(2),
    'retries': 1,
    'retry_delay': timedelta(seconds=60)
}

dag = DAG(
    dag_id='pipeline_spark', default_args=args,
    schedule_interval=config.get('general', 'schedule_interval'),
    dagrun_timeout=timedelta(minutes=60))

run_this_first = BashOperator(
    task_id='env', bash_command='env', dag=dag)

sparksubmit_cmd = "/usr/local/airflow/apps/pipeline/launchYarn.sh "
run_this = BashOperator(
    task_id='run_after_loop', bash_command=sparksubmit_cmd, dag=dag)

run_this_first.set_downstream(run_this)

if __name__ == "__main__":
    dag.cli()