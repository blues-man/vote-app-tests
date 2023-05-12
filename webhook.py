 #!/usr/bin/env python3

import os
import requests 


gogs_user = os.getenv('USERNAME')
gogs_pwd = os.getenv('PASSWORD')

#webhookURL = "http://" + os.popen("oc get route el-ui -o template --template=\"{{.spec.host}}\" -n vote-app-ci-$gogs_user").read()
webhookURL = os.getenv('WEBHOOK')
gogsURL = os.getenv('GITEA')



# configure webhook on app repo
data_webhook = '{"type": "gitea", "config": { "url": "' + webhookURL + '", "content_type": "json"}, "events": ["push"], "active": true}'
headers = {'Content-Type': 'application/json'}

print(gogs_user + " " + gogs_pwd + " " + gogsURL + " " + data_webhook)
resp = requests.post(url = gogsURL + "/api/v1/repos/" + gogs_user + "/pipelines-vote-ui/hooks", 
                    headers = headers, 
                    auth = (gogs_user, gogs_pwd), 
                    data = data_webhook) 

if resp.status_code != 200 and resp.status_code != 201:
    print("Error configuring the webhook (status code: {})".format(resp.status_code))
    print(resp.content)
else:
    print("Configured webhook: " + webhookURL)


