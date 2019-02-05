import airflow
import unittest
import os
import sys
import configparser
config = configparser.RawConfigParser()
config.read(os.path.join(os.path.abspath(os.path.dirname(__file__)) + '/../../../dags/ingest/ingest.dev.properties'))
apps_path=config.get('general', 'apps_path')
sys.path.insert(0, apps_path)
import ingest as ing
import tools as t

# python -m unittest testsIngest.TestsIngest.test_unzip


class TestsIngest(unittest.TestCase):

    #@unittest.skip("suite skipping")
    # def test_unzip(self):
    #     ing.unzip(config=config)
    #     #self.assertTrue(len(files)>0, True)
    #
    # def test_extract_files(self):
    #     ing.extract_files(config=config)

    def test_move_hdfs(self):
        ing.move_hdfs(config=config)

    def test_add_procedures(self):
        t.create_docs_elk('/apps/nfs/data-input/pdf/', 450, 'Error al mover ficheros a HDFS')

    #def setUp(self):

if __name__ == '__main__':

    unittest.main()