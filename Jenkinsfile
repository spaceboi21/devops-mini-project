pipeline {
    agent any

    environment {
        BRANCH_NAME = "${env.BRANCH_NAME ?: 'main'}"
        // Add npm config to address potential permission issues
        NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "Checking out branch: ${BRANCH_NAME}"
                    checkout([$class: 'GitSCM', 
                        branches: [[name: "*/${BRANCH_NAME}"]],
                        userRemoteConfigs: [[
                            url: 'git@github.com:spaceboi21/devops-mini-project.git',
                            credentialsId: 'GITHUB_SSH_KEY'
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
                    echo "Building Docker image for branch: ${BRANCH_NAME}"
                    
                    // Create a .dockerignore if it doesn't exist
                    sh '''
                        echo "node_modules" > .dockerignore
                        echo ".git" >> .dockerignore
                        echo "npm-debug.log" >> .dockerignore
                    '''
                    
                    // Build Docker image with proper error handling
                    sh """
                        # Ensure Docker daemon is running and we have proper permissions
                        docker info
                        
                        # Clean up any old images to free space
                        docker image prune -f
                        
                        # Build the image
                        docker build \
                            --progress=plain \
                            --no-cache \
                            --build-arg NODE_ENV=production \
                            -t my-node-app:${BRANCH_NAME} .
                    """
                }
            }
        }

        stage('Deploy to Dev') {
            when { branch 'dev' }
            steps {
                script {
                    echo "Deploying to Dev environment..."
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@ec2-16-170-223-61.eu-north-1.compute.amazonaws.com '
                                # Pull the image if it exists on the remote
                                docker pull my-node-app:dev || true
                                
                                # Stop and remove existing container
                                docker stop app_dev || true
                                docker rm app_dev || true
                                
                                # Run new container
                                docker run -d \
                                    --name app_dev \
                                    -p 3000:3000 \
                                    --restart unless-stopped \
                                    my-node-app:dev
                                
                                # Clean up old images
                                docker image prune -f
                            '
                        """
                    }
                }
            }
        }

        stage('Deploy to Testing') {
            when { branch 'testing' }
            steps {
                script {
                    echo "Deploying to Testing environment..."
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-109-124.eu-north-1.compute.amazonaws.com '
                                # Pull the image if it exists on the remote
                                docker pull my-node-app:testing || true
                                
                                # Stop and remove existing container
                                docker stop app_testing || true
                                docker rm app_testing || true
                                
                                # Run new container
                                docker run -d \
                                    --name app_testing \
                                    -p 3000:3000 \
                                    --restart unless-stopped \
                                    my-node-app:testing
                                
                                # Clean up old images
                                docker image prune -f
                            '
                        """
                    }
                }
            }
        }

        stage('Run Tests in Testing Environment') {
            when { branch 'testing' }
            steps {
                script {
                    echo "Running automated tests on the Testing environment..."
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-109-124.eu-north-1.compute.amazonaws.com '
                                docker exec app_testing npm test || {
                                    echo "Tests failed!"
                                    exit 1
                                }
                            '
                        """
                    }
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
                    sshagent (credentials: ['DEV_SSH_KEY']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@ec2-51-20-137-150.eu-north-1.compute.amazonaws.com '
                                # Pull the image if it exists on the remote
                                docker pull my-node-app:main || true
                                
                                # Stop and remove existing container
                                docker stop app_staging || true
                                docker rm app_staging || true
                                
                                # Run new container
                                docker run -d \
                                    --name app_staging \
                                    -p 3000:3000 \
                                    --restart unless-stopped \
                                    my-node-app:main
                                
                                # Clean up old images
                                docker image prune -f
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // Clean up Docker images to prevent disk space issues
            sh 'docker image prune -f'
        }
        failure {
            echo 'Pipeline failed! Check the logs for details.'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}