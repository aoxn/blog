title: 基于haproxy和keepalived的高可用的私有docker registry 
date: 2015-11-04 22:02:11
tags: ["Docker","Registry"]
categories: ["容器","Docker"]
---

本文用于搭建一个基于haproxy和keepalived的高可用的私有docker registry

## 部署结构

* haproxy keepalived 主：221.228.86.4
* haproxy keepalived 备：221.228.86.5
* docker registry 1：    221.228.86.6
* docker registry 2：    221.228.86.67
* VIP : 221.228.86.70 

```bash
                    221.228.86.100
             +-----------VIP----------+   
             |                        |
             |                        |
           Master                   Backup
        221.228.86.4             221.228.86.6
        +----------+             +----------+
        | HAProxy  |             | HAProxy  |
        |keepalived|             |keepalived|
        +----------+             +----------+
             |  
             v  
    +--------+---------+ 
    |        |         |
    |        |         |
    v        v         v
+------+  +------+  +------+
| WEB1 |  | WEB2 |  | WEB3 |
+------+  +------+  +------+
```

<!-- more -->

#### 修改docker daemon 启动参数 
```bash
修改/etc/default/docker文件，在DOCKER_OPTS="--insecure-registry vip:5000"
```

## Docker Registry 配置
* 参考 https://github.com/docker/distribution/blob/master/docs/configuration.md
* 221.228.86.5 221.228.86.67
* 在/var/lib/pri_docker_registry/目录下建立config.yml配置文件,内容如下：

```bash
version: 0.1
log:
  level: debug
  formatter: json
  fields:
    service: registry
  hooks:
    - type: mail
      disabled: true
      levels:
        - panic
      options:
        smtp:
          addr: mail.yy.com:25
          username: xxx
          password: pass
          insecure: true
        from: sender@yy.com
        to:
          - errors@yy.com
storage:
    filesystem:
        rootdirectory: /var/lib/registry
    delete:
      enabled: true
    redirect:
      disable: false
http:
    addr: :5000
    headers:
        X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
```

* 在docker registry 1 、2、3上分别执行如下命令

```bash
$ mkdir -p /var/lib/registry
$ docker run -d -p 5000:5000 --net=host --restart=always -v /var/lib/pri_docker_registry/config.yml:/etc/docker/registry/config.yml -v /var/lib/registry:/var/lib/registry -v /etc/ceph/:/etc/ceph/ --name docker-registry registry:2.1
```
一定要将ceph的配置文件挂载进入容器，rados访问ceph需要
* 配置iptables规则，只允许proxy机器访问

```bash
$ iptables -A INPUT -d 221.228.86.67/32 -m comment --comment "not allow to be connected except proxy" -j DROP
$ iptables -I INPUT 1 -s 221.228.86.4 -d 221.228.86.67 -j ACCEPT
$ iptables -I INPUT 1 -s 221.228.86.6 -d 221.228.86.67 -j ACCEPT
# 添加办公网的访问
$ iptables -I INPUT -s 183.60.177.224/27 -d 221.228.86.70/32 -j ACCEPT
  # 配置221.228.86.6
$ iptables -A INPUT -d 221.228.86.5/32 -m comment --comment "not allow to be connected except proxy" -j DROP
$ iptables -I INPUT 1 -s 221.228.86.4 -d 221.228.86.5 -j ACCEPT
$ iptables -I INPUT 1 -s 221.228.86.6 -d 221.228.86.5 -j ACCEPT
$ iptables -I INPUT -s 183.60.177.224/27 -d 221.228.86.70/32 -j ACCEPT
```

## Haproxy 配置
* 参考 https://hub.docker.com/_/haproxy/
* 在haproxy 主备上分别执行下面命令,在/var/lib/hadporxy/目录下建立haproxy.cfg配置文件,内容如下:

