##########################################################
1.docker启动服务

docker save -o  openjdk.tar 314a09fd7b45 

docker load --input openjdk.tar     //首先load  openjdk.tar openjdk镜像

docker tag  314a09fd7b45  openjdk:8.0.72   //给openjdk镜像命名

docker build -t smartsight-agentcontroller .  //在当前目录下通过Docfile创建smartsight的镜像

docker run --name nginx-test -it -p 10080:80 10.63.240.209:5000/nginx:alpine //前台运行docker镜像
docker run --name nginx-test -d -p 10080:80 10.63.240.209:5000/nginx:alpine //后台运行docker镜像

docker exec -it fbc /bin/sh        //用来进入docker进程内部

查看日志： docker logs -t -f 9bfea30999a4
 
netstat -an                       //查看网络状态
netstat -an:grep 80   

##########################################################
2.git提交代码
    git status    //查看下修改状态
	git pull
	git add .
	git commit -m "bugfixed"
	git push
	
	切换分支提交代码
	(1) 先拉master代码
    git clone https://github.com/jacklife/tools.git
	(2) 将远程分支在本地别名化，注意本地分支名与远程分支名字相同
	git branch 16.20 origin/16.20
	(3) 切换到对应的分支进行开发
	git checkout 16.20
	git branch -v
	git branch -vv
	(4)修改完代码 ，提交
	git status
	git pull
	git branch -v
	git add .
	git commit -m "bugfix"
	git review -R -v release-V16.18.20
	
	git关联已有目录到远程目录
	git init
    git remote add origin git@gitlab.zte.com.cn:SmartSight/elasticsearch.git
    git  add .
    git commit
    git status
    git commit -m "build project"
   git push -u origin master

##########################################################
3.启动agent

java -jar  -Djava.security.egd=file:/dev/./urandom  -javaagent:/home/test-bootstrap.jar -Dtest.agentId=test_A -Dtest.applicationName=test_A -DcollectorIp=192.168.0.117 -DlogstashIp=192.168.0.117  servicea-1.0.0.jar

java -jar  -Djava.security.egd=file:/dev/./urandom -javaagent:/home/smartsight-agent/smartsight-bootstrap.jar -Dsmartsight.agentId=boot_B -Dsmartsight.applicationName=boot_B -DcollectorIp=192.168.0.117 -DlogstashIp=192.168.0.117  serviceb-1.0.0.jar

java -jar  -Djava.security.egd=file:/dev/./urandom -javaagent:/home/smartsight-agent/smartsight-bootstrap.jar -Dsmartsight.agentId=boot_C -Dsmartsight.applicationName=boot_C -DcollectorIp=10.62.127.137 -DlogstashIp=10.62.127.137  servicec-1.0.0.jar



java -jar -Djava.security.egd=file:/dev/./urandom   webui-1.0.0.jar
// testapp的接口为5010




