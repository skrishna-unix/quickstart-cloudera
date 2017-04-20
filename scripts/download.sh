#!/bin/bash -e

usage() {
		cat <<EOF
		Usage: $0 [options]
				-h print usage
				-b S3 BuildBucket that contains scripts/templates/media dir
EOF
		exit 1
}

# ------------------------------------------------------------------
#          Read all inputs
# ------------------------------------------------------------------



while getopts ":h:b:" o; do
		case "${o}" in
				h) usage && exit 0
						;;
				b) BUILDBUCKET=${OPTARG}
								;;
				*)
						usage
						;;
		esac
done



VERSION=2.1.0
BUILDBUCKET=$(echo ${BUILDBUCKET} | sed 's/"//g')


# ------------------------------------------------------------------
#          Download all the scripts needed for installing Cloudera
# ------------------------------------------------------------------

# first update time
yum -y install ntp
service ntpd start
ntpdate  -u 0.amazon.pool.ntp.org

mkdir -p /home/ec2-user/cloudera/misc/
mkdir -p /home/ec2-user/cloudera/aws

# New! 1.5.1!
mkdir -p /home/ec2-user/cloudera/setup-default
cd /home/ec2-user/cloudera
unzip  setup-default.zip

export DIRECTOR_LATEST_VERSION=2.1.0
AWS_SIMPLE_CONF=/home/ec2-user/cloudera/setup-default/aws.simple.conf
AWS_REFERENCE_CONF=/home/ec2-user/cloudera/setup-default/aws.reference.conf
wget https://s3.amazonaws.com/${BUILDBUCKET}/media/aws.simple.conf.${DIRECTOR_LATEST_VERSION} --output-document=${AWS_SIMPLE_CONF}
wget https://s3.amazonaws.com/${BUILDBUCKET}/media/aws.reference.conf.${DIRECTOR_LATEST_VERSION} --output-document=${AWS_REFERENCE_CONF}

for f in RHELami.py
do
   wget https://s3.amazonaws.com/${BUILDBUCKET}/scripts/$f --output-document=/home/ec2-user/cloudera/misc/$f
done


wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip --output-document=/home/ec2-user/cloudera/aws/awscli-bundle.zip
wget https://s3.amazonaws.com/${BUILDBUCKET}/media/jq --output-document=/home/ec2-user/cloudera/aws/jq
wget https://s3.amazonaws.com/${BUILDBUCKET}/media/setup-default.zip --output-document=/home/ec2-user/cloudera/setup-default.zip

cd /home/ec2-user/cloudera/aws
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
cd /home/ec2-user/cloudera/aws
chmod 755 ./jq
export JQ_COMMAND=/home/ec2-user/cloudera/aws/jq
export AWS_INSTANCE_IAM_ROLE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)
export AWS_ACCESSKEYID=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${AWS_INSTANCE_IAM_ROLE} | ${JQ_COMMAND} '.AccessKeyId'  | sed 's/^"\(.*\)"$/\1/')
export AWS_SECRETACCESSKEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/${AWS_INSTANCE_IAM_ROLE} | ${JQ_COMMAND} '.SecretAccessKey' | sed 's/^"\(.*\)"$/\1/')
export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | ${JQ_COMMAND} '.region'  | sed 's/^"\(.*\)"$/\1/')
export AWS_INSTANCEID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | ${JQ_COMMAND} '.instanceId' | sed 's/^"\(.*\)"$/\1/' )
export RHEL_VERSION_HVM=7.1
export AWS_HVM_AMI=$(/usr/bin/python /home/ec2-user/cloudera/misc/RHELami.py -v ${RHEL_VERSION_HVM} -r ${AWS_DEFAULT_REGION} -t hvm)

