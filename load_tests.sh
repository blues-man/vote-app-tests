#!/bin/bash

for i in {1..50}; do 
    tkn pipeline start vote-app-api-pipeline -w name=app-source,claimName=workspace-api-app-source --use-param-defaults -n vote-app-ci-user$i;
    tkn pipeline start vote-app-ui-pipeline -w name=app-source,claimName=workspace-ui-app-source --use-param-defaults -n vote-app-ci-user$i;
    gitea=`oc get route gitea -o template --template={{.spec.host}} -n gitea`;
    webhook=`oc get route el-ui -o template --template="{{.spec.host}}" -n vote-app-ci-user$i`;
    USERNAME=user$i PASSWORD=openshift GITEA=http://$gitea WEBHOOK=http://$webhook python webhook.py

    argocd app create vote-app-dev-user$i --repo https://$gitea/user$i/vote-app-gitops --path environments/dev --dest-namespace vote-app-dev-user$i --dest-server https://kubernetes.default.svc 


    workspace=`oc get pods -o=jsonpath="{range .items[*]}{.metadata.name}" -n user$i-devspaces`
    oc -n user$i-devspaces rsh -c python $workspace sed -i 's/<h1>{{option/<h1>Red Hat Summit 2023 {{option/'  vote-ui-python/templates/index.html
    oc -n user$i-devspaces rsh -c python $workspace pip install -r vote-ui-python/requirements.txt
    oc -n user$i-devspaces rsh -c python $workspace python /projects/vote-ui-python/app.py & disown
    oc -n user$i-devspaces rsh -c python $workspace git -C /projects/vote-ui-python add .
    oc -n user$i-devspaces rsh -c python $workspace git -C /projects/vote-ui-python commit -m "test for user$i"
    oc -n user$i-devspaces rsh -c python $workspace git -C /projects/vote-ui-python push origin master
    
    tkn pipeline start promote-to-prod --use-param-defaults -w name=app-source,emptyDir= -n vote-app-ci-user$i;

    argocd app create vote-app-prod-user$i --repo https://$gitea/user$i/vote-app-gitops --path environments/prod --dest-namespace vote-app-prod-user$i --dest-server https://kubernetes.default.svc

done