##########################################################
4.远程拷贝scp
scp 10.62.127.136:/home/testapp/service/* .   从远程拷贝到本地
scp - r testapp root@10.62.127.137:/home      从本地拷贝到远程


scp 10.62.127.136:/home/apm/standalone/SMARTSIGHT_V1.17.40_B43_20171123111714.tar.gz .

scp -r 10.62.127.88:/root/workspace/kafkademo .



##########################################################
5.解压
*.tar 用 tar –xvf 解压
*.gz 用 gzip -d或者gunzip 解压
*.tar.gz和*.tgz 用 tar –xzf 解压
*.bz2 用 bzip2 -d或者用bunzip2 解压
*.tar.bz2用tar –xjf 解压
*.Z 用 uncompress 解压
*.tar.Z 用tar –xZf 解压
.rar 用 unrar e解压
*.zip 用 unzip 解压

压缩

01-.tar格式
解包：[＊＊＊＊＊＊＊]$ tar xvf FileName.tar
打包：[＊＊＊＊＊＊＊]$ tar cvf FileName.tar DirName（注：tar是打包，不是压缩！）
02-.gz格式
解压1：[＊＊＊＊＊＊＊]$ gunzip FileName.gz
解压2：[＊＊＊＊＊＊＊]$ gzip -d FileName.gz
压 缩：[＊＊＊＊＊＊＊]$ gzip FileName

03-.tar.gz格式
解压：[＊＊＊＊＊＊＊]$ tar zxvf FileName.tar.gz
压缩：[＊＊＊＊＊＊＊]$ tar zcvf FileName.tar.gz DirName
tar zcvf FileName.tar.gz DirName

##########################################################
6.docker配置仓库，拉取镜像
vi /etc/default/docker 
service docker restart
docker pull 
docker run -d -p 18080:8080 -p 50000:50000 -v /var/lib/volumes/jenkins:/var/jenkins_home -v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime -v /etc/timezone:/etc/timezone  --restart=always 10.62.127.132:9999/jenkins:2.11
docker images 

docker run --name nginx-test -d -p 10080:80 10.63.240.209:5000/nginx:alpine //后台运行docker镜像
docker run --name apache -d -p 10080:8010.62.127.132:9999/eboraas/apache:latest//后台运行docker镜像
docker run --name nginx-test -d -p 10080:80 10.62.127.132:9999/eboraas/apache

docker run --name apache -d -p 10080:80 -v /home:/var/www/html 10.62.127.132:9999/eboraas/apache

 docker run --name apache -d -p 10080:80 -v /home:/var/www/html:ro  10.62.127.132:9999/eboraas/apache
 
 ##########################################################
7.新开vnc窗口命令，关闭窗口命令

vncserver -geometry 1440x900
vncserver -kill :2


vncserver:2 -geometry 1440x900
 
cd /var/lib/lib/volumes/jenkins/
ls
cd /var/lib/
rm -rf lib
ls
mkdir -p volumes/jenkins
cd volumes/
ls
chmod -R 777 jenkins/
ls


##########################################################
8  Ubuntu查看端口使用情况，使用netstat命令：

查看已经连接的服务端口（ESTABLISHED）

netstat -a

查看所有的服务端口（LISTEN，ESTABLISHED）

netstat -ap

查看指定端口，可以结合grep命令：

netstat -ap | grep 8080

 也可以使用lsof命令：

lsof -i:8888

若要关闭使用这个端口的程序，使用kill + 对应的pid

kill -9 PID号

9  kafka   &    logstash常用命令

./kafka-server-start.sh ../config/server.properties &    //启动kafka（无zookeeper的话要先启动zookeeper）

./kafka-topics.sh --list --zookeeper localhost:2181     //列出kafka所有topic

./bin/logstash -f ./config/logstash.conf &     //用配置文件启动logstash   & 表示后台启动

du -sh --max-depth=1  #查看当前目录下所有一级子目录文件夹大小
du -h --max-depth=1 |sort    #查看当前目录下所有一级子目录文件夹大小 并排序

10 挂载硬盘
df -hl 查看磁盘剩余空间
df -h 查看每个根路径的分区大小
du -sh [目录名] 返回该目录的大小
du -sm [文件夹] 返回该文件夹总M数

查看硬盘列表

sudo fdisk -l
为新硬盘添加分区

sudo fdisk /dev/sdb 
n：添加新分区 
p：使用主分区 
l：主分区编号为1，这样创建的分区为sdb1
格式化新分区

sudo mkfs ext4 /dev/sdb1 #使用ext4格式化sdb1分区
随意创建一个文件夹，将新分区挂载上去

sudo mkdir /disk2 
sudo mount /dev/sdb1 /disk2 #将sdb1挂载到/disk2文件夹上
设置开机自动挂载

sudo vim /etc/fstab 
加入如下： 
/dev/sdb1 /disk2 ext4 defaults 0 1

11 linux常用命令

. /etc/profile
source /etc/profile  保存环境变量

