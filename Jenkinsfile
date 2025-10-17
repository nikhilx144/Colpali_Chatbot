pipeline {
    agent any

    tools {
        terraform "terraform-latest"
    }

    environment {
        AWS_REGION     = 'ap-south-2'
        AWS_ACCOUNT_ID = '661979762009'
        // *** CHANGED: New ECR repository for the OpenAI app ***
        ECR_REPO_NAME  = 'colpali-pdf-chatbot' 
        ECR_REPO_URI   = '661979762009.dkr.ecr.ap-south-2.amazonaws.com/colpali-pdf-chatbot'
    }

    stages {
        stage('Prepare Environment') {
            steps {
                // Adds GitHub's public key to the known_hosts file
                sh 'ssh-keyscan github.com >> ~/.ssh/known_hosts'
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withAWS(credentials: 'aws_credentials', region: AWS_REGION) {
                        sh 'terraform init'
                        sh 'terraform apply -auto-approve'
                        script {
                            env.EC2_PUBLIC_IP = sh(returnStdout: true, script: 'terraform output -raw ec2_public_ip').trim()
                        }
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withAWS(credentials: 'aws_credentials', region: AWS_REGION) {
                    sh "docker build -t ${ECR_REPO_URI}:${BUILD_NUMBER} ."
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URI}"
                    sh "docker push ${ECR_REPO_URI}:${BUILD_NUMBER}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no -i \${SSH_KEY} ec2-user@${env.EC2_PUBLIC_IP} '
                            # Log in to ECR on the EC2 instance
                            sudo aws ecr get-login-password --region ${AWS_REGION} | sudo docker login --username AWS --password-stdin ${ECR_REPO_URI}
                            
                            # Pull the new image
                            sudo docker pull ${ECR_REPO_URI}:${BUILD_NUMBER}
                            
                            # Stop and remove the old container if it exists
                            sudo docker stop openai-chatbot || true
                            sudo docker rm openai-chatbot || true
                            
                            # *** CHANGED: Run the new container. No --gpus flag needed. Map port 80 to 8501. ***
                            sudo docker run -d --name openai-chatbot -p 80:8501 ${ECR_REPO_URI}:${BUILD_NUMBER}
                        '
                    """
                }
            }
        }
    }
}