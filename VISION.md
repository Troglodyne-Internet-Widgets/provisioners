# Vision: or, why the hell do we need another 'nomad' or 'kubernetes'

These are big self-contained projects that do way too much.
They do not leverage the existing strengths of operating systems
to minimize the amount of code they need to write.

To make matters worse, because they do so much, their configuration format
and means to extend them are *more* complicated than "lol just make RPMs".

While there is an argument to be made for arrogating all under the purview
of the computer to your program (in an environment of uncertainty, vertical
integration is a winning strategy), this simply does not hold in the least
on modern linux systems.

Things like package managers and init systems have been around a long time,
are stable, *infinitely* better documented, well tested and most importantly
it's one less thing you have to do.

In many ways our approach with trog-provisioner leans heavily on this.
Cloud-init, Make and atd are nearly all of the 'secret sauce' that makes
this all work. (as an aside, cloud-init is reimplementing Make with a recipe bag-on-the-side,
e.g. much of what I'm doing here, but in python! why do we keep doing this to ourselves)

So, in that spirit, the long term goal of this project is to leverage existing
OS facilities to build the kind of auto-scaling control plane you want.

If it doesn't make me think "pootie done did it again" (search it on youtube) RE the simplicity
it's probably not good.

## What needs to change

1. We need to eliminate terraform usage in trog-provisioner entirely in favor of libvirt
XMLs & calls; that the terraform provider is not a meaningful reduction of complexity
when compared to XML is quite the indictment.  It's pretty much the same story with
all the other abstractions that make this work with podman/docker/snap/flatpack et al.
When the abstraction is more complex than doing the thing directly, you should instead
build a simple interface that has pluggability.  That's the whole approach of Provisioner::Recipe!

2. Right now we lean on make failing on any bad rc as our test/verification, optionally
having additional testing includable by recipes.  We need a strong policy and structure
that allows us to never have to do silly things like /bin/true at the end of lines that
undermines this.  Ultimately the only thing that will ensure such idempotency is a robust
test suite, which means we'll dogfood our own control plane here.

3. We can radically simplify the provision process via leaning on RPM/Deb.  We are already
building makefiles and setting up the HV as a deb mirror, may as well "make it a fish" and
just make the *entire* deploy process save data schlepping managed by clown-init's
"install-packages" recipe.

4. We need to control individual VMs via systemctl files.
Reload rebuilds the VM, while start/stop does what you expect.
Implement healthchecks w/timers.

5. The actual control plane needs to be something like a preforking PSGI server
but that has the ability to scale up/down workers via the min\_spare\_servers mechanism
in Net::Server::PreFork.  Each 'request' does something with a VM, be it forwarding a req
or managing the VM itself.  These requests 'lock' the VM from being used by other workers
IFF it's a VM state change or said VM fails a health check.
After a grace period (or it has no known active jobs, but is still failing health)
we either unlock it for use or respawn it.

6. Control plane has to coexist with static infrastructure.  Not everything can or should autoscale.
It needs to know what guests are under it's control, and have strict quotas.

7. From there any frontend management interface is largely a recipes.d config builder,
and intermediator with the control plane.
It needs to treat everything it needs done as a queue of jobs that it polls for status,
optionally specifying what can be done in parallell at each step.
at / atq and each job being a makefile and having its own log largely handles this, but
perl w/ log::dispatch::db may make more sense.
