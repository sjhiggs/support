LDAP
====

sample usage
------------


Create:
```
./run.sh
```

# Note: modify your ~/.ldaprc; the  ~/.ldaprc file points to the CA so ldapsearch works. An example .ldaprc is in this project.

Test:
```
ldapsearch  -x -H ldaps://ldap.local -b dc=redhat,dc=local -D "cn=admin,dc=redhat,dc=local" -w admin
```
