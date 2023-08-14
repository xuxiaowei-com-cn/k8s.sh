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

| Name                        | Format | Type  | URL	                                                               | APT Distribution | Proxy Remote storage               | Blob store    |
|-----------------------------|--------|-------|--------------------------------------------------------------------|------------------|------------------------------------|---------------|
| apt-aliyun                  | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-aliyun/                  | lunar            | http://mirrors.aliyun.com          | apt-aliyun    |
| apt-tencent                 | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-tencent/                 | lunar            | http://mirrors.cloud.tencent.com   | apt-tencent   |
| apt-docker                  | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-docker/                  | lunar            | https://download.docker.com        | apt-docker    |
| apt-openkylin-software      | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-openkylin-software/      | default          | http://software.openkylin.top      | apt-openkylin |
| apt-openkylin-archive-build | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-openkylin-archive-build/ | yangtze          | http://archive.build.openkylin.top | apt-openkylin |
| apt-openkylin-ppa-build     | apt    | proxy | https://nexus.xuxiaowei.cn/repository/apt-openkylin-ppa-build/     | yangtze          | http://ppa.build.openkylin.top     | apt-openkylin |

- 使用说明
    1. apt-aliyun 代理整个阿里云 apt 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：ubuntu、debian
    2. apt-tencent 代理整个腾讯云 apt 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：ubuntu、debian
    3. 阿里云存在 openkylin 的安装源 https://mirrors.aliyun.com/openkylin/
       ，只不过在 https://developer.aliyun.com/mirror/ 没有列举出来
- 使用方式
    1. 待更新

### docker

| Domain                        | Name             | Format | Type   | URL                                                     | Repository Connectors HTTP | Repository Connectors HTTPS | Allow anonymous docker pull | Enable Docker V1 API | Proxy Remote storage                 | Blob store       |
|-------------------------------|------------------|--------|--------|---------------------------------------------------------|----------------------------|-----------------------------|-----------------------------|----------------------|--------------------------------------|------------------|
| jihulab.docker.xuxiaowei.cn   | docker-jihulab   | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-jihulab/   | 8001                       | 9001                        | ✅                           | ✅                    | https://registry.jihulab.com         | docker-jihulab   |
| io.docker.xuxiaowei.cn        | docker-io        | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-io/        | 8002                       | 9002                        | ✅                           | ✅                    | https://registry-1.docker.io         | docker-io        |
| gitlab-jh.docker.xuxiaowei.cn | docker-gitlab-jh | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-gitlab-jh/ | 8003                       | 9003                        | ✅                           | ✅                    | https://registry.gitlab.cn           | docker-gitlab-jh |
| hosted.docker.xuxiaowei.cn    | docker-hosted    | docker | hosted | https://nexus.xuxiaowei.cn/repository/docker-hosted/    | 8004                       | 9004                        | ✅                           | ✅                    |                                      | docker-hosted    |
| 163.docker.xuxiaowei.cn       | docker-163       | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-163/       | 8005                       | 9005                        | ✅                           | ✅                    | https://hub-mirror.c.163.com         | docker-163       |
| group.docker.xuxiaowei.cn     | docker-group     | docker | group  | https://nexus.xuxiaowei.cn/repository/docker-group/     | 8006                       | 9006                        | ✅                           | ✅                    |                                      | docker-group     |
| aliyuncs.docker.xuxiaowei.cn  | docker-aliyuncs  | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-aliyuncs/  | 8007                       | 9007                        | ✅                           | ✅                    | https://hnkfbj7x.mirror.aliyuncs.com | docker-aliyuncs  |
| elastic.docker.xuxiaowei.cn   | docker-elastic   | docker | proxy  | https://nexus.xuxiaowei.cn/repository/docker-elastic/   | 8008                       | 9008                        | ✅                           | ✅                    | https://docker.elastic.co            | docker-elastic   |

- 使用说明
    1. 此处拉取 docker 镜像时，使用不同的域名拉取不同的仓库
- docker 信任证书
    1. 待更新
- containerd 信任证书（k8s 使用 containerd）
    1. 待更新
- 使用方式
    1. 待更新

### maven

| Name                 | Format | Type  | URL                                                         | Version policy | Proxy Remote storage                                           | Blob store           |
|----------------------|--------|-------|-------------------------------------------------------------|----------------|----------------------------------------------------------------|----------------------|
| maven-aliyun-central | maven2 | proxy | https://nexus.xuxiaowei.cn/repository/maven-aliyun-central/ | Release        | https://maven.aliyun.com/repository/central                    | maven-aliyun         |
| maven-aliyun-public  | maven2 | proxy | https://nexus.xuxiaowei.cn/repository/maven-aliyun-public/  | Release        | https://maven.aliyun.com/repository/public                     | maven-aliyun         |
| maven-tencent-public | maven2 | proxy | https://nexus.xuxiaowei.cn/repository/maven-tencent-public/ | Release        | http://mirrors.cloud.tencent.com/nexus/repository/maven-public | maven-tencent-public |
| maven-group          | maven2 | group | https://nexus.xuxiaowei.cn/repository/maven-group/          | Release        |                                                                | maven-group          |

- 使用方式
    1. 待更新

### yum

| Name           | Format | Type  | URL                                                   | Proxy Remote storage             | Blob store     |
|----------------|--------|-------|-------------------------------------------------------|----------------------------------|----------------|
| yum-aliyun     | yum    | proxy | https://nexus.xuxiaowei.cn/repository/yum-aliyun/     | http://mirrors.aliyun.com        | yum-aliyun     |
| yum-tencent    | yum    | proxy | https://nexus.xuxiaowei.cn/repository/yum-tencent/    | http://mirrors.cloud.tencent.com | yum-tencent    |
| yum-docker     | yum    | proxy | https://nexus.xuxiaowei.cn/repository/yum-docker/     | https://download.docker.com      | yum-docker     |
| yum-openanolis | yum    | proxy | https://nexus.xuxiaowei.cn/repository/yum-openanolis/ | https://mirrors.openanolis.cn    | yum-openanolis |

- 使用说明
    1. yum-aliyun 代理整个阿里云 yum 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：centos、centos-vault
    2. yum-tencent 代理整个腾讯云 yum 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：
- 使用方式
    1. 待更新
