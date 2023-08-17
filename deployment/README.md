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
    1. PVE 8.0-2：40C256G7440H
    2. k8s 主节点：2C4G100H
    3. k8s 工作节点：8C16G100H
    4. k8s 主节点 VIP：172.25.25.210
    5. k8s 工作节点 VIP：172.25.25.220

```shell
[root@k8s-control-plane-1 ~]# kubectl get node -o wide
NAME                  STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE       KERNEL-VERSION              CONTAINER-RUNTIME
k8s-control-plane-1   Ready    control-plane   4d3h    v1.27.4   172.25.25.211   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-control-plane-2   Ready    control-plane   4d3h    v1.27.4   172.25.25.212   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-control-plane-3   Ready    control-plane   4d3h    v1.27.4   172.25.25.213   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-1            Ready    <none>          4d3h    v1.27.4   172.25.25.221   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-2            Ready    <none>          4d3h    v1.27.4   172.25.25.222   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-3            Ready    <none>          2d10h   v1.27.4   172.25.25.223   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-4            Ready    <none>          47h     v1.27.4   172.25.25.224   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
k8s-node-5            Ready    <none>          3m32s   v1.27.4   172.25.25.225   <none>        Anolis OS 23   5.10.134-14.1.an23.x86_64   containerd://1.6.22
[root@k8s-control-plane-1 ~]# kubectl get svc --all-namespaces 
NAMESPACE              NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                                                                                                                                                                                                                         AGE
default                demo                                 ClusterIP      10.98.26.157     <none>        80/TCP                                                                                                                                                                                                                                                                          2d11h
default                kubernetes                           ClusterIP      10.96.0.1        <none>        443/TCP                                                                                                                                                                                                                                                                         4d3h
gitlab                 gitlab-ce-service                    NodePort       10.98.41.219     <none>        80:31101/TCP,443:31102/TCP,22:31103/TCP                                                                                                                                                                                                                                         3d2h
gitlab                 gitlab-ee-service                    NodePort       10.97.231.174    <none>        80:31201/TCP,443:31202/TCP,22:31203/TCP                                                                                                                                                                                                                                         3d2h
gitlab                 gitlab-jh-service                    NodePort       10.104.1.6       <none>        80:31301/TCP,443:31302/TCP,22:31303/TCP                                                                                                                                                                                                                                         3d2h
ingress-nginx          ingress-nginx-controller             LoadBalancer   10.110.209.138   <pending>     80:31974/TCP,443:31467/TCP                                                                                                                                                                                                                                                      2d11h
ingress-nginx          ingress-nginx-controller-admission   ClusterIP      10.101.191.140   <none>        443/TCP                                                                                                                                                                                                                                                                         2d11h
kube-system            kube-dns                             ClusterIP      10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP                                                                                                                                                                                                                                                          4d3h
kube-system            metrics-server                       ClusterIP      10.101.158.114   <none>        443/TCP                                                                                                                                                                                                                                                                         4d3h
kubernetes-dashboard   dashboard-metrics-scraper            ClusterIP      10.109.12.2      <none>        8000/TCP                                                                                                                                                                                                                                                                        4d2h
kubernetes-dashboard   kubernetes-dashboard                 NodePort       10.97.228.26     <none>        443:30320/TCP                                                                                                                                                                                                                                                                   4d2h
minio-operator         console                              NodePort       10.105.243.243   <none>        9090:32326/TCP,9443:30151/TCP                                                                                                                                                                                                                                                   4d1h
minio-operator         operator                             ClusterIP      10.107.178.90    <none>        4221/TCP                                                                                                                                                                                                                                                                        4d1h
minio-operator         sts                                  ClusterIP      10.110.109.236   <none>        4223/TCP                                                                                                                                                                                                                                                                        4d1h
nexus                  minio-service                        NodePort       10.96.97.172     <none>        9000:31401/TCP,9001:31402/TCP                                                                                                                                                                                                                                                   3d
nexus                  nexus-service                        NodePort       10.107.234.44    <none>        8081:31501/TCP,8443:31502/TCP,8001:31581/TCP,9001:31591/TCP,8002:31582/TCP,9002:31592/TCP,8003:31583/TCP,9003:31593/TCP,8004:31584/TCP,9004:31594/TCP,8005:31585/TCP,9005:31595/TCP,8006:31586/TCP,9006:31596/TCP,8007:31587/TCP,9007:31597/TCP,8008:31588/TCP,9008:31598/TCP   3d2h
[root@k8s-control-plane-1 ~]# 
```

