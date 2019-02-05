import airflow
import unittest
import os
import sys
import configparser
config = configparser.RawConfigParser()
config.read(os.path.join(os.path.abspath(os.path.dirname(__file__)) + '/../../../dags/extract_logs/extract_logs.deploy.dev.properties'))
apps_path=config.get('general', 'apps_path')
sys.path.insert(0, apps_path)
import extract_logs as lgs

# python -m unittest testsIngest.TestsIngest.test_unzip

class TestsLogs(unittest.TestCase):

    #@unittest.skip("suite skipping")
    def test_extract_logs(self):
        lgs.extract_logs(config=config)
        #self.assertTrue(len(files)>0, True)

    def test_move_logs(self):
        lgs.move_logs(config=config)

    #def setUp(self):

if __name__ == '__main__':

    unittest.main()