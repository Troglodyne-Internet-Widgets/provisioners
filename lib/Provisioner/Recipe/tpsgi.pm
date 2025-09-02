package Provisioner::Recipe::tpsgi;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{git};
	}
	die "Unsupported packager";
}

1;
