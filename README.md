# AWS Infrastructure Project for ViewPost

This project implements a highly available and scalable AWS infrastructure for a Python/Flask web application, utilizing modern DevOps practices and Infrastructure as Code (IaC) principles.

## Architecture Overview

Our infrastructure leverages several AWS services to create a robust and scalable environment:

- **Networking**: Multi-AZ VPC with public and private subnets
- **Compute**: Auto Scaling Group with EC2 instances
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Database**: Multi-AZ RDS configuration
- **Storage**: S3 for artifact management
- **CI/CD**: Integrated pipeline with CodeBuild and CodeDeploy
- **Monitoring**: CloudWatch dashboards and alarms

### Architecture Diagram

```
[Internet] --> [ALB] --> [ASG/EC2] --> [RDS]
                          |
                          v
                        [S3]
```

## Prerequisites

Before deploying this infrastructure, ensure you have:

- AWS CLI installed and configured with appropriate credentials
- Python 3.8 or higher
- Git
- Proper AWS permissions to create and manage resources

## Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/guirgsilva/viewpost.git
cd viewpost
```

2. Set up script permissions:
```bash
chmod +x scripts/*.sh
chmod +x deploy.sh
chmod +x delete.sh
```

3. Configure GitHub token in AWS Secrets Manager:
```bash
aws secretsmanager create-secret \
    --name github/aws-token \
    --secret-string '{"token":"your-github-token"}'
```

## Deployment Process

To deploy the complete infrastructure:

```bash
./deploy.sh
```

The deployment script executes the following steps:
1. Network infrastructure creation (VPC, subnets)
2. Storage configuration (S3)
3. Database setup (RDS)
4. Compute resource provisioning (EC2, ASG, ALB)
5. Monitoring implementation (CloudWatch)
6. CI/CD pipeline configuration

### Deployment Order

1. NetworkStack
2. StorageStack
3. DatabaseStack
4. ComputeStack
5. MonitoringStack
6. CICDStack

## Project Structure

```
.
├── app/                    # Flask application
│   ├── __init__.py
│   └── app.py
├── appspec.yml            # CodeDeploy configuration
├── buildspec*.yml         # CodeBuild configurations
├── cloudformation/        # CloudFormation templates
│   ├── cicd.yaml
│   ├── compute.yaml
│   ├── database.yaml
│   ├── monitoring.yaml
│   ├── network.yaml
│   └── storage.yaml
├── scripts/               # Deployment scripts
└── requirements.txt       # Python dependencies
```

## Testing

After deployment, test the application endpoints:

- **Home**: `http://<alb-dns>/`
- **Health Check**: `http://<alb-dns>/health`
- **Stress Test**: `http://<alb-dns>/stress/10`
- **Error Test**: `http://<alb-dns>/error`

To retrieve the ALB DNS:
```bash
aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[*].DNSName' \
    --output text
```

## Monitoring Setup

The monitoring infrastructure includes:
- CloudWatch dashboard with key metrics
- Configured alarms for:
  - CPU utilization > 70%
  - Memory usage > 80%
  - Error rate threshold breaches

## Infrastructure Cleanup

To remove all created resources:

```bash
./delete.sh
```

## Security Implementation

Our security measures include:
- Resources deployed within private VPC
- Access restricted through ALB
- Database in private subnet
- Secrets managed via AWS Secrets Manager
- Least privilege security groups

## Cost Considerations

The infrastructure utilizes:
- EC2 t2.micro instances (free tier eligible)
- RDS db.t3.micro instance
- Application Load Balancer (not free tier eligible)
- S3 storage (usage-based pricing)

## Contributing Guidelines

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Submit a Pull Request

## Support Channels

For support:
- Open an issue on GitHub
- Contact the development team

## Development Team

ViewPost Systems Engineering Team

For more information about this infrastructure or assistance with deployment, please contact the Systems Engineering team.

## License

Proprietary - ViewPost © 2024