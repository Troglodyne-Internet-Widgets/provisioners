# General recipe guidelines

## Sockets

* When possible with HTTP services, we are to use unix sockets rather than publically accessible ones, and proxy access via nginx to these.
    - When the above is not possible, a recipe MUST add a UFW application configuration to /etc/ufw/applications.d so that it will be allowed to communicate.

## SSL

* When a service requires SSL to function, both the letsencrypt and pdns targets' templates will need to be considered and most likely updated so that DNS DCV for its subdomains can function properly.

## Makefile target execution order is not guaranteed

* When you need to restart services or interact with things which may or may not be present and functioning at the time your recipe's target runs, be sure to queue it as a postrun task.

## Dependencies

* Don't require dependencies for things which are dependencies of recipes you depend on.  Instead, simply die during validate() if the recipe you depend on is not present in `$opts{modules}`.
    - Example: `die "This recipe requires the nginxproxy recipe to function" unless List::Util::any { $_ eq 'nginxproxy' } @{$opts{modules}};`
