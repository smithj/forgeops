#!/usr/bin/env bash
# Import dynamic config.

DIR=`pwd`

IMPORT_SCRIPT=${IMPORT_SCRIPT:-"${DIR}/amster-scripts/import.amster"}

# Use 'openam' as the internal cluster dns name.
export SERVER_URL=${OPENAM_INSTANCE:-http://am:80}
export URI=${SERVER_URI:-/am}

export INSTANCE="${SERVER_URL}${URI}"

# Alive check
ALIVE="${INSTANCE}/isAlive.jsp"

wait_for_openam()
{
    # If we get lucky, AM will be up before the first curl command is issued.
    sleep 20
   response="000"

	while true
	do
	  echo "Trying ${ALIVE}"
		response=$(curl --write-out %{http_code} --silent --connect-timeout 30 --output /dev/null ${ALIVE} )

      echo "Got Response code ${response}"
      if [ ${response} = "200" ];
      then
         echo "AM web app is up and dynamic config can be imported"
         break
      fi

      echo "Will continue to wait..."
      sleep 5
   done

	# Sleep additional time in case DS is not quite up yet.
	echo "About to begin import"
}

echo "Waiting for AM server at ${ALIVE} "

wait_for_openam

# Execute Amster if the configuration is found.
if [  ${IMPORT_SCRIPT} ]; then
    if [ ! -r /var/run/secrets/amster/id_rsa ]; then
        echo "ERROR: Can not find the Amster private key"
        exit 1
    fi

    echo "Executing Amster to import dynamic config"
    # Need to be in the amster directory, otherwise Amster can't find its libraries.

    cd ${DIR}

    sh ./amster -q ${IMPORT_SCRIPT} -D AM_HOST="https://${FQDN}/am"

fi

echo "Import script finished"