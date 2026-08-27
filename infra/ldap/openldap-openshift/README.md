OpenLDAP on OpenShift
=====================

Deploys the same OpenLDAP configuration as the podman-based `openldap` project, but on OpenShift/CRC.

Install
-------

```
./install.sh
```

This will:
- Create an `openldap` project
- Grant `anyuid` SCC (required by the osixia/openldap image)
- Generate TLS certificates using the shared CA scripts
- Create a Secret with the TLS certs and a ConfigMap with the bootstrap LDIF
- Deploy OpenLDAP with ports 389 (LDAP) and 636 (LDAPS)

Test
----

Test LDAP binding from a pod within the cluster (plaintext):
```
oc run ldap-test --rm -it --restart=Never --image=alpine -n openldap --command -- \
  sh -c "apk add --no-cache openldap-clients >/dev/null 2>&1 && \
  ldapsearch -x -H ldap://openldap.openldap.svc.cluster.local \
  -s base -b dc=redhat,dc=local -D 'cn=admin,dc=redhat,dc=local' -w admin"
```

Test LDAPS binding from a pod within the cluster (TLS):
```
oc run ldap-test-tls --rm -it --restart=Never --image=alpine -n openldap --command -- \
  sh -c "apk add --no-cache openldap-clients >/dev/null 2>&1 && \
  LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://openldap.openldap.svc.cluster.local \
  -s base -b dc=redhat,dc=local -D 'cn=admin,dc=redhat,dc=local' -w admin"
```

Or port-forward to test from your local machine:
```
oc port-forward svc/openldap -n openldap 389:389 636:636
ldapsearch -x -H ldaps://localhost -b dc=redhat,dc=local -D "cn=admin,dc=redhat,dc=local" -w admin
```

Note: set your `~/.ldaprc` to trust the generated CA for local ldaps:
```
TLS_CACERT /tmp/ca-data/certs/ca.pem
```

Cleanup
-------

```
oc delete project openldap
```
