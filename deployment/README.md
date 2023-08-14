# 部署说明

## 说明

1. 使用通配符域名证书，减少配置，申请参见：
    1. [使用 acme.sh 生成证书](https://xuxiaowei-com-cn.gitee.io/gitlab-k8s/docs/ssl/acme.sh)
2. 数据使用 NFS 储存
    1. NFS IP：172.25.25.5
    2. NFS 路径：/nfs
    3. 每个宿主机都需要安装 NFS
3. 宿主机系统：Anolis OS release 23
4. 资源配置、软件版本
    1. 主节点：2C4G100H
    2. 工作节点：8C16G100H

```shell
[root@k8s-control-plane-1 ~]# kubectl get node -o wide
NAME                  STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE       KERNEL-VERSION              CONTAINER-RUNTIME
k8s-control-plane-1   Ready    control-plane   3d3h   v1.27.4   172.25.25.211   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-control-plane-2   Ready    control-plane   3d3h   v1.27.4   172.25.25.212   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-control-plane-3   Ready    control-plane   3d3h   v1.27.4   172.25.25.213   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-1            Ready    <none>          3d3h   v1.27.4   172.25.25.221   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-2            Ready    <none>          3d3h   v1.27.4   172.25.25.222   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-3            Ready    <none>          34h    v1.27.4   172.25.25.223   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-4            Ready    <none>          22h    v1.27.4   172.25.25.224   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
[root@k8s-control-plane-1 ~]# 
```

## GitLab

| Name      | Version     | Domain                 |
|-----------|-------------|------------------------|
| gitlab-ce | 16.2.3-ce.0 | gitlab.ce.xuxiaowei.cn |
| gitlab-ee | 16.2.3-ee.0 | gitlab.ee.xuxiaowei.cn |
| gitlab-jh | 16.2.3      | gitlab.jh.xuxiaowei.cn |

## Nexus

1. 使用 MinIO S3 储存文件

### apt

| Name       | Format | Type  | URL	                                              | APT Distribution | Proxy Remote storage      | Blob store |
|------------|--------|-------|---------------------------------------------------|------------------|---------------------------|------------|
| apt-aliyun | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-aliyun/ | lunar            | http://mirrors.aliyun.com | apt-aliyun |

- 使用说明
    1. apt-aliyun 代理整个阿里云镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：ubuntu、debian
- 使用方式
    1. 待更新

### docker

| Domain                        | Name             | Format | Type   | URL                                                     | Repository Connectors HTTP | Repository Connectors HTTPS | Allow anonymous docker pull | Enable Docker V1 API | Proxy Remote storage                 | Blob store       |
|-------------------------------|------------------|--------|--------|---------------------------------------------------------|----------------------------|-----------------------------|-----------------------------|----------------------|--------------------------------------|------------------|
| 163.docker.xuxiaowei.cn       | docker-163       | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-163/       | 8005                       | 9005                        | ✅                           | ✅                    | https://hub-mirror.c.163.com         | docker-163       |
| aliyuncs.docker.xuxiaowei.cn  | docker-aliyuncs  | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-aliyuncs/  | 8007                       | 9007                        | ✅                           | ✅                    | https://hnkfbj7x.mirror.aliyuncs.com | docker-aliyuncs  |
| elastic.docker.xuxiaowei.cn   | docker-elastic   | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-elastic/   | 8008                       | 9008                        | ✅                           | ✅                    | https://docker.elastic.co            | docker-elastic   |
| gitlab-jh.docker.xuxiaowei.cn | docker-gitlab-jh | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-gitlab-jh/ | 8003                       | 9003                        | ✅                           | ✅                    | https://registry.gitlab.cn           | docker-gitlab-jh |
| group.docker.xuxiaowei.cn     | docker-group     | docker | group  | https://nexus.xuxiaowei.cn/repository/docker-group/     | 8006                       | 9006                        | ✅                           | ✅                    |                                      | docker-group     |
| hosted.docker.xuxiaowei.cn    | docker-hosted    | docker | hosted | https://nexus.xuxiaowei.cn/repository/docker-hosted/    | 8004                       | 9004                        | ✅                           | ✅                    |                                      | docker-hosted    |
| io.docker.xuxiaowei.cn        | docker-io        | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-io/        | 8002                       | 9002                        | ✅                           | ✅                    | https://registry-1.docker.io         | docker-io        |
| jihulab.docker.xuxiaowei.cn   | docker-jihulab   | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-jihulab/   | 8001                       | 9001                        | ✅                           | ✅                    | https://registry.jihulab.com         | docker-jihulab   |

- 使用说明
    1. 此处拉取 docker 镜像时，使用不同的域名拉取不同的仓库
- 使用方式
    1. 待更新

### maven

| Name                 | Format | Type  | URL                                                         | Version policy | Proxy Remote storage                        | Blob store   |
|----------------------|--------|-------|-------------------------------------------------------------|----------------|---------------------------------------------|--------------|
| maven-aliyun-central | maven2 | proxy | https://nexus.xuxiaowei.cn/repository/maven-aliyun-central/ | Release        | https://maven.aliyun.com/repository/central | maven-aliyun |
| maven-aliyun-public  | maven2 | proxy | https://nexus.xuxiaowei.cn/repository/maven-aliyun-public/  | Release        | https://maven.aliyun.com/repository/public  | maven-aliyun |
| maven-group          | maven2 | group | https://nexus.xuxiaowei.cn/repository/maven-group/          | Release        |                                             | maven-group  |

- 使用方式
    1. 待更新

### yum

| Name       | Format | Type  | URL                                               | Proxy Remote storage      | Blob store |
|------------|--------|-------|---------------------------------------------------|---------------------------|------------|
| yum-aliyun | yum    | proxy | https://nexus.xuxiaowei.cn/repository/yum-aliyun/ | http://mirrors.aliyun.com | yum-aliyun |

- 使用方式
    1. 待更新
