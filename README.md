# quickstart-cloudera
## Cloudera EDH on the AWS Cloud

This Quick Start helps you build a multi-node Cloudera Enterprise Data Hub (EDH) cluster on the AWS Cloud by integrating Cloudera Director with AWS services such as Amazon EC2 and Amazon VPC. EDH enables you to store your data with the flexibility to run a variety of enterprise workloads--including batch processing, interactive SQL, enterprise search, and advanced analytics--while utilizing robust security, governance, data protection, and management. You can choose to deploy Cloudera EDH into a new VPC or your existing VPC. The Quick Start includes AWS CloudFormation templates that automate each option. 

In this reference architecture, we support two options for deploying Cloudera's Enterprise Data Hub within a virtual private cloud (VPC). One option is to launch all the nodes within a public subnet providing direct internet access. The second option is to deploy all the nodes within a private subnet. The reference deployment builds both a public and private subnet, and the cluster can be deployed in either subnet using the configuration file.

### EDH cluster in a public subnet

![Quick Start Cloudera Architecture](https://docs.aws.amazon.com/quickstart/latest/cloudera/images/cloudera-public-subnet.png)

### EDH cluster in a private subnet

![Quick Start Cloudera Architecture](https://docs.aws.amazon.com/quickstart/latest/cloudera/images/cloudera-private-subnet.png)

For architectural details, best practices, step-by-step instructions, and customization options, see the 
[deployment guide](https://fwd.aws/NPbPz).

To post feedback, submit feature ideas, or report bugs, use the **Issues** section of this GitHub repo.
If you'd like to submit code for this Quick Start, please review the [AWS Quick Start Contributor's Kit](https://aws-quickstart.github.io/). 