# Replace these via CloudFormation User-Data
export AWS_SUBNETID=SUBNETID-CFN-REPLACE
export AWS_PRIVATESUBNETID=PRIVATESUBNETID-CFN-REPLACE
export AWS_PUBLICSUBNETID=PUBLICSUBNETID-CFN-REPLACE
export AWS_SECURITYGROUPIDS=SECUTIRYGROUPIDS-CFN-REPLACE
export AWS_KEYNAME=KEYNAME-CFN-REPLACE
export AWS_CDH_INSTANCE=HADOOPINSTANCE-TYPE-CFN-REPLACE
export AWS_CDH_COUNT=HADOOPINSTANCE-COUNT-CFN-REPLACE

declare -A IsHVMSupported

IsHVMSupported=( ["m4.large"]=1
				["m4.xlarge"]=1
				["m4.2xlarge"]=1 
				["m3.xlarge"]=1
				["m3.xlarge"]=1
				["m3.2xlarge"]=1
				["m1.small"]=1
				["m1.medium"]=1
				["m1.large"]=0
				["m1.xlarge"]=0
				["c3.large"]=1
				["c3.xlarge"]=1
				["c3.2xlarge"]=1
				["c3.4xlarge"]=1
				["c3.8xlarge"]=1
				["c1.medium"]=1
				["c1.xlarge"]=1
				["cc2.8xlarge"]=1
				["g2.2xlarge"]=1
				["cg1.4xlarge"]=1
				["m2.xlarge"]=0
				["m2.2xlarge"]=0
				["m2.4xlarge"]=0
				["cr1.8xlarge"]=1
				["hi1.4xlarge"]=1
				["hs1.8xlarge"]=1
				["i2.xlarge"]=1
				["i2.2xlarge"]=1
				["i2.4xlarge"]=1
				["i2.8xlarge"]=1
				["r3.large"]=1
				["r3.xlarge"]=1
				["r3.2xlarge"]=1
				["r3.4xlarge"]=1
				["r3.8xlarge"]=1
				["t1.micro"]=0
				["t2.micro"]=1
				["t2.small"]=1
				["t2.medium"]=1
)

ishvm=${IsHVMSupported[${AWS_CDH_INSTANCE}]}
if [ -z ${ishvm} ]; then
	export AWS_AMI=${AWS_HVM_AMI}
elif [ ${ishvm} -eq 1 ];then
	export AWS_AMI=${AWS_HVM_AMI}
else
	echo "ERROR: Supported AMI not found!"
	exit 1
fi

# Escape / to keep sed happy
# This is not used currently.
AWS_ACCESSKEYID=$(echo $AWS_ACCESSKEYID | sed 's/\//\\\//g')
AWS_SECRETACCESSKEY=$(echo $AWS_SECRETACCESSKEY | sed 's/\//\\\//g')

CURRENT_DATE=$(date +"%m-%d-%Y")
AWS_PLACEMENT_GROUP_NAME=AWS-PLACEMENT-GROUP-${AWS_DEFAULT_REGION}-${CURRENT_DATE}

# Create PlacementGroup
/usr/local/bin/aws ec2 create-placement-group --group-name ${AWS_PLACEMENT_GROUP_NAME} --strategy cluster


	# For private subnet, use subnetId: privatesubnetId-REPLACE-ME
	# For public subnet, use subnetId: publicsubnetId-REPLACE-ME


