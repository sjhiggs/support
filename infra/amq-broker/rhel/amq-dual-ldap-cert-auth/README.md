# Prereq

Run ldap server (see ldap infra project)

# Install

../scripts/create-certs.sh 
../scripts/install.sh 

# Run
/tmp/amq-dual-ldap-cert-auth-instance/bin/artemis run

# Test

## client cert auth with python client

pip install python-qpid-proton
python src/artemis_amqp_mtls.py 

## ldap auth with cli

/tmp/amq-dual-ldap-cert-auth-instance/bin/artemis queue stat --user myuser --password mypassword --url "tcp://localhost:61617?sslEnabled=true;trustStorePath=/tmp/myapp-certs/truststore.p12;trustStorePassword=foobar;;trustStoreType=PKCS12"

