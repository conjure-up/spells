#!/usr/bin/env python3

import sys
import yaml
from pathlib import Path


conf_file = Path(sys.argv[1])
model_name = sys.argv[2]

conf_data = yaml.load(conf_file.read_text())
conf_data['users'][0]['name'] = model_name
conf_data['clusters'][0]['name'] = model_name
conf_data['contexts'][0]['name'] = model_name
conf_data['contexts'][0]['context']['cluster'] = model_name
conf_data['contexts'][0]['context']['user'] = model_name
conf_file.write_text(yaml.dump(conf_data))
