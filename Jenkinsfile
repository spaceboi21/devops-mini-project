pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                script {
                    // Pulls from the current branch (dev, testing, main)
                    checkout scm
                }
            }
        }

        stage('Build Image on Dev (or Jenkins)') {
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
                    
                    // Option A: Build locally on Jenkins host (which is presumably the Dev instance).
                    // If Jenkins has Docker installed + /var/run/docker.sock:
                    sh """
                      docker build -t my-node-app:${env.BRANCH_NAME} .
                    """
                    
                    // Option B (preferred best practice):
                    //   Build the image, then push to Docker Hub/ECR with a tag.
                    //   e.g.:
                    //   docker build -t <your-dockerhub-user>/my-node-app:${env.BRANCH_NAME} .
                    //   docker push <your-dockerhub-user>/my-node-app:${env.BRANCH_NAME}
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
                    // SSH into dev instance (if Jenkins is on a separate host) or run local if Jenkins is the same dev server
                    // We'll assume we DO SSH, to keep it consistent with test/stage steps.
                    
                    // Use Jenkins credentials for SSH
                    // 'sshagent' approach:
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

        stage('Deploy to Test') {
            when {
                branch 'testing'
            }
            steps {
                script {
                    echo "Deploying to Test environment..."
                    // If you built and pushed the image to a registry, you'd do "docker pull" on the test server
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

        stage('Run Tests in Test environment') {
            when {
                branch 'testing'
            }
            steps {
                script {
                    echo "Running automated tests on the Test environment..."
                    // Example: 'docker exec' to run tests, or a separate command
                    // ssh - to run "docker exec app_testing npm test" 
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                          ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-109-124.eu-north-1.compute.amazonaws.com \\
                          'docker exec app_testing npm test'
                        """
                    }
                }
            }
        }

        stage('Merge testing -> main') {
            when {
                allOf {
                    branch 'testing'
                    expression { currentBuild.currentResult == "SUCCESS" }
                }
            }
            steps {
                script {
                    echo "All tests passed. Merging from testing to main..."
                    // Automatic merge or manual. Example of auto merge (needs git push perms):
                    // sh """
                    //   git config user.name 'Jenkins'
                    //   git config user.email 'jenkins@example.com'
                    //   git checkout main
                    //   git merge origin/testing
                    //   git push origin main
                    // """
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
                    // SSH into staging server
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