for AWS_CONF_FILE in ${AWS_SIMPLE_CONF} ${AWS_REFERENCE_CONF}
do
	sed -i "s/accessKeyId-REPLACE-ME/${AWS_ACCESSKEYID}/g" ${AWS_CONF_FILE}
	sed -i "s/secretAccessKey-REPLACE-ME/${AWS_SECRETACCESSKEY}/g" ${AWS_CONF_FILE}
	sed -i "s/region-REPLACE-ME/${AWS_DEFAULT_REGION}/g" ${AWS_CONF_FILE}
	sed -i "s/privatesubnetId-REPLACE-ME/${AWS_PRIVATESUBNETID}/g" ${AWS_CONF_FILE}
	sed -i "s/publicsubnetId-REPLACE-ME/${AWS_PUBLICSUBNETID}/g" ${AWS_CONF_FILE}
	sed -i "s/subnetId-REPLACE-ME/${AWS_SUBNETID}/g" ${AWS_CONF_FILE}
	sed -i "s/securityGroupsIds-REPLACE-ME/${AWS_SECURITYGROUPIDS}/g" ${AWS_CONF_FILE}
	sed -i "s/keyName-REPLACE-ME/${AWS_KEYNAME}/g" ${AWS_CONF_FILE}
	sed -i "s/type-REPLACE-ME/${AWS_CDH_INSTANCE}/g" ${AWS_CONF_FILE}
	sed -i "s/count-REPLACE-ME/${AWS_CDH_COUNT}/g" ${AWS_CONF_FILE}
	sed -i "s/image-REPLACE-ME/${AWS_AMI}/g" ${AWS_CONF_FILE}
	sed -i "s/ami-HVM-REPLACE-ME/${AWS_HVM_AMI}/g" ${AWS_CONF_FILE}
	sed -i "s/placementGroup-REPLACE-ME/${AWS_PLACEMENT_GROUP_NAME}/g" ${AWS_CONF_FILE}
	sed -i "s/instanceNamePrefix.*/instanceNamePrefix: cloudera-director-${AWS_INSTANCEID}/g" ${AWS_CONF_FILE}

done

# change ownership
chown -R ec2-user /home/ec2-user/cloudera

export INSTANCEKEYPAIR=/home/ec2-user/cloudera-aws-quickstart-${CURRENT_DATE}.pem
export INSTANCEKEYPAIRESC=\\/home\\/ec2\\-user\\/cloudera\\-aws\\-quickstart\\-${CURRENT_DATE}\\.pem


# Pull bits from Cloudera repo
DIRECTOR_VERSION='2.4.0-1.director240.p0.25.el7'
yum-config-manager --add-repo http://archive.cloudera.com/director/redhat/7/x86_64/director/cloudera-director.repo
yum install -y cloudera-director-server-${DIRECTOR_VERSION} cloudera-director-client-${DIRECTOR_VERSION}


/usr/local/bin/aws  ec2 delete-key-pair --key-name aws-cloudera-quickstart-${CURRENT_DATE} \
                                        --region ${AWS_DEFAULT_REGION}


/usr/local/bin/aws  ec2 create-key-pair --key-name aws-cloudera-quickstart-${CURRENT_DATE} \
                                        --region ${AWS_DEFAULT_REGION} \
                                        | ${JQ_COMMAND} -r ".KeyMaterial"  > ${INSTANCEKEYPAIR}

chown ec2-user:ec2-user ${INSTANCEKEYPAIR}

for AWS_CONF_FILE in ${AWS_SIMPLE_CONF} ${AWS_REFERENCE_CONF}
do
    echo "Changing /privateKey-REPLACE-ME/${INSTANCEKEYPAIRESC}/g in ${AWS_CONF_FILE}"
    sed -i "s/privateKey-REPLACE-ME/${INSTANCEKEYPAIRESC}/g" ${AWS_CONF_FILE}
done


cd /tmp
yum install python -y
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
pip install boto

cd /home/ec2-user/cloudera
unzip  setup-default.zip
cd /home/ec2-user/cloudera/setup-default
pip install setuptools --upgrade
pip install virtualenv
pip install -r requirements.txt


wget https://s3.amazonaws.com/${BUILDBUCKET}/scripts/setupdefaults.sh --output-document=/home/ec2-user/cloudera/setup-default/setupdefaults.sh

service cloudera-director-server start
# Strange issues happen when cloudera-director-server isn't completely started
/bin/sleep 60
sh /home/ec2-user/cloudera/setup-default/setupdefaults.sh -t CLUSTERTYPE-REPLACE-ME

# cleanup
for f in /home/ec2-user/cloudera/setup-default.zip
do
    if [ -f "$f" ]; then
      rm -rf "$f"
    fi
done

