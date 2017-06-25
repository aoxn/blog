podTemplate(label: 'golang-pod',  containers: [
    containerTemplate(
            name: 'golang',
            image: 'registry.cn-hangzhou.aliyuncs.com/spacexnice/golang:1.8.3-docker',
            ttyEnabled: true,
            command: 'cat'
        ),
    containerTemplate(
            name: 'jnlp',
            image: 'registry.cn-hangzhou.aliyuncs.com/google-containers/jnlp-slave:alpine',
            args: '${computer.jnlpmac} ${computer.name}',
            command: ''
        )
  ]
  ,volumes: [
        /*persistentVolumeClaim(mountPath: '/home/jenkins', claimName: 'jenkins', readOnly: false),*/
        hostPathVolume(hostPath: '/root/work/jenkins', mountPath: '/home/jenkins'),
        hostPathVolume(hostPath: '/var/run/docker.sock', mountPath: '/var/run/docker.sock'),
        hostPathVolume(hostPath: '/tmp/', mountPath: '/tmp/'),
]) 
{
    node ('golang-pod') {
        properties([
            parameters ([
                string(name: 'K8S_VERSION', defaultValue: '1.6.4', description: 'Kubernetes version, default to 1.6.4?'),
            ])
        ])
        container('golang') {
	        git url: 'https://github.com/spacexnice/release.git', branch: 'spacex-master'
            
            stage('Build blog project') {
                withDockerRegistry([credentialsId: 'KUBE_REPO_PUSH', url: 'https://registry.cn-hangzhou.aliyuncs.com/v2']) {
			sh ("make")
		} 
		/* 
                withCredentials([usernamePassword(credentialsId: 'OSS_KEY_SECRET', passwordVariable: 'OSS_PASS', usernameVariable: 'OSS_USER')]) {
                    
                    sh ("osscmd config --id=${env.OSS_USER} --key=${env.OSS_PASS}")
                    
                    withDockerRegistry([credentialsId: 'KUBE_REPO_PUSH', url: 'https://registry.cn-hangzhou.aliyuncs.com/v2']) {
                        // some block
                        sh ("cd kubeadm/; ./release.sh --branch ${params.K8S_CODE_BRANCH} --k8s_version ${params.K8S_VERSION} --revision ${params.K8S_REVISION} --skip-make-k8s ${params.K8S_SKIP_MAKE} --skip-make-hyperkube ${params.K8S_SKIP_MAKE_HYPERKUBE} --skip-make-rpm ${params.K8S_SKIP_MAKE_RPM} --skip-make-debian ${params.K8S_SKIP_MAKE_DEBIAN} --skip-upload-installer ${params.K8S_SKIP_UPLOAD_INSTALLER}")
                    }
                }
		*/
            }
	    }
    }
}
