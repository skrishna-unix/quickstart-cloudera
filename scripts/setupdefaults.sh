#!/bin/bash

usage() {
        cat <<EOF
        Usage: $0 [options]
                -h print usage
                -t Cluster type ["Simple","Advanced"]
EOF
        exit 1
}

# ------------------------------------------------------------------
#          Read all inputs
# ------------------------------------------------------------------

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"



while getopts ":h:t:" o; do
        case "${o}" in
                h) usage && exit 0
                        ;;
                t) CLUSTERTYPE=${OPTARG}
                                ;;
                *)
                        usage
                        ;;
        esac
done

[ -z ${CLUSTERTYPE} ] && usage

cd /home/ec2-user/cloudera/setup-default

if [ ${CLUSTERTYPE} == "Simple" ]
then
    python setup-default.py --admin-username admin --admin-password admin ${CURR_DIR}/aws.simple.conf
else
    python setup-default.py --admin-username admin --admin-password admin ${CURR_DIR}/aws.reference.conf
fi



