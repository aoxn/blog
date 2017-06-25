FROM registry.cn-hangzhou.aliyuncs.com/spacexnice/hexo-amd64:v1.0.2
COPY . /Hexo
#RUN npm install hexo --save && npm install hexo-cli -g 
RUN bash build.sh

ENTRYPOINT ["hexo","s"]
