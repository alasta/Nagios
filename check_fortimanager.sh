#!/bin/sh
##################################################################
# Creation: alasta
# Last Modification:
# Script de check CPU/MEM/DISK FortiManager/FortiAnalyzer
##################################################################

###### VAR BEGIN
# Nagios State
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4


BIN_AWK=$(which awk)
BIN_SNMPWALK=$(which snmpwalk)

OID_CPU="1.3.6.1.4.1.12356.103.2.1.1"
OID_MEM_USAGE="1.3.6.1.4.1.12356.103.2.1.2.0"
OID_MEM_TOTAL="1.3.6.1.4.1.12356.103.2.1.3.0"
OID_DISK_USAGE="1.3.6.1.4.1.12356.103.2.1.4.0"
OID_DISK_TOTAL="1.3.6.1.4.1.12356.103.2.1.5.0"



#Default values
STATE=${STATE_UNKNOWN}



###### VAR END

###### SCRIPT BEGIN
# Help function
function f_help {
        echo ""
        echo "Usage : `basename $0` [-h] [-D] -H <host> -C <snmp_community_v2> [-T <check_type>] -w <warn level> -c <crit level> "
        echo ""
        echo "   -h : Help"
        echo "   -D : Debug script"
        echo "   -H : host to checki - default 127.0.0.1"
        echo "   -C : SNMP community v2 - default public"
        echo "   -T : Type of check (CPU, MEM, DISK) -default CPU"
        echo "   -w : Warning level - default 60"
        echo "   -c : Critical level - default 90"
        echo ""
}

# fonction snmpwalk
snmpwalk_function() {
        $BIN_SNMPWALK -v2c -c $1 $2 $3  | $BIN_AWK '{print $NF}'
}


# Gestion des Options
while getopts ":hDT:H:C:w:c:" option
do
        case $option in
                D)     set -x
                ;;
                H)      C_HOST=$OPTARG
                ;;
                C)      SNMP_COMMUNITY=$OPTARG
                ;;
                T)      C_CHECK_TYPE=$OPTARG
                        #Gestion de la valeur de l argument, on quit si ce n est pas une valeur desiree
                        ${BASH_VERSION+shopt -s extglob}
                        if [[ $C_CHECK_TYPE != @(CPU|MEM|DISK) ]]
                        then
                                exit 3
                        fi
                ;;
                w)      C_WARN=$OPTARG
                ;;
                c)      C_CRITICAL=$OPTARG
                ;;
                h)      f_help
                        exit 1
                ;;
                \?)     echo "*** Error ***"
                        exit $STATE_UNKNOWN
                ;;
                :)      echo "*** Option \"$OPTARG\" not set ***"
                        exit 3
                ;;
                *)      echo "*** Option \"$OPTARG\" unknown ***"
                        exit 3
                ;;
        esac
done

#Gestion des requetes SNMP
# Default type = CPU
case $C_CHECK_TYPE in
        CPU)
                C_VALUE=$(snmpwalk_function ${SNMP_COMMUNITY:-"public"} ${C_HOST:-"127.0.0.1"} $OID_CPU)
        ;;
        MEM)
                C_VALUE_TOTAL=$(snmpwalk_function ${SNMP_COMMUNITY:-"public"} ${C_HOST:-"127.0.0.1"} $OID_MEM_TOTAL)
                C_VALUE_USAGE=$(snmpwalk_function ${SNMP_COMMUNITY:-"public"} ${C_HOST:-"127.0.0.1"} $OID_MEM_USAGE)
                C_VALUE=$((($C_VALUE_USAGE*100)/$C_VALUE_TOTAL))
        ;;
        DISK)
                C_VALUE_TOTAL=$(snmpwalk_function ${SNMP_COMMUNITY:-"public"} ${C_HOST:-"127.0.0.1"} $OID_DISK_TOTAL)
                C_VALUE_USAGE=$(snmpwalk_function ${SNMP_COMMUNITY:-"public"} ${C_HOST:-"127.0.0.1"} $OID_DISK_USAGE)
                C_VALUE=$((($C_VALUE_USAGE*100)/$C_VALUE_TOTAL))
        ;;
esac


#Gestion de l etat de sortie Nagios
if [ ! -z $C_VALUE ]
        then

        if [[  $C_VALUE -le 100  &&  $C_VALUE -ge $C_CRITICAL   ]]
                then
                echo "CRITICAL - $C_CHECK_TYPE : $C_VALUE"
                exit $STATE_CRITICAL
        elif [[  $C_VALUE -lt $C_CRITICAL  &&  $C_VALUE -ge $C_WARN  ]]
                then
                echo "WARNING - $C_CHECK_TYPE : $C_VALUE"
                exit $STATE_WARNING
        elif [[ $C_VALUE -lt $C_WARN  &&  $C_VALUE -ge 0 ]]
                then
                echo "OK - $C_CHECK_TYPE : $C_VALUE"
                exit $STATE_OK
        else
                echo "UNKNOWN - $C_CHECK_TYPE : $C_VALUE"
                exit $STATE_UNKNOWN
        fi
else
        echo "UNKNOWN - Valeur de $C_CHECK_TYPE vide !"
        exit $STATE_UNKNOWN
fi

###### SCRIPT END
