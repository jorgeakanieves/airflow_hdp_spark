import airflow
from airflow import DAG
from airflow.operators.python_operator import PythonOperator
import os
import sys
import configparser
config = configparser.RawConfigParser()
config.read(os.path.join(os.path.abspath(os.path.dirname(__file__)) + '/extract_logs.dev.properties'))
apps_path=config.get('general', 'apps_path')
sys.path.insert(0, apps_path)
import extract_logs as hks



args = {
    'owner': 'airflow',
    'start_date': airflow.utils.dates.days_ago(2),
    'email': ['toadmin@admin.com'],
    'email_on_failure': ['toadmin@admin.com'],
    'provide_context': True
}

dag = DAG(
    'logs_pipeline',
    schedule_interval=config.get('general', 'schedule_interval'),
    default_args=args)


extract_logs = PythonOperator(dag=dag,
                               task_id='extract_logs',
                               #provide_context=True,
                               python_callable=hks.extract_logs,
                               #op_args=['arguments_passed_to_callable'],
                               op_kwargs={'config':config}
                               )

move_logs = PythonOperator(dag=dag,
                                  task_id='move_logs',
                                  python_callable=hks.move_logs,
                                  provide_context=True,
                                  trigger_rule="all_success",
                                  op_kwargs={'config':config}
                                )

extract_logs >> move_logs
