FROM registry.cn-hangzhou.aliyuncs.com/spacexnice/hexo-amd64:v1.0.2
COPY . /Hexo
RUN npm install hexo-cli -g && npm install hexo --save
RUN npm install
RUN bash build.sh

ENTRYPOINT ["hexo","s"]
