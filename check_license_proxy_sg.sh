#!/bin/sh
##################################################################
# Creation: 20180919 - Alasta  
# Last Modification:
# Description : Check License validity
##################################################################

###### VAR BEGIN
# Nagios State
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

BIN_AWK=$(which awk)
BIN_CURL="$(which curl) -sk "
BIN_DATE=$(which date)
BIN_GREP=$(which grep)


#Default values
STATE=${STATE_UNKNOWN}
PROXY_URI_LICENSE="/ContentFilter/Blue%20Coat/log"

#Code to verify option is set
CODEV=0

###### VAR END

###### SCRIPT BEGIN
# Help function
function f_help {
        echo ""
        echo "Usage : `basename $0` [-h] [-D] -H <host> -u <username GUI> -p <password> -w <days before warn expiration> -c <days before crit expiration> "
        echo ""
        echo "   -c : Critical alarm : number of days before expiration"
        echo "   -h : Help"
        echo "   -H : Proxy host"
        echo "   -D : Debug script"
        echo "   -u : Username of GUI"
        echo "   -p : Password of username"
        echo "   -w : Warning alarm : number of days before expiration"
        echo ""
}



# Gestion des Options
while getopts ":hDp:u:w:c:H:" option
do
    case $option in
        D)	set -x
    ;;
	u)	PROXY_USER=$OPTARG
		CODEV=$((CODEV+1))
	;;
	p)	PROXY_PASS=$OPTARG
		CODEV=$((CODEV+10))
	;;
    w)	C_WARN=$OPTARG
		CODEV=$((CODEV+100))
    ;;
    c)  C_CRITICAL=$OPTARG
		CODEV=$((CODEV+1000))
    ;;
	H)	C_HOST=$OPTARG
		CODEV=$((CODEV+10000))
	;;
    h)  f_help
        exit 1
    ;;
    \?) echo "*** Error ***"
        exit $STATE_UNKNOWN
    ;;
    :)  echo "*** Option \"$OPTARG\" not set ***"
        exit 3
    ;;
    *)  echo "*** Option \"$OPTARG\" unknown ***"
        exit 3
    ;;
    esac
done



#Verify if all option is set
if [ ${CODEV} -ne 11111 ]
then
	echo "All option is not set."
	exit $STATE_UNKNOWN
fi


#Verify if warning > critical
if [ ${C_WARN} -le ${C_CRITICAL} ]
then
	echo "The warning option should be superior to critical option."
	exit $STATE_UNKNOWN
fi


#Get End of validity (EOV) & EOV Timestamp (EOV_TS)
#DATE_EOV=$(${BIN_CURL} "https://${C_HOST}:8082${PROXY_URI_LICENSE}" | ${BIN_GREP} 'Licensed Until' | ${BIN_AWK} '{print $4,$5,$6}')
DATE_EOV=$(${BIN_CURL} "https://${PROXY_USER}:${PROXY_PASS}@${C_HOST}:8082${PROXY_URI_LICENSE}" | ${BIN_GREP} 'Licensed Until' | ${BIN_AWK} '{print $4,$5,$6}')
DATE_EOV_TS=$(${BIN_DATE} '+%s' -d "${DATE_EOV}")

#Get current date 
DATE_CURRENT_TS=$(${BIN_DATE} '+%s')

#Diff between 2 dates
DIFF_DATE_TS=$(((${DATE_EOV_TS}-${DATE_CURRENT_TS})/86400))


#Manage status of Nagios
if [  ${DIFF_DATE_TS} -lt 0   ]
  then
	echo "UNKNOWN - Diff value = ${DIFF_DATE_TS}"
  exit $STATE_UNKNOWN
elif [[  ${DIFF_DATE_TS} -le ${C_CRITICAL}  ]]
	then
	echo "CRITICAL - Number of days before expiration (${DIFF_DATE_TS}) is inferior to critical value : ${C_CRITICAL}"
	exit $STATE_CRITICAL
elif [[  ${DIFF_DATE_TS} -le ${C_WARN}  ]]
  then
  echo "WARNING - Number of days before expiration (${DIFF_DATE_TS}) is inferior to warning value : ${C_WARN}"
  exit $STATE_WARNING
elif [[ ${DIFF_DATE_TS} -gt ${C_WARN} ]]
  then
  echo "OK - Number of days before expiration (${DIFF_DATE_TS}) is superior to warning value : ${C_WARN}"
  exit $STATE_OK
else
  echo "UNKNOWN - Diff value = ${DIFF_DATE_TS}, Warning days = ${C_WARN}, Critical days = ${C_CRITICAL}"
  exit $STATE_UNKNOWN
fi


###### SCRIPT END
