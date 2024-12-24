pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                script {
                    // Use SSH to pull from your GitHub repository
                    checkout([$class: 'GitSCM', 
                        branches: [[name: "*/${env.BRANCH_NAME}"]],
                        userRemoteConfigs: [[
                            url: 'git@github.com:spaceboi21/devops-mini-project.git',
                            credentialsId: 'GITHUB_SSH_KEY' // Replace with the ID of your Jenkins SSH credentials
                        ]]
                    ])
                }
            }
        }

        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'dev'
                    branch 'testing'
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "Building Docker image for branch: ${env.BRANCH_NAME}"

                    // Build the Docker image locally (on your Jenkins host or dev server)
                    sh """
                      docker build -t my-node-app:${env.BRANCH_NAME} .
                    """

                    // (Optional) Uncomment if pushing to a Docker registry:
                    // sh """
                    //   docker tag my-node-app:${env.BRANCH_NAME} your-dockerhub-user/my-node-app:${env.BRANCH_NAME}
                    //   docker push your-dockerhub-user/my-node-app:${env.BRANCH_NAME}
                    // """
                }
            }
        }

        stage('Deploy to Dev') {
            when {
                branch 'dev'
            }
            steps {
                script {
                    echo "Deploying to Dev environment..."

                    // SSH into Dev instance and deploy
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                          ssh -o StrictHostKeyChecking=no ubuntu@ec2-16-170-223-61.eu-north-1.compute.amazonaws.com \\
                          'docker stop app_dev || true && docker rm app_dev || true && \\
                           docker run -d --name app_dev -p 3000:3000 my-node-app:dev'
                        """
                    }
                }
            }
        }

        stage('Deploy to Testing') {
            when {
                branch 'testing'
            }
            steps {
                script {
                    echo "Deploying to Testing environment..."

                    // SSH into Testing instance and deploy
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                          ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-109-124.eu-north-1.compute.amazonaws.com \\
                          'docker stop app_testing || true && docker rm app_testing || true && \\
                           docker run -d --name app_testing -p 3000:3000 my-node-app:testing'
                        """
                    }
                }
            }
        }

        stage('Run Tests in Testing Environment') {
            when {
                branch 'testing'
            }
            steps {
                script {
                    echo "Running automated tests on the Testing environment..."

                    // Run tests inside the Testing container
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                          ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-109-124.eu-north-1.compute.amazonaws.com \\
                          'docker exec app_testing npm test'
                        """
                    }
                }
            }
        }

        stage('Merge Testing to Main') {
            when {
                allOf {
                    branch 'testing'
                    expression { currentBuild.currentResult == "SUCCESS" }
                }
            }
            steps {
                script {
                    echo "All tests passed. Merging from testing to main..."

                    // (Optional) Uncomment to automatically merge 'testing' into 'main'
                    // This requires separate Git credentials with commit/push permissions
                    // sshagent (credentials: ['GIT_CREDENTIALS']) {
                    //     sh """
                    //       git config user.name 'spaceboi21'
                    //       git config user.email 'ma_abbas2001@hotmail.com'
                    //       git checkout main
                    //       git merge origin/testing
                    //       git push origin main
                    //     """
                    // }
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                script {
                    echo "Deploying to Staging environment..."

                    // SSH into Staging instance and deploy
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                          ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-137-150.eu-north-1.compute.amazonaws.com \\
                          'docker stop app_staging || true && docker rm app_staging || true && \\
                           docker run -d --name app_staging -p 3000:3000 my-node-app:main'
                        """
                    }
                }
            }
        }
    }
}
