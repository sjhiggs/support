# Description


# Initialize 

Run the init script and edit `./scripts/env` to customize for environment.

~~~
./scripts/init.sh - initialize directories
~~~

# Create a CA and issuing CA:

~~~
./scripts/ca.sh - create the root CA
./scripts/ca-issuing.sh - create the issuing CA
~~~

# Create server/client certs

~~~
./scripts/cert-server.sh ...
./scripts/cert-client.sh ...
~~~


# Clean up

~~~
./scripts/clean.sh - delete all ca's, certs, keys, etc.
~~~
