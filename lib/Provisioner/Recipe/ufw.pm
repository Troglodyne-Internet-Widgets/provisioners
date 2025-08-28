package Provisioner::Recipe::ufw;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

use File::Path qw{rmtree};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{ufw};
	}
	die "Unsupported packager";
}

sub validate {
    my ($self, %vars) = @_;

    if ( $vars{port_forwards} ) {
        die "port_forwards must be ARRAY" unless ref $vars{port_forwards} eq 'ARRAY';
        foreach my $cron (@{$vars{port_forwards}}) {
            die "Each port forward must be a HASH" unless ref $cron eq 'HASH';
            die "port forwards must have a from & to" unless $cron->{from} && $cron->{to}
        }
    }

    return %vars;
}

my %template2rule = (
    'ufw.pdns.tt' => 'ufw/pdns',
);

sub template_files {
	my ($self, @recipes) = @_;

    my $dir = "$self->{output_dir}/ufw";

    rmtree $dir; 
    mkdir  $dir;
    return () unless @recipes;

    # Only render things we actually need
    my %ret;
    foreach my $r (@recipes) {
        my $key = "ufw.$r.tt";
        $ret{$key} = $template2rule{$key} if exists $template2rule{$key};
    }
    return %ret;
}

1;
