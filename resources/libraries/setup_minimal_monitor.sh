#!/bin/bash
# Script with getopt argument parsing

###############################################################################
# PARÁMETROS CON GETOPT
###############################################################################

OPTS=$(getopt -o "" \
    --long ip:,name:,type:,parent_id: \
    -n "$0" -- "$@")

if [ $? != 0 ]; then
    echo "Error parsing options" >&2
    exit 1
fi

eval set -- "$OPTS"

# Valores por defecto
SENSOR_IP="10.1.32.158"
SENSOR_NAME="Device"
SENSOR_TYPE=12
SENSOR_PARENT_ID=0

while true; do
    case "$1" in
        --ip) SENSOR_IP="$2"; shift 2 ;;
        --name) SENSOR_NAME="$2"; shift 2 ;;
        --type) SENSOR_TYPE="$2"; shift 2 ;;
        --parent_id) SENSOR_PARENT_ID="$2"; shift 2 ;;
        --) shift; break ;;
        *) break ;;
    esac
done

###############################################################################
# INICIO DEL SCRIPT REAL
###############################################################################

/usr/lib/redborder/bin/rb_set_modules ips:0 flow:1 wireless:0 vault:0 scanner:0 correlation_engine_rule:0 malware:0 location:0

/usr/lib/redborder/bin/rbcli service disable f2k
/usr/lib/redborder/bin/rbcli service disable redborder-mem2incident
/usr/lib/redborder/bin/rbcli service disable postfix
/usr/lib/redborder/bin/rbcli service disable redborder-dswatcher
/usr/lib/redborder/bin/rbcli service disable sfacctd

#TO delayed_job remove default
/usr/bin/chef-client

# RVM gemset
source /etc/profile.d/rvm.sh

###############################################################################
# RAILS RUNNER
###############################################################################

/usr/lib/rvm/gems/ruby-2.7.5@web/bin/rails runner "\
allowed_types = [1, 12]; \
Sensor.where.not(type: allowed_types).destroy_all; \
sensor = Sensor.find_by(name: '$SENSOR_NAME'); \
if sensor.nil?; \
  sensor = Sensor.new(name: '$SENSOR_NAME', type: $SENSOR_TYPE, parent_id = $SENSOR_PARENT_ID, ip: '$SENSOR_IP'); \
end; \
"

# TODO: Auto associate monitor categories

echo "✔ Script completado."
