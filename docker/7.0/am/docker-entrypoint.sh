#!/bin/bash
# Copyright ForgeRock AS. All Rights Reserved
#

set -x

. $FORGEROCK_HOME/debug.sh
. $FORGEROCK_HOME/profiling.sh

CATALINA_OPTS="$CATALINA_OPTS $CATALINA_USER_OPTS $JFR_OPTS"

# TODO check we have secrets directory mounted
# TODO remove -encrypted attributes

copy_secrets() {
    mkdir -p $AM_HOME/var/audit
    SDIR=$AM_HOME/security/secrets/default
    KDIR=$AM_HOME/security/keystores
    mkdir -p $SDIR
    mkdir -p $KDIR
    echo "Copying bootstrap files for legacy AMKeyProvider"
    rm -f $SDIR/.storepass $SDIR/.keypass
    cp $AM_KEYSTORE_PATH/.storepass $SDIR
    cp $AM_KEYSTORE_PATH/.keypass $SDIR

    cp $AM_KEYSTORE_PATH/.storepass $KDIR
    cp $AM_KEYSTORE_PATH/.keypass $KDIR
    cp $AM_KEYSTORE_PATH/keystore.jceks $KDIR

    cp $SDIR/.storepass $SDIR/storepass
    cp $SDIR/.keypass $SDIR/keypass
}

generateRandomSecret() {
    cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 32 | head -n 1
}

am-crypto() {
    java -jar /home/forgerock/crypto-tool.jar $@
}

export AM_KEYSTORE_PATH=${AM_KEYSTORE_PATH:-/var/run/secrets/openam}

copy_secrets

export AM_SERVER_PROTOCOL=${AM_SERVER_PROTOCOL:-"https"}
export AM_SERVER_FQDN=${AM_SERVER_FQDN:-"default.iam.example.com"}
export AM_SERVER_PORT=${AM_SERVER_PORT:-80}

export AM_ENCRYPTION_KEY=${AM_ENCRYPTION_KEY:-$(generateRandomSecret)}

AM_PASSWORDS_DSAMEUSER_CLEAR=$(generateRandomSecret)
export AM_PASSWORDS_DSAMEUSER_HASHED_ENCRYPTED=$(echo $AM_PASSWORDS_DSAMEUSER_CLEAR | am-crypto hash encrypt des)
export AM_PASSWORDS_DSAMEUSER_ENCRYPTED=$(echo $AM_PASSWORDS_DSAMEUSER_CLEAR | am-crypto encrypt des)


AM_PASSWORDS_ANONYMOUS_CLEAR=${AM_PASSWORDS_ANONYMOUS_CLEAR:-$(generateRandomSecret)}
AM_PASSWORDS_ANONYMOUS_HASHED=${AM_PASSWORDS_ANONYMOUS_HASHED:-$(echo $AM_PASSWORDS_ANONYMOUS_CLEAR | am-crypto hash)}
export AM_PASSWORDS_ANONYMOUS_HASHED_ENCRYPTED=$(echo $AM_PASSWORDS_ANONYMOUS_HASHED | am-crypto encrypt des)

AM_PASSWORDS_AMADMIN_HASHED=${AM_PASSWORDS_AMADMIN_HASHED:-$(echo $AM_PASSWORDS_AMADMIN_CLEAR | am-crypto hash)}
unset AM_PASSWORDS_AMADMIN_CLEAR
export AM_PASSWORDS_AMADMIN_HASHED_ENCRYPTED=$(echo $AM_PASSWORDS_AMADMIN_HASHED | am-crypto encrypt des)

export AM_KEYSTORE_DEFAULT_PASSWORD=$(cat $AM_HOME/security/secrets/default/.storepass)
export AM_KEYSTORE_DEFAULT_ENTRY_PASSWORD=$(cat $AM_HOME/security/secrets/default/.keypass)

export AM_STORES_USER_USERNAME="${AM_STORES_USER_USERNAME:-"uid=am-identity-bind-account,ou=admins,ou=identities"}"
export AM_STORES_USER_PASSWORD="${AM_STORES_USER_PASSWORD:-"password"}"
export AM_STORES_USER_SERVERS="${AM_STORES_USER_SERVERS:-"ds-idrepo-0.ds-idrepo:1389"}"

export AM_STORES_CTS_USERNAME="${AM_STORES_CTS_USERNAME:-"uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens"}"
export AM_STORES_CTS_PASSWORD="${AM_STORES_CTS_PASSWORD:-"$AM_STORES_USER_PASSWORD"}"
export AM_STORES_CTS_SERVERS="${AM_STORES_CTS_SERVERS:-"$AM_STORES_USER_SERVERS"}"

export AM_STORES_APPLICATION_USERNAME="${AM_STORES_APPLICATION_USERNAME:-"uid=am-config,ou=admins,ou=am-config"}"
export AM_STORES_APPLICATION_PASSWORD="${AM_STORES_APPLICATION_PASSWORD:-"$AM_STORES_USER_PASSWORD"}"
export AM_STORES_APPLICATION_SERVERS="${AM_STORES_APPLICATION_SERVERS:-"$AM_STORES_USER_SERVERS"}"

export AM_STORES_POLICY_USERNAME="${AM_STORES_POLICY_USERNAME:-"uid=am-config,ou=admins,ou=am-config"}"
export AM_STORES_POLICY_PASSWORD="${AM_STORES_POLICY_PASSWORD:-"$AM_STORES_APPLICATION_PASSWORD"}"
export AM_STORES_POLICY_SERVERS="${AM_STORES_POLICY_SERVERS:-"$AM_STORES_APPLICATION_SERVERS"}"

export AM_STORES_UMA_USERNAME="${AM_STORES_UMA_USERNAME:-"uid=am-config,ou=admins,ou=am-config"}"
export AM_STORES_UMA_PASSWORD="${AM_STORES_UMA_PASSWORD:-"$AM_STORES_APPLICATION_PASSWORD"}"
export AM_STORES_UMA_SERVERS="${AM_STORES_UMA_SERVERS:-"$AM_STORES_APPLICATION_SERVERS"}"

export AM_AUTHENTICATION_SHARED_SECRET="${AM_AUTHENTICATION_SHARED_SECRET:-$(generateRandomSecret | base64)}"
export AM_SESSION_STATELESS_SIGNING_KEY="${AM_SESSION_STATELESS_SIGNING_KEY:-$(generateRandomSecret)}"
export AM_SESSION_STATELESS_ENCRYPTION_KEY="${AM_SESSION_STATELESS_ENCRYPTION_KEY:-$(generateRandomSecret)}"

export AM_OIDC_CLIENT_SUBJECT_IDENTIFIER_HASH_SALT="${AM_OIDC_CLIENT_SUBJECT_IDENTIFIER_HASH_SALT:-$(generateRandomSecret)}"

export AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY="${AM_SELFSERVICE_LEGACY_CONFIRMATION_EMAIL_LINK_SIGNING_KEY:-$(generateRandomSecret | base64)}"

# For debugging purposes
echo "****** Environment *************: "
env | sort

# sleep 40


echo "Starting tomcat with opts: ${CATALINA_OPTS}"
exec $CATALINA_HOME/bin/catalina.sh $JPDA_DEBUG run

