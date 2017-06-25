
VERSION?=v1.0.0

all: build push
	echo "build and push"

build:
	docker build -t registry.cn-hangzhou.aliyuncs.com/spacexnice/blog:${VERSION} .
	#docker -H localhost:2375 build -t registry.cn-hangzhou.aliyuncs.com/spacexnice/blog:${VERSION} .

push: 
	docker push registry.cn-hangzhou.aliyuncs.com/spacexnice/blog:${VERSION}
	#docker -H localhost:2375 push registry.cn-hangzhou.aliyuncs.com/spacexnice/blog:${VERSION}


