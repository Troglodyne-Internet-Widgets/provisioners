package Provisioner::Recipe::imagemagick;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{ghostscript libjpeg-dev libpng-dev libtiff-dev liblzma-dev libxml2-dev libdjvulibre-dev libfreetype-dev libperl-dev};
	}
	die "Unsupported packager";
}

sub validate {
	my ($self, %opts) = @_;

    my $ver = $opts{version};
    die "Must define version in [imagemagick] section of recipes.yaml" unless $ver;

	return %opts;
}

1;