## 脚本说明

### gitlab 命名空间

1. [gitlab-ce-deployment.yaml](gitlab-ce-deployment.yaml)
    1. 部署 gitlab-ce（社区版）
2. [gitlab-ee-deployment.yaml](gitlab-ee-deployment.yaml)
    1. 部署 gitlab-ee（企业版）
3. [gitlab-jh-deployment.yaml](gitlab-jh-deployment.yaml)
    1. 部署 gitlab-jh（极狐版）
4. [gitlab-ingress.yaml](gitlab-ingress.yaml)
    1. 配置 gitlab 域名、证书
    2. 只使用 80/443 端口，使用不同域名区分访问目的地

### nexus 命名空间

1. [nexus-deployment.yaml](nexus-deployment.yaml)
    1. 部署 nexus，搭建个人私库
    2. 支持的私库类型（其中 hosted 代表宿主仓库，可以自己上传；proxy 代表代理仓库；group 代表分组仓库，可以将多个仓库聚合成一个仓库）：
        1. apt (hosted)
        2. apt (proxy)
        3. bower (group)
        4. bower (hosted)
        5. bower (proxy)
        6. cocoapods (proxy)
        7. conan (proxy)
        8. conda (proxy)
        9. docker (group)
        10. docker (hosted)
        11. docker (proxy)
        12. gitlfs (hosted)
        13. go (group)
        14. go (proxy)
        15. helm (hosted)
        16. helm (proxy)
        17. maven2 (group)
        18. maven2 (hosted)
        19. maven2 (proxy)
        20. npm (group)
        21. npm (hosted)
        22. npm (proxy)
        23. nuget (group)
        24. nuget (hosted)
        25. nuget (proxy)
        26. p2 (proxy)
        27. pypi (group)
        28. pypi (hosted)
        29. pypi (proxy)
        30. r (group)
        31. r (hosted)
        32. r (proxy)
        33. raw (group)
        34. raw (hosted)
        35. raw (proxy)
        36. rubygems (group)
        37. rubygems (hosted)
        38. rubygems (proxy)
        39. yum (group)
        40. yum (hosted)
        41. yum (proxy)
2. [minio-deployment.yaml](minio-deployment.yaml)
    1. MinIO（支持 S3 协议），用户储存 nexus 文件/数据
3. [nexus-ingress.yaml](nexus-ingress.yaml)
    1. 配置 nexus 域名、证书
    2. 主要用于 docker 私库域名证书的配置

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

| 系统名称   | 系统版本  | 安装源类型      | 代理镜像 | 安装源配置文件                                                                        |
|--------|-------|------------|------|--------------------------------------------------------------------------------|
| Ubuntu | 22.10 | 默认 apt     | 阿里云  | [/etc/apt/22.10/aliyun-sources.list](/etc/apt/22.10/aliyun-sources.list)       |
| Ubuntu | 22.10 | docker     | 阿里云  | [/etc/apt/22.10/aliyun-docker.list](/etc/apt/22.10/aliyun-docker.list)         |
| Ubuntu | 22.10 | kubernetes | 阿里云  | [/etc/apt/22.10/aliyun-kubernetes.list](/etc/apt/22.10/aliyun-kubernetes.list) |

- 使用说明
    1. apt-aliyun 代理整个阿里云 apt 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：ubuntu、debian
    2. apt-tencent 代理整个腾讯云 apt 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：ubuntu、debian
    3. 阿里云存在 openkylin 的安装源 https://mirrors.aliyun.com/openkylin/
       ，只不过在 https://developer.aliyun.com/mirror/ 没有列举出来
