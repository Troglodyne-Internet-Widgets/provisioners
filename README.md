# Provisioners

Configuration files to provision troglodyne VMs

Also a framework for making new provision confs, with recipes etc

```
bin/new_config test.somedomain
```

## ipmap.cfg

Relies on an ipmap.cfg to grab static IPs for VMs, and other relevant information.

Example:

```
[global]
tld=test.test
basedir=/opt/provisioners
admin_user=test
admin_key=gh:test
admin_gecos=Testy Testerson
admin_email=test@test.test
[ips]
tickle=192.168.1.1
hug=...
```

Suppose we execute `bin/new_config tickle`.

The above would produce a VM config for tickle.test.test at 192.168.1.1, and place it in /opt/provisioners/tickle.test.test.

It would populate the default users.yaml to make the 'test' user, give them admin rights and ssh-import-id their github key.

TODO: support raw keys.

## recipes.yaml

These will have sections describing user-configuration for the various recipes:

```
---
tickle:
    perl:
        user: test
    nginx:
        socket: /var/run/testApp.sock
hug:
...
```

These are powered by subclasses of `Provisioner::Recipe`, say `Provisioner::Recipe::perl`.
All these subclasses MUST be lowercase on their least component.
This is so we can have special uppercase targets in the makefile you can't overwrite.

These modules render the appropriately named template in templates, e.g. `templates/perl.tt`.
These are makefile fragments with no leading tab (we add this for you).

All recipe fragments must be re-entrant so we can run `make -j $whatever`.
This means you have to provide a list of deps up-front which can be run before everything else.

## scripts/

To simplify matters, we SCP over the scripts/ directory, which you should shove any complicated scripting into.
Be that used for recipes, or what have you.
