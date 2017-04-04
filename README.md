# quickstart-cloudera

This Quick Start helps you build a multi-node Cloudera Enterprise Data Hub (EDH) cluster on the AWS Cloud by integrating Cloudera Director with AWS services such as Amazon EC2 and Amazon VPC. EDH enables you to store your data with the flexibility to run a variety of enterprise workloads--including batch processing, interactive SQL, enterprise search, and advanced analytics--while utilizing robust security, governance, data protection, and management. You can choose to deploy Cloudera EDH into a new VPC or your existing VPC. The Quick Start includes AWS CloudFormation templates that automate each option. 

In this reference architecture, we support two options for deploying Cloudera's Enterprise Data Hub within an Amazon VPC. One option is to launch all the nodes within a public subnet providing direct Internet access. The second option is to deploy all the nodes within a private subnet. The reference deployment builds both a public and private subnet, and the cluster can be deployed in either subnet using the configuration file.

### EDH Cluster in a Public Subnet

![Quick Start Cloudera Architecture](https://docs.aws.amazon.com/quickstart/latest/cloudera/images/cloudera-public-subnet.png )

### EDH Cluster in a Private Subnet

![Quick Start Cloudera Architecture](https://docs.aws.amazon.com/quickstart/latest/cloudera/images/cloudera-private-subnet.png )

Deployment steps:

1. Sign up for an AWS account at http://aws.amazon.com, select a region, and create a key pair.
2. In the AWS CloudFormation console, launch one of the following templates to build a new stack:
  * /templates/cloudera-master.template (to deploy Cloudera EDH into a new VPC)
  * /templates/cloudera.template (to deploy Cloudera EDH into your existing VPC)
3. [Configure](http://docs.aws.amazon.com/quickstart/latest/cloudera/step3.html) the cluster and EDH services.
4. [Deploy](http://docs.aws.amazon.com/quickstart/latest/cloudera/step4.html) the EDH Cluster.

The Quick Start provides parameters that you can set to customize your deployment. For architectural details, best practices, step-by-step instructions, and customization options, see the [deployment guide].(http://docs.aws.amazon.com/quickstart/latest/cloudera/welcome.html)
