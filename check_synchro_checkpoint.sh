#!/bin/sh
##################################################################
# Creation: alasta
# Last Modification:
# Script de check synchro CheckPoint
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

OID_SESSIONS="1.3.6.1.4.1.2620.1.1.25.3.0"

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
        echo "   -P : Member 1"
        echo "   -S : Member 2"
        echo "   -C : SNMP community v2"
        echo "   -N : Cluster Name"
        echo "   -w : Warning level"
        echo "   -c : Critical level"
        echo ""
}

# fonction snmpwalk
snmpwalk_function() {
        $BIN_SNMPWALK -v2c -c $1 $2 $3  | $BIN_AWK '{print $NF}'
}


# Gestion des Options
while getopts ":hDP:S:C:N:w:c:" option
do
        case $option in
                D)     set -x
                ;;
                P)      MEMBER1=$OPTARG
                ;;
                S)      MEMBER2=$OPTARG
                ;;
                C)      SNMP_COMMUNITY=$OPTARG
                ;;
                N)      CLUSTER_NAME=$OPTARG
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
# Nb de sessions du member 1
SESSIONS_M1=$(snmpwalk_function $SNMP_COMMUNITY $MEMBER1 $OID_SESSIONS)

# Nb de sessions du member 2
SESSIONS_M2=$(snmpwalk_function $SNMP_COMMUNITY $MEMBER2 $OID_SESSIONS)

#Recuperation du delta en valeur absolue
if [[ ! -z $SESSIONS_M1 && ! -z $SESSIONS_M2 ]]
then
        DELTA=$(($SESSIONS_M1-$SESSIONS_M2))
        DELTA=${DELTA#-}
else
        echo "Erreur lors de la recuperation du nombre de sessions !"
        exit $STATE_UNKNOWN
fi


#Gestion des differents seuils
#Gestion de l etat de sortie Nagios
if [  $DELTA -ge $C_CRITICAL   ]
        then
        echo "CRITICAL - Synchro FW $CLUSTER_NAME - delta de sessions : $DELTA<BR>MEMBER_1 : $SESSIONS_M1 - MEMBER_2 : $SESSIONS_M2"
        exit $STATE_CRITICAL
elif [[  $DELTA -lt $C_CRITICAL  &&  $DELTA -ge $C_WARN  ]]
        then
        echo "WARNING - Synchro FW $CLUSTER_NAME - delta de sessions : $DELTA<BR>MEMBER_1 : $SESSIONS_M1 - MEMBER_2 : $SESSIONS_M2"
        exit $STATE_WARNING
elif [[ $DELTA -lt $C_WARN  &&  $DELTA -ge 0 ]]
        then
        echo "OK - Synchro FW $CLUSTER_NAME - delta de sessions : $DELTA<BR>MEMBER_1 : $SESSIONS_M1 - MEMBER_2 : $SESSIONS_M2"
        exit $STATE_OK
else
        echo "UNKNOWN - Synchro FW $CLUSTER_NAME - delta de sessions : $DELTA<BR>MEMBER_1 : $SESSIONS_M1 - MEMBER_2 : $SESSIONS_M2"
        exit $STATE_UNKNOWN
fi


###### SCRIPT END