- 使用方式
    1. 备份 `/etc/apt/` 中的源
        ```shell
        cd /etc/apt/
        ll
        sudo mv sources.list sources.list.bak
        ll
        ```
    2. 根据当前系统，选择所需的配置文件，上传至 `/etc/apt/` 或 `/etc/apt/sources.list.d` 文件夹

    3. 清理所有本地仓库

        ```shell
        sudo apt-get clean
        ```

    4. 重建索引测试

        ```shell
        sudo apt-get update
        ```

    5. CentOS 安装依赖测试

        ```shell
        # 可使用搜索进行测试
        # sudo apt-cache madison autoconf
        sudo apt-get -y install autoconf gcc gettext libcurl4-gnutls-dev libexpat1-dev libnl-3-dev libpcre3-dev libssl-dev make zlib1g-dev
        ```

    6. docker 安装依赖测试

        ```shell
        # 可使用搜索进行测试
        # sudo apt-cache madison docker-ce
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ```

    7. kubernetes 安装依赖测试

        ```shell
        # 可使用搜索进行测试
        # sudo apt-cache madison kubelet
        sudo apt-get -y install kubelet kubeadm kubectl
        ```

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
    1. 参见：https://xuxiaowei-com-cn.gitee.io/gitlab-k8s/docs/nexus/docker-https-configuration
- containerd 信任证书（k8s 使用 containerd）
    1. 参见：https://xuxiaowei-com-cn.gitee.io/gitlab-k8s/docs/k8s/containerd-mirrors/
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

| 系统名称         | 系统版本 | 安装源类型      | 代理镜像 | 安装源配置文件                                                                                                  |
|--------------|------|------------|------|----------------------------------------------------------------------------------------------------------|
| CentOS       | 7    | 默认 yum     | 阿里云  | [/etc/yum.repos.d/aliyun-centos-7.repo](/etc/yum.repos.d/aliyun-centos-7.repo)                           |
| CentOS       | 8    | 默认 yum     | 阿里云  | [/etc/yum.repos.d/aliyun-centos-8.repo](/etc/yum.repos.d/aliyun-centos-8.repo)                           |
| CentOS vault | 8    | 默认 yum     | 阿里云  | [/etc/yum.repos.d/aliyun-centos-vault-8.5.2111.repo](/etc/yum.repos.d/aliyun-centos-vault-8.5.2111.repo) |
| CentOS       | 7/8  | docker     | 阿里云  | [/etc/yum.repos.d/aliyun-docker-ce.repo](/etc/yum.repos.d/aliyun-docker-ce.repo)                         |
| CentOS       | 7/8  | kubernetes | 阿里云  | [/etc/yum.repos.d/aliyun-kubernetes.repo](/etc/yum.repos.d/aliyun-kubernetes.repo)                       |

- 使用说明
    1. yum-aliyun 代理整个阿里云 yum 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：centos、centos-vault
    2. yum-tencent 代理整个腾讯云 yum 镜像的域名，通过 URL 后面不同的路径，可直接使用不同的源，如：centos、centos-vault
- 使用方式
    1. 备份 `/etc/yum.repos.d` 中的源
        ```shell
        cd /etc/yum.repos.d
        ll
        for file in *.repo; do mv "$file" "${file}.bak"; done
        ll
        ```
    2. 根据当前系统，选择所需的配置文件，上传至 `/etc/yum.repos.d/` 文件夹

    3. 清理所有本地仓库

        ```shell
        yum clean all
        ```

    4. 重建索引测试

        ```shell
        yum makecache
        ```

    5. CentOS 安装依赖测试

        ```shell
        # 可使用搜索进行测试
        # yum --showduplicates list autoconf
        yum -y install autoconf bash-completion curl-devel expat-devel gcc git libnl3-devel libtool make openssl-devel svn systemd-devel tar tcl vim wget zlib-devel
        ```

    6. docker 安装依赖测试

        ```shell
        # 可使用搜索进行测试
        # yum --showduplicates list docker-ce
        yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ```

    7. kubernetes 安装依赖测试

        ```shell
        # 可使用搜索进行测试
        # yum --showduplicates list kubelet
        yum -y install kubelet kubeadm kubectl --disableexcludes=kubernetes --nogpgcheck
        ```