```bash
global
    log 127.0.0.1 local3 info
    maxconn 4096
    nbproc 1
    pidfile /var/lib/haproxy/haproxy.pid
defaults
    maxconn 2000
    timeout connect 5000
    timeout client 30000
    timeout server 30000
    mode http
    stats uri /admin?stats
    option forwardfor
frontend http_server
    bind :5000
    log global
    default_backend docker-registry
    #acl test hdr_dom(host) -i test.domain.com
    #use_backend cache_test if test
backend docker-registry
    #balance roundrobin
    balance source
    option httpchk GET /v2/ HTTP/1.1\r\nHost:221.228.86.6
    server inst1 221.228.86.5:5000 check inter 5000 fall 3
    server inst2 221.228.86.67:5000 check inter 5000 fall 3
#HAProxy管理页面 
listen admin_stat
    bind *:1158                    #管理页面端口
    mode http                        
    stats refresh 10s                #自动刷新时间
    stats uri /haproxy                 #页面名称
    stats realm Haproxy\ Statistics     #登录提示
    stats auth admin:admin    #帐号密码
    stats hide-version 
stats admin if TRUE
```

#### 创建haproxy-registry容器

```bash
$ mkdir -p /var/lib/haproxy
$ docker run -d --name haproxy-registry --net=host -v /var/lib/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro haproxy:1.5
```
#### 清除Iptables 规则，目前让所有机器都能访问该proxy

```bash
$ iptables -D INPUT -d 221.228.86.5/32 -m comment --comment sigma -j DROP
```

## Keepalived主备配置
使用Keeplalived管理浮动IP

* 在221.228.86.4 221.228.86.6机器上同时安装keepalived，keepalived配置文件区别设置
#### Ubuntu Keepalived安装

```bash
$ apt-get install keepalived
```
#### Master（221.228.86.4）服务器配置 /etc/keepalived/keepalived.conf

```bash
global_defs {
   notification_email {
       xieyaoyao@yy.com
   }
   notification_email_from mail@example.org
   smtp_server mail.yy.com
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}
#监测haproxy进程状态，每2秒执行一次
vrrp_script chk_haproxy {
    script "/usr/local/keepalived/chk_haproxy.sh"
    interval 2
    weight 2
}
vrrp_instance VI_1 {
    state MASTER #标示状态为MASTER
    interface eth0
    virtual_router_id 51
    priority 101   #MASTER权重要高于BACKUP
    advert_int 1
    mcast_src_ip 221.228.86.4 #Master服务器IP
    authentication {
        auth_type PASS #主从服务器验证方式
        auth_pass 1111
    }
    track_script {
        chk_haproxy #监测haproxy进程状态
    }
    #VIP
    virtual_ipaddress {
        221.228.86.70 #虚拟IP
    }
}
```
#### Backup（221.228.86.6）服务器上的配置 /etc/keepalived/keepalived.conf

```bash
global_defs {
   notification_email {
   user@example.com
   }
   notification_email_from mail@example.org
   smtp_server 192.168.x.x
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}
#监测haproxy进程状态，每2秒执行一次
vrrp_script chk_haproxy {
    script "/usr/local/keepalived/chk_haproxy.sh"
    interval 2
    weight 2
}
vrrp_instance VI_1 {
    state BACKUP #状态为BACKUP
    interface eth0
    virtual_router_id 51
    priority 100  #权重要低于MASTER
    advert_int 1
    mcast_src_ip 221.228.86.6 #Backup服务器的IP
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    track_script {
        chk_haproxy #监测haproxy进程状态
    }
    #VIP
    virtual_ipaddress {
        221.228.86.70 #虚拟IP
    }
}
```
#### chk_haproxy.sh内容 /usr/local/keepalived/chk_haproxy.sh

```bash
#!/bin/bash
#
# author: weizhifeng
# description: 
# 定时查看haproxy是否存在，如果不存在则启动haproxy，
# 如果启动失败，则停止keepalived
# 
status=$(docker inspect  -f "{{.State.Running}}" haproxy-registry)
if [ "${status}" = "false" ]; then
    docker start haproxy-registry
    status2=$(docker inspect  -f "{{.State.Running}}" haproxy-registry)
    if [ "${status2}" = "false"  ]; then
            service keepalived stop
    fi
fi
```
#### 启动keepalived服务

```bash
$ service keepalived start
```








		
