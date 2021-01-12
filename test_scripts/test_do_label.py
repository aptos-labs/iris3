import json

from test_scripts.utils_for_tests import do_local_http

project = 'joshua-playground-host-vpc'
plugins = 'Subscriptions,Cloudsql,Bigtable,Gcs,Bigquery,Instances,Disks,Snapshots'
plugins = 'Subscriptions'#,Cloudsql,Bigtable,Gcs,Bigquery,Instances,Disks,Snapshots'

for plugin in plugins.split(','):
    contents = json.dumps({'project_id': project, 'plugin': plugin})
    do_local_http('do_label', contents)