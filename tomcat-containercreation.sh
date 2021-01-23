#!/bin/sh

set -x

output=`docker ps | grep -v "NAMES" | awk '{print $(NF)}' | grep -i tomcat`

if [ "$output" = "tomcat" ];then
        docker stop tomcat
        docker rm tomcat
        docker image rmi purushothamkdr453/tomcat-mavenwebapp
        docker build -t purushothamkdr453/tomcat-mavenwebapp .
        docker push purushothamkdr453/tomcat-mavenwebapp
        docker run -it -d --name tomcat -p 8888:8080 purushothamkdr453/tomcat-mavenwebapp:latest
else
        docker build -t purushothamkdr453/tomcat-mavenwebapp .
        docker push purushothamkdr453/tomcat-mavenwebapp
        docker run -it -d --name tomcat -p 8888:8080 purushothamkdr453/tomcat-mavenwebapp:latest
fi
