# AMQ Broker on OpenShift - Examples

Each subdirectory contains a self-contained scenario for deploying AMQ Broker on OpenShift.

| Scenario | Description |
|---|---|
| [broker-custom-bootstrap](broker-custom-bootstrap/) | Custom bootstrap.xml with HTTP request logging via ConfigMap |
| [broker-tls-client-auth](broker-tls-client-auth/) | Two-way (mutual) TLS with client certificate authentication |
| [custom-postconfig](custom-postconfig/) | Custom post-configuration script injected via init container |
| [logging](logging/) | Override default Log4J2 logging configuration via secret |
| [storage](storage/) | LVM Storage (LVMS) setup for persistent broker storage |

## Shared Resources

The [shared/](shared/) directory contains files common across scenarios:

- **Operator subscriptions** — `shared/yaml/subscription/` (7.12.x and 7.13.x channels)
- **Utilities** — `shared/scripts/check-olm.sh` (check available AMQ Broker operator versions for a given OCP release)

## Miscellaneous

The [misc/](misc/) directory contains files not tied to a specific documented scenario (heap dump artifacts, experimental broker configs, etc.).
