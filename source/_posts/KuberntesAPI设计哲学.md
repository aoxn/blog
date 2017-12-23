title: Kubernetes API设计哲学
date: 2017-12-16 15:21:02
tags: ["Kubernetes"]
categories: ["Kubernetes","Container","容器"]
---

# Kubernetes API设计哲学
kubernetes API设计时遵循了如下几个特征，声明式的API设计、水平触发的reconcile、异步的pull模式
## 声明式（Declarative）
用户指定的是期望达到的状态，而不是操作命令。
Kubernetes API设计的理念如下： 用户将一个资源对象的期望状态通过描述文件的方式发送给API接口，然后API接口通过不间断的操作使资源对象达到并稳定在期望的状态之上。例如，用户将一个具有多个副本、及指定版本的deployment发送到API接口时，API首先对该资源对象做校验然后进行持久化存储，接下来一个reconcile操作会取回该资源并执行该资源的定义操作，直到该资源的实际状态与定义的期望状态一致。期间如果实际状态被意外更改，仍然会被reconcile到期望状态。

**reconcile**
reconcile是一组预定义的循环操作(通常的实现是controller-manager)，watch storage上资源对象的期望状态的变化，并对比资源的本地实际状态，执行相关操作使资源最终达到该期望的一致状态，具有幂等性。
![](/upload/15134909004013.jpg)

## 水平触发（Level trigger）
Kubernetes API是基于水平触发的实现，系统会驱动资源达到当前所期望的状态，而不管在此之前被设置了哪些不同的期望状态，以当前为基准。例如对当前正在进行rollout的deployment更改其镜像，会促使系统放弃执行当前未完成的rollout,转而进入新的desired state reconcile 流程，即切换到最新的修改上。

## 异步性（Asynchronous）
Kubernetes API接口异步的执行资源的desired state reconcile操作。这意味着创建资源的API请求会在完成校验并存储后立刻返回给调用方而不会立刻执行任何的资源创建动作。这也会导致许多创建中的错误不会在这个阶段返回给用户。解决的方式是定义良好的事件通知机制，资源reconcile过程中产生的错误信息写入到资源关联的事件中，用户通过watch事件了解创建过程。


## Reference
[Building and using Kubernetes API](https://github.com/kubernetes-incubator/apiserver-builder/blob/master/docs/concepts/api_building_overview.md)

