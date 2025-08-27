package Provisioner::Recipe::fail2ban;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

# XXX this is pretty much tPSGI specific

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{fail2ban};
	}
	die "Unsupported packager";
}

sub template_files {
	my ($self) = @_;

	return (
        'fail2ban.jail.tt'    => 'jail.cfg',
		'fail2ban.filter.tt'  => 'filter.cfg',
	);
}


1;
