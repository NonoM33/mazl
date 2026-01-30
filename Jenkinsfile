pipeline {
    agent any

    environment {
        JAVA_HOME = "/opt/homebrew/opt/openjdk@17"
        ANDROID_HOME = "/opt/homebrew/share/android-commandlinetools"
        ANDROID_SDK_ROOT = "${ANDROID_HOME}"
        FLUTTER_HOME = "/opt/homebrew/share/flutter"
        PATH = "${JAVA_HOME}/bin:${FLUTTER_HOME}/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        COOLIFY_URL = "http://157.180.43.90:8000"
        LANG = "en_US.UTF-8"
        LC_ALL = "en_US.UTF-8"
        FASTLANE_SKIP_UPDATE_CHECK = "1"
        FASTLANE_HIDE_CHANGELOG = "1"
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
                    sh 'flutter build appbundle --release'
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: "${params.FLUTTER_DIR}/build/app/outputs/**/*.aab", fingerprint: true
                }
            }
        }

        stage('Build iOS') {
            steps {
                dir("${params.FLUTTER_DIR}") {
                    withCredentials([
                        string(credentialsId: 'asc-key-id', variable: 'ASC_KEY_ID'),
                        string(credentialsId: 'asc-issuer-id', variable: 'ASC_ISSUER_ID')
                    ]) {
                        sh 'flutter build ipa --release --export-options-plist=ios/ExportOptions.plist || flutter build ipa --release || true'
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: "${params.FLUTTER_DIR}/build/ios/ipa/*.ipa", allowEmptyArchive: true
                }
            }
        }

        stage('Deploy to Google Play') {
            when {
                expression {
                    return fileExists("${params.FLUTTER_DIR}/build/app/outputs/bundle/release/app-release.aab")
                }
            }
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh """
                        fastlane supply \
                          --aab build/app/outputs/bundle/release/app-release.aab \
                          --track internal \
                          --json_key /Users/renaud/.jenkins/credentials/google-play-service-account.json \
                          --skip_upload_metadata \
                          --skip_upload_images \
                          --skip_upload_screenshots
                    """
                }
            }
        }

        stage('Deploy to TestFlight') {
            when {
                expression {
                    def ipaFiles = findFiles(glob: "${params.FLUTTER_DIR}/build/ios/ipa/*.ipa")
                    return ipaFiles.length > 0
                }
            }
            steps {
                dir("${params.FLUTTER_DIR}") {
                    sh '''
                        fastlane pilot upload \
                          --ipa build/ios/ipa/*.ipa \
                          --api_key_path /Users/renaud/.jenkins/credentials/asc_api_key.json
                    '''
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
        success {
            withCredentials([
                string(credentialsId: 'telegram-bot-token', variable: 'TG_TOKEN'),
                string(credentialsId: 'telegram-chat-id', variable: 'TG_CHAT')
            ]) {
                sh """
                    curl -s "https://api.telegram.org/bot\${TG_TOKEN}/sendMessage" \
                      -d "chat_id=\${TG_CHAT}" \
                      -d "parse_mode=HTML" \
                      -d "text=<b>BUILD OK</b> %E2%9C%85%0A%0AJob: <b>${env.JOB_NAME}</b>%0ABuild: %23${env.BUILD_NUMBER}%0ABranche: ${env.GIT_BRANCH ?: 'N/A'}%0A%0A<a href='${env.BUILD_URL}'>Voir le build</a>"
                """
            }
        }
        failure {
            withCredentials([
                string(credentialsId: 'telegram-bot-token', variable: 'TG_TOKEN'),
                string(credentialsId: 'telegram-chat-id', variable: 'TG_CHAT')
            ]) {
                sh """
                    curl -s "https://api.telegram.org/bot\${TG_TOKEN}/sendMessage" \
                      -d "chat_id=\${TG_CHAT}" \
                      -d "parse_mode=HTML" \
                      -d "text=<b>BUILD FAILED</b> %E2%9D%8C%0A%0AJob: <b>${env.JOB_NAME}</b>%0ABuild: %23${env.BUILD_NUMBER}%0ABranche: ${env.GIT_BRANCH ?: 'N/A'}%0A%0A<a href='${env.BUILD_URL}'>Voir le build</a>"
                """
            }
        }
    }
}
