import argparse
import subprocess
import json
import dateutil.parser

aws_cmd = '/usr/local/bin/aws '

def exe_cmd(cmd,cwd=None):
    if cwd == None:
        proc = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True)
        proc.wait()
        (out, err) = proc.communicate()
        output = {}
        output['out'] = out
        output['err'] = err
        return output
    else:
        proc = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True,cwd=cwd)
        proc.wait()
        (out, err) = proc.communicate()
        output = {}
        output['out'] = out
        output['err'] = err
        return output

def get_creationdate(data):
    return  dateutil.parser.parse(data['CreationDate'])


def main():
    parser = argparse.ArgumentParser(description='Find latest RHEL AMI')
    parser.add_argument('-v', dest="version",metavar="VERSION",required = True,
                              help='RHEL Version')
    parser.add_argument('-r', dest="region",metavar="REGION",required = True,
                              help='REGION to query AMI')
    parser.add_argument('-t', dest="type",metavar="AMI_TYPE",required = True,
                              help='AMI Type (hvm)')

    args = parser.parse_args()
    version = args.version
    region = args.region
    ami_type = args.type

    ami_name = 'RHEL-'+ version + "*" + "-x86_64*";

    cmd = aws_cmd + " ec2 describe-images --filters \"Name=name,Values=AMI-PLACEHOLDER\" \"Name=virtualization-type,Values=VTYPE-PLACEHOLDER\" --owners 309956199498 --region REGION-PLACEHOLDER"
    cmd = cmd.replace('AMI-PLACEHOLDER',ami_name)
    cmd = cmd.replace('VTYPE-PLACEHOLDER',ami_type)
    cmd = cmd.replace('REGION-PLACEHOLDER',region)

    output = exe_cmd(cmd)
    images = output['out']
    val = json.loads(images)
    images =  val['Images']
    sorted_images = sorted(images,key = get_creationdate,reverse=True)
    print sorted_images[0]['ImageId']



if __name__ == "__main__":
    main()
