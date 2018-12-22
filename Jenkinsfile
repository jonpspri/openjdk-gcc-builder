/*
 * This file makes two assumptions about your Jenkins build environment:
 *
 * 1.  You have nodes set up with labels of the form "docker-${ARCH}" to
 *     support the various build architectures (currently 'x86_64',
 *     's390x', 'aarch64' (ARM), and 'ppc64le').
 * 2.  If you do not want to target the 'docker.io/adoptopenjdk' registry
 *     (and unless you're the official maintainer, you shouldn't), then
 *     you've set up an ADOPTOPENJDK_TARGET_REGISTRY variable with the target
 *     registry you'll use.
 *
 * TODO:  Set up the build architectures as a parameter that will drive
 *        a scripted loop to build stages.
 */

pipeline {
  agent none
  stages {
    stage('Build') {
      parallel {
        stage("Build-x86_64") {
          agent {
            label "docker-x86_64"
          }
          steps {
            sh './build.sh'
          }
        }
        stage("Build-s390x") {
          agent {
            label "docker-s390x"
          }
          steps {
            sh './build.sh'
          }
        }
        stage("Build-aarch64") {
          agent {
            label "docker-aarch64"
          }
          steps {
            sh './build.sh'
          }
        }
        stage("Build-ppc64le") {
          agent {
            label "docker-ppc64le"
          }
          steps {
            sh './build.sh'
          }
        }

      }
    }
  }
}
