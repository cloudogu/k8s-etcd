#!groovy
@Library('github.com/cloudogu/ces-build-lib@1.48.0')
import com.cloudogu.ces.cesbuildlib.*

node('docker') {
    timestamps {
        stage('Checkout') {
            checkout scm
        }

        yamllintImage = 'cytopia/yamllint:1.26'

        stage('Lint') {
            docker.image(yamllintImage).inside('-v ${WORKSPACE}/manifests/:/data -t') {
                sh "yamllint ."
            }
        }
    }
}

