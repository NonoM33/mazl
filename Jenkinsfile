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
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    dir("${params.FLUTTER_DIR}") {
                        sh '''#!/bin/bash
                            set -e

                            # Step 0: Unlock CI keychain for codesign
                            security unlock-keychain -p "ci2026" ~/Library/Keychains/ci.keychain-db
                            security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "ci2026" ~/Library/Keychains/ci.keychain-db > /dev/null
                            security list-keychains -s ~/Library/Keychains/ci.keychain-db ~/Library/Keychains/login.keychain-db

                            # Step 1: Build unsigned app (fast, ~90s)
                            flutter build ios --no-codesign --release

                            APP="build/ios/iphoneos/Runner.app"
                            CERT="Apple Distribution: Renaud cosson (66GH4N82J9)"
                            PROFILE_UUID="399500f9-c3a4-43b5-8b3e-8a8cb906c050"
                            PROFILE="$HOME/Library/MobileDevice/Provisioning Profiles/${PROFILE_UUID}.mobileprovision"
                            ENT="ios/Runner/Runner.entitlements"
                            IPA_DIR="build/ios/ipa"

                            # Step 2: Embed provisioning profile
                            cp "$PROFILE" "$APP/embedded.mobileprovision"

                            # Step 3: Sign all frameworks
                            for fw in "$APP/Frameworks/"*.framework; do
                                codesign -f -s "$CERT" "$fw"
                            done
                            for dylib in "$APP/Frameworks/"*.dylib; do
                                [ -f "$dylib" ] && codesign -f -s "$CERT" "$dylib"
                            done

                            # Step 4: Sign the main app
                            codesign -f -s "$CERT" --entitlements "$ENT" "$APP"

                            # Step 5: Verify signature
                            codesign -dvv "$APP"

                            # Step 6: Create IPA
                            mkdir -p "$IPA_DIR"
                            rm -f "$IPA_DIR"/*.ipa
                            TMPD=$(mktemp -d)
                            mkdir -p "$TMPD/Payload"
                            cp -R "$APP" "$TMPD/Payload/"
                            cd "$TMPD"
                            zip -qr "$WORKSPACE/${FLUTTER_DIR}/$IPA_DIR/Runner.ipa" Payload
                            rm -rf "$TMPD"
                            cd "$WORKSPACE/${FLUTTER_DIR}"

                            echo "IPA created:"
                            ls -lh "$IPA_DIR/"*.ipa
                        '''
                    }
                }
            }
            post {
                always {
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
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    dir("${params.FLUTTER_DIR}") {
                        script {
                            def packageName = sh(
                                script: "grep -rh 'applicationId' android/app/build.gradle android/app/build.gradle.kts 2>/dev/null | grep -oE '\"[a-z][a-z0-9_.]+\"' | head -1 | tr -d '\"'",
                                returnStdout: true
                            ).trim()
                            if (packageName) {
                                sh """
                                    fastlane supply \
                                      --aab build/app/outputs/bundle/release/app-release.aab \
                                      --track internal \
                                      --package_name ${packageName} \
                                      --json_key /Users/renaud/.jenkins/credentials/google-play-service-account.json \
                                      --skip_upload_metadata \
                                      --skip_upload_images \
                                      --skip_upload_screenshots
                                """
                            } else {
                                echo "Package name not found in build.gradle, skipping Google Play deploy"
                            }
                        }
                    }
                }
            }
        }

        stage('Deploy to TestFlight') {
            when {
                expression {
                    return sh(script: "ls ${params.FLUTTER_DIR}/build/ios/ipa/*.ipa 2>/dev/null", returnStatus: true) == 0
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    dir("${params.FLUTTER_DIR}") {
                        sh '''
                            fastlane pilot upload \
                              --ipa build/ios/ipa/*.ipa \
                              --api_key_path /Users/renaud/.jenkins/credentials/asc_api_key.json
                        '''
                    }
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
                string(credentialsId: 'telegram-chat-id', variable: 'TG_CHAT'),
                string(credentialsId: 'anthropic-api-key', variable: 'ANTHROPIC_KEY')
            ]) {
                sh '''#!/bin/bash
                    set +e

                    # Fetch last 150 lines of build log via Jenkins API
                    BUILD_LOG=$(curl -s -u "renaud:24536Tetr@" "${BUILD_URL}consoleText" | tail -150)

                    if [ -z "$BUILD_LOG" ]; then
                        echo "[WARN] Could not fetch build log, skipping Claude analysis"
                        ANALYSIS="Log indisponible"
                    else
                        # Write Claude request payload
                        python3 -c "
import json, sys
log = sys.stdin.read()
payload = {
    'model': 'claude-sonnet-4-20250514',
    'max_tokens': 1024,
    'messages': [{
        'role': 'user',
        'content': 'Tu es un expert CI/CD Flutter. Analyse ce log de build Jenkins qui a echoue. Reponds en francais, max 800 caracteres. Donne: 1) Le stage qui a echoue 2) La cause exacte 3) Comment corriger\\n\\nLog:\\n' + log[-4000:]
    }]
}
json.dump(payload, open('/tmp/claude_request.json', 'w'))
" <<< "$BUILD_LOG"

                        # Call Claude API
                        HTTP_CODE=$(curl -s -o /tmp/claude_response.json -w '%{http_code}' https://api.anthropic.com/v1/messages \
                          -H "x-api-key: ${ANTHROPIC_KEY}" \
                          -H "anthropic-version: 2023-06-01" \
                          -H "content-type: application/json" \
                          -d @/tmp/claude_request.json)

                        echo "[DEBUG] Claude API HTTP status: $HTTP_CODE"

                        if [ "$HTTP_CODE" = "200" ]; then
                            ANALYSIS=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data['content'][0]['text'])
except Exception as e:
    print('Erreur parsing: ' + str(e))
" < /tmp/claude_response.json)
                        else
                            echo "[WARN] Claude API returned HTTP $HTTP_CODE"
                            cat /tmp/claude_response.json 2>/dev/null
                            ANALYSIS="Analyse indisponible (HTTP $HTTP_CODE)"
                        fi

                        rm -f /tmp/claude_request.json /tmp/claude_response.json
                    fi

                    # Send to Telegram
                    MSG=$(printf '❌ BUILD FAILED\n\nJob: %s\nBuild: #%s\n\n🤖 Analyse Claude:\n%s\n\n%s' \
                      "${JOB_NAME}" "${BUILD_NUMBER}" "$ANALYSIS" "${BUILD_URL}")

                    curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
                      -d "chat_id=${TG_CHAT}" \
                      --data-urlencode "text=${MSG}"
                '''
            }
        }
    }
}
