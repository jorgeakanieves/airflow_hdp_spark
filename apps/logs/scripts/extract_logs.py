import airflow
import tools as u
import logging
import inspect
import subprocess


def extract_logs(**kwargs):
    logging.info("<o>======================= Start "+ inspect.stack()[0][3] + " method")
    logging.info("<o>======================= Parameters: {0}".format(kwargs))
    config = kwargs['config']
    response = u.extract_logs(config.get('general', 'hdfs_log_path'), config.get('general', 'fs_temp_path'))
    if response == False:
        raise ValueError('Error extracting HDFS logs files')
    globvars = {'move_logs': response}
    logging.info("<o>======================= End "+ inspect.stack()[0][3] + " method")
    return globvars

def move_logs(**kwargs):
    logging.info("<o>======================= Start "+ inspect.stack()[0][3] + " method")
    logging.info("<o>======================= Parameters: {0}".format(kwargs))
    config = kwargs['config']
    globvars = kwargs['task_instance'].xcom_pull(task_ids='extract_logs')
    run = globvars.get('move_logs')
    if run == True:
        response = u.move_logs(config.get('general', 'fs_temp_path'), config.get('general', 'fs_logs_path'))
        if response == False :
            raise ValueError('Error moving log files')
    logging.info("<o>======================= End "+ inspect.stack()[0][3] + " method")
    return globvars
