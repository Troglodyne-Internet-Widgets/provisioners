package Provisioner::Recipe::auditd;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

# XXX this is pretty much tPSGI specific

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{auditd};
	}
	die "Unsupported packager";
}

sub template_files {
	my ($self) = @_;

	return (
        'auditd.global.tt' => 'global.rules',
		'auditd.domain.tt' => 'domain.rules',
	);
}

1;
