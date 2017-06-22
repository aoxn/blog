podTemplate(label: 'golang-pod',  containers: [
    containerTemplate(
            name: 'golang',
            image: 'registry.cn-hangzhou.aliyuncs.com/spacexnice/golang:1.8.3-docker',
            ttyEnabled: true,
            command: 'cat'
        )
    /*
    containerTemplate(name: 'docker', image: 'registry.cn-hangzhou.aliyuncs.com/spacexnice/jenkins-slave:latest', command: '', ttyEnabled: false)
  */
  ]
  ,volumes: [
/*
      persistentVolumeClaim(mountPath: '/home/jenkins', claimName: 'jenkins', readOnly: false),
*/
        hostPathVolume(hostPath: '/root/work/jenkins', mountPath: '/home/jenkins'),
        hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock')
  ]) 
{
    node ('golang-pod') {
        container('golang') {
	        git url: 'https://code.aliyun.com/spacexnice/blog.git'
            stage('Build blog project') {
		        sh ("docker build -t registry.cn-hangzhou.aliyuncs.com/spacexnice/blog:v1.0.0 .")
		       
		    }
	    }
    }
}
