import requests
from loguru import logger
import csv
import os

tpl = """
{{
"id": "server-{server_name}-{server_ip}",
    "name": "server-{server_name}-{server_ip}",
    "tags": ["server"],
    "address": "{server_ip}",
    "port": {metric_port},
    "meta": {{
        "job": "{server_name}"
    }},
    "checks": 
    [
        {{
            "http": "{health_check_url}",
            "interval": "10s",
            "timeout": "5s"
        }}
    ]
}}
"""

class ConsulRegister(object):
    def __init__(self, consul_url):
        self.tpl = tpl
        self.register_url = f"http://{consul_url}/v1/agent/service/register"
    def set_server_info(self, *row):
        self.server_name, self.server_ip, self.metric_port, self.health_check_ip, self.health_check_port, self.health_check_uri = row
        self.health_check_url = f"http://{self.health_check_ip}:{self.health_check_port}/{self.health_check_uri}"

    def make_template(self):
        res = self.tpl.format(server_name=self.server_name,server_ip=self.server_ip, metric_port=self.metric_port, health_check_url=self.health_check_url)
        return res
    def register_to_consul(self, data):
        logger.debug(f"start to register {self.server_name} - {self.server_ip}")
        headers = {'X-Consul-Token': os.getenv("CONSUL_HTTP_TOKEN")}
        r = requests.put(self.register_url, data=data, headers=headers)
        if r.status_code != 200:
            logger.error('register to consul failed')
        else:
            logger.info('register to consul success')
        logger.debug(r.text)

    def read_from_csv(self, csv_file):
        with open(csv_file, 'r') as f:
            reader = csv.reader(f)
            next(reader)
            for row in reader:
                yield row
           
if __name__ == '__main__':
    cr = ConsulRegister(f'{os.getenv("CONSUL_IP","127.0.0.1")}:8500')
    services = cr.read_from_csv('./service.csv')
    for row in services:
        cr.set_server_info(*row)
        cr.register_to_consul(cr.make_template())


