pipeline {
    agent any

    environment {
        JAVA_HOME = "/opt/homebrew/opt/openjdk@17"
        ANDROID_HOME = "/opt/homebrew/share/android-commandlinetools"
        ANDROID_SDK_ROOT = "${ANDROID_HOME}"
        FLUTTER_HOME = "/opt/homebrew/share/flutter"
        PATH = "${JAVA_HOME}/bin:${FLUTTER_HOME}/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        COOLIFY_URL = "http://157.180.43.90:8000"
    }

    parameters {
        string(name: 'FLUTTER_DIR', defaultValue: 'mobile', description: 'Subdirectory containing the Flutter project')
        string(name: 'COOLIFY_UUIDS', defaultValue: '', description: 'Comma-separated Coolify app UUIDs to deploy')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Flutter Setup') {
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh 'flutter --version'
                    sh 'flutter pub get'
                }
            }
        }

        stage('Analyze') {
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh 'dart analyze --no-fatal-infos --no-fatal-warnings || true'
                }
            }
        }

        stage('Test') {
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh 'flutter test'
                }
            }
        }

        stage('Build Android') {
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh 'flutter build apk --release'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: "${params.FLUTTER_DIR}/build/app/outputs/**/*.apk", fingerprint: true
                }
            }
        }

        stage('Build iOS') {
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh 'flutter build ios --release --no-codesign'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: "${params.FLUTTER_DIR}/build/ios/ipa/*.ipa", allowEmptyArchive: true
                }
            }
        }

        stage('Deploy via Coolify') {
            when {
                expression { return params.COOLIFY_UUIDS?.trim() }
            }
            steps {
                withCredentials([string(credentialsId: 'coolify-api-token', variable: 'COOLIFY_TOKEN')]) {
                    script {
                        def uuids = params.COOLIFY_UUIDS.split(',')
                        for (uuid in uuids) {
                            uuid = uuid.trim()
                            if (uuid) {
                                echo "Deploying Coolify app: ${uuid}"
                                sh """
                                    curl -sSf "${COOLIFY_URL}/api/v1/deploy?uuid=${uuid}&force=false" \
                                      -H "Authorization: Bearer \${COOLIFY_TOKEN}" \
                                      -H "Content-Type: application/json"
                                """
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo 'Build failed!'
        }
        success {
            echo 'Build succeeded!'
        }
    }
}
