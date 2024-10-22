import requests
from loguru import logger
import csv

tpl = '''
{
    "id": "server-${server_name}-${ip}",
    "name": "server-${server_name}-${ip}",
    "tags": ["server"],
    "address": ${ip},
    "port": "${port}",
    "meta": {
        "job": "${server_name}"
    },
    "checks": 
    [
        {
            "http": "${health_check_url}",
            "interval": "10s",
            "timeout": "5s"
        }
    ]
}
'''

class ConsulRegister(object):
    def __init__(self, ip, port, server_name, health_check_url):
        self.ip = ip
        self.port = port
        self.server_name = server_name
        self.health_check_url = health_check_url
        self.consul_url = ''
        self.register_url = '' % (self.consul_url, self.server_name)

    def register_to_consul(self,data):
        r = requests.put(self.register_url, data=data)
        if r.status_code != 200:
            logger.error('register to consul failed')
        else:
            logger.info('register to consul success')
        logger.debug(r.text)

    def register(self):
        data = tpl.format(ip=self.ip, port=self.port, server_name=self.server_name, health_check_url=self.health_check_url)

    def read_from_csv(self, csv_file):
        with open(csv_file, 'r') as f:
            reader = csv.reader(f)
            for row in reader:
                self.register_to_consul(row)

