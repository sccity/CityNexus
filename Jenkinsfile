pipeline {
    agent {
        kubernetes {
            label "${env.JOB_NAME}-${BUILD_NUMBER}"
            containerTemplate {
                name 'jnlp'
                image 'sccity/jenkins-agent-php:0.0.4'
            }
        }
    }

    stages {
        stage('Database') {
            steps {
                container('jnlp') {
                    sh '''
                    echo "development" | su -c "/etc/init.d/mariadb start" root
                    until mysqladmin ping --silent; do sleep 3; done
                    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '';" > setup.sql
                    echo "FLUSH PRIVILEGES;" >> setup.sql
                    echo "CREATE DATABASE citynexus;" >> setup.sql
                    echo "development" | su -c "mysql -u root < setup.sql" root
                    '''
                }
            }
        }

        stage('Dependencies') {
            steps {
                container('jnlp') {
                    withCredentials([string(credentialsId: 'fontawesome-npm-token', variable: 'FA_TOKEN')]) {
                        sh '''
                        composer install
                        echo "@fortawesome:registry=https://npm.fontawesome.com/" >> .npmrc
                        echo "//npm.fontawesome.com/:_authToken=${FA_TOKEN}" >> .npmrc
                        npm install
                        '''
                    }
                }
            }
        }

        stage('Environment') {
            steps {
                container('jnlp') {
                    sh '''
                    cp .env.example .env
                    php artisan key:generate
                    sed -i 's/^LOG_LEVEL=.*/LOG_LEVEL=debug/' .env
                    sed -i 's/^DB_HOST=.*/DB_HOST=localhost/' .env
                    sed -i 's/^DB_DATABASE=.*/DB_DATABASE=citynexus/' .env
                    sed -i 's/^DB_USERNAME=.*/DB_USERNAME=root/' .env
                    sed -i 's/^DB_PASSWORD=.*/DB_PASSWORD=/' .env
                    '''
                }
            }
        }

        stage('Run') {
            steps {
                container('jnlp') {
                    sh '''
                    php artisan migrate
                    php artisan db:seed
                    ./clean.sh
                    ./vendor/bin/pest
                    '''
                }
            }
        }
    }

    post {
        success {
            script {
                withCredentials([usernamePassword(credentialsId: 'git', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    commit_hash=$(git rev-parse HEAD | head -c 7)
                    branch=$(git name-rev --name-only HEAD | cut -d '/' -f 3-)
                    echo "Branch: ${branch} - Commit Hash: $commit_hash"
                    git config --global user.email "jenkins@email.santaclarautah.gov"
                    git config --global user.name "Jenkins"
                    if git rev-parse "$commit_hash" >/dev/null 2>&1; then
                        echo "Tag $commit_hash already exists. Skipping tag creation."
                    else
                        export GIT_ASKPASS=$(mktemp)
                        echo '#!/bin/sh' > \$GIT_ASKPASS
                        echo 'echo "\$GIT_PASSWORD"' >> \$GIT_ASKPASS
                        chmod +x \$GIT_ASKPASS
                        git tag -a "$commit_hash" -m "Automated Build ${commit_hash}"
                        git push origin tag "$commit_hash"
                        rm -f \$GIT_ASKPASS
                    fi
                    '''
                }
            }
        }
        fixed {
            script {
                def logLines = currentBuild.rawBuild.getLog(100).join("\n")
                emailext(
                    to: 'lhaynie@santaclarautah.gov, rlevsey@santaclarautah.gov',
                    subject: "Build Fixed: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: """
                        <strong>Project:</strong> ${env.JOB_NAME}<br>
                        <strong>Build Number:</strong> ${env.BUILD_NUMBER}<br>
                        <strong>Result:</strong> ${currentBuild.currentResult}<br>
                        <strong>URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a><br><br>
                        <strong>Last 100 lines of build log:</strong>
                        <pre>${logLines}</pre>
                        """,
                    mimeType: 'text/html'
                )
            }
        }
        failure {
            script {
                def logLines = currentBuild.rawBuild.getLog(100).join("\n")
                emailext(
                    to: 'lhaynie@santaclarautah.gov, rlevsey@santaclarautah.gov',
                    subject: "Build Failed: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                    body: """
                        <strong>Project:</strong> ${env.JOB_NAME}<br>
                        <strong>Build Number:</strong> ${env.BUILD_NUMBER}<br>
                        <strong>Result:</strong> ${currentBuild.currentResult}<br>
                        <strong>URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a><br><br>
                        <strong>Last 100 lines of build log:</strong>
                        <pre>${logLines}</pre>
                        """,
                    mimeType: 'text/html'
                )
            }
        }
    }
}
