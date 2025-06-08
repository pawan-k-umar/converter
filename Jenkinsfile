pipeline {
    agent any

    parameters {
        string(name: 'BRANCH', defaultValue: 'integration', description: 'Git branch to build')
        string(name: 'DOCKER_TAG', defaultValue: '0.0.1-SNAPSHOT', description: 'Docker image tag')
        string(name: 'HOST_PORT', defaultValue: '9092', description: 'Host port to expose')
        string(name: 'CONTAINER_PORT', defaultValue: '9092', description: 'Container port the app listens on')
    }

    environment {
        DOCKER_IMAGE = "converter-image"
        CONTAINER_NAME = "converter"
        DOCKER = "docker"  // or full path if needed
        GIT_REPO = 'https://github.com/pawan-k-umar/converter.git'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: "${params.BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build with Maven') {
            steps {
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Check Docker') {
            steps {
                sh '''
                    if ! command -v docker >/dev/null 2>&1; then
                        echo "❌ Docker is not installed."
                        exit 1
                    fi

                    if ! systemctl is-active --quiet docker; then
                        echo "⚙️ Starting Docker service..."
                        sudo systemctl start docker
                    fi

                    docker info
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    echo "🔍 Checking if Docker is installed and running..."

                    if ! command -v ${DOCKER} >/dev/null 2>&1; then
                        echo "❌ Docker is not installed. Please install Docker on Ubuntu."
                        exit 1
                    fi

                    if ! ${DOCKER} info >/dev/null 2>&1; then
                        echo "❌ Docker is installed but the daemon is not running. Please start the Docker service."
                        exit 1
                    fi


                    echo "✅ Docker is running. Proceeding to build and run the container..."

                    ${DOCKER} stop ${CONTAINER_NAME} || true
                    ${DOCKER} rm ${CONTAINER_NAME} || true

                    ${DOCKER} build -t ${DOCKER_IMAGE}:${params.DOCKER_TAG} .
                    echo "🚀 Build successful. App should be available for deployment at http://localhost:${params.HOST_PORT}"
                """
            }
        }

         stage('Docker Run') {
            steps {
                sh """
                  ${DOCKER} run -d -p ${params.HOST_PORT}:${params.CONTAINER_PORT} --name ${CONTAINER_NAME} ${DOCKER_IMAGE}:${params.DOCKER_TAG}
                  echo "🚀 Deployment successful. App should be available at http://localhost:${params.HOST_PORT}"
                """
            }
         }
    }
}