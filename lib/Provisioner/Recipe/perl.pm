package Provisioner::Recipe::perl;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{perlbrew libcarp-always-perl};
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;
	my $user = $opts{user};
	die "Must set user in [perl] section of recipes.cfg" unless $user;

	return %opts;
}

1;
