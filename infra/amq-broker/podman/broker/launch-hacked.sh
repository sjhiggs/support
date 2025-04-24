#!/bin/bash

set -e

## Let's set up a hook so that we can do whatever we want for configuration
## The hook "configure_custom_hook.sh" will first call the default configure_custom_config.sh and then 
## execute further customizations

echo  "USING A CUSTOM ENTRYPOINT! NOT SUPPORTED!!!"
sed -i 's/configure_custom_config.sh/configure_custom_hook.sh/' /opt/amq/bin/launch.sh

exec /opt/amq/bin/launch.sh "$@"



