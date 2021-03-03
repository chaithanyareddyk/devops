Installing Jenkins in Ubuntu20.04
--------------------------------------------
sudo apt-get update
apt install default-jre
apt install default-jdk
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add - 
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update  
sudo apt install jenkins
Jenkins password can be found: 

Setting JAVA_HOME path under Global tool -> JDK

Note: To find out JAVA_HOME path run the below command.

sudo update-alternatives --config java

temporarily:

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$JAVA_HOME

permanent:

add the below settings to ~/.bashrc

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$JAVA_HOME
source ~/.bashrc

Installing Maven and adding Maven to Path:
--------------------------
mkdir /opt/maven
wget https://mirrors.estointernet.in/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -xzvf apache-maven-3.6.3-bin.tar.gz
export M2_HOME=/opt/maven/apache-maven-3.6.3
export M2=/opt/maven/apache-maven-3.6.3/bin
export PATH=$PATH:$M2_HOME:$M2

Installing Tomcat:
-----------------------
sudo apt update
sudo apt install openjdk-11-jdk
sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.41/bin/apache-tomcat-9.0.41.tar.gz
sudo tar -xf apache-tomcat-9.0.41.tar.gz -C /opt/tomcat/
sudo ln -s /opt/tomcat/apache-tomcat-9.0.41 /opt/tomcat/latest
sudo chown -R tomcat: /opt/tomcat
sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'

sudo vi /etc/systemd/system/tomcat.service
----------------------------------------------------
[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target

----------------------------------------------

sudo systemctl daemon-reload
sudo systemctl enable --now tomcat
sudo systemctl status tomcat
sudo systemctl start tomcat
sudo ufw allow 8080/tcp

Open the file -> /opt/tomcat/latest/conf/tomcat-users.xml and add the below details under  <tomcat-users>

<role rolename="admin-gui"/>
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<user username="admin" password="admin" roles="admin-gui,manager-gui, manager-script, manager-jmx, manager-status"/>
<user username="deployer" password="deployer" roles="manager-script"/>

Modify the below files

sudo vi /opt/tomcat/latest/webapps/manager/META-INF/context.xml
sudo vi /opt/tomcat/latest/webapps/host-manager/META-INF/context.xml

under <context> add the below to allow specific ip or commment to allow from anyip.

<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1|<your-system-ip>|<jenkins-ip>" />

Note: <your-ip> - replace with your ip(local system) for example: 157.47.2.0
      <jenkins-ip> -> replace with jenkins ip.

sudo systemctl restart tomcat

Integrating Jenkins with Tomcat:
--------------------------------------

Go to Jenkins instance and Install the plugin -> "Deploy to container"

Create Maven Project -> Under "Sourcecode Management" select Git repo, under "Build" Enter Maven goals, under "post build" select deploy to container

Deploying to Tomcat container using Ansible
--------------------------------------------------------------------

Create a new server named "Ansible". Install ansible using below commands.

sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
sudo apt install sshpass
sudo mkdir /opt/playbooks
sudo chown ansadmin:ansadmin  /opt/playbooks

open vi /etc/ansible/hosts and add the below content at the end of the file.

<tomcat-server-ip> ansible_python_interpreter=/usr/bin/python3
172.31.16.192 ansible_python_interpreter=/usr/bin/python3

create new user i.e "ansadmin" in ansible server & tomcat server.

adduser ansadmin

Run the below steps only on Ansible server.

open sudo vi /etc/ssh/sshd_config
PasswordAuthentication yes
systemctl daemon-reload
systemctl restart sshd

add ansadmin to sudoers file and set nopassword setting as follows.(run these steps on both ansible & Tomcat server)

sudo visudo
ALL=(ALL) NOPASSWD:ALL

Now Go to Jenkins install "publish over ssh" plugin
Go to Jenkins -> Configure system -> Publish over ssh (here provide the details of ansible server(i.e private ip, password) with password authentication) -> Test connection

Configure Jenkins Job(Maven Project) -> Go to "PostBuild" select "Publish over ssh" under which select ansible server and move the files to /opt/playbooks

/opt/tomcat/latest/webapps


/usr/local/tomcat/webapps


Deploying application to tomcat using docker:
---------------------------------------------

docker stop tomcat
docker rm tomcat
docker image rmi purushothamkdr453/tomcat-mavenwebapp
docker build -t purushothamkdr453/tomcat-mavenwebapp .
docker push purushothamkdr453/tomcat-mavenwebapp
docker run -it -d --name tomcat -p 8888:8080 purushothamkdr453/tomcat-mavenwebapp:latest
----------------------------------------------------------------
ufw -> Uncomplicated Firewall
https://linuxize.com/post/how-to-install-tomcat-9-on-ubuntu-20-04/
apt install firewalld
sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
sudo firewall-cmd --reload

