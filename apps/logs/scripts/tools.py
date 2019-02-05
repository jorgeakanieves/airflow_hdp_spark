import logging
import os, sys, time, re
from shutil import move, copyfile, rmtree
from subprocess import Popen, PIPE
from os.path import normpath, basename,isfile

def extract_logs(dir_start, dir_end):
    logging.info("<o>======================= Cleaning log path " + dir_end)
    try:
        rmtree(dir_end)
    except IOError as e:
        print(e.errno)

    logging.info("<o>======================= Extracting log files from " + dir_start + " to " + dir_end)
    process = Popen('hdfs dfs -get ' + dir_start + ' ' + dir_end,shell=True,stdout=PIPE, stderr=PIPE)
    std_out, std_err = process.communicate()
    if not std_err:
        return True
    else :
        return False


def move_logs(dir_start, dir_end):
    logging.info("<o>======================= Moving log files from " + dir_start + " to " + dir_end)
    for dirname, dirnames, filenames in os.walk(dir_start):
        for file in filenames:
            filedest= basename(normpath(dirname)) + '-yarn-spark.log'
            filepath = os.path.join(dirname, file)

            if not isfile(filedest):
                try:
                    move(filepath, os.path.join(dir_end,filedest))
                except IOError as e:
                    print(e.errno)
                    print(e)
                    return False

    rmtree(dir_start)
    return True

