package Provisioner::Recipe::cron;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{rkhunter sysstat cronie};
	}
	die "Unsupported packager";
}

sub validate {
    my ($self, %vars) = @_;

    if ( $vars{user_scripts} ) {
        die "user_scripts must be ARRAY" unless ref $vars{user_scripts} eq 'ARRAY';
        foreach my $cron (@{$vars{user_scripts}}) {
            die "Each user script must be a HASH" unless ref $cron eq 'HASH';
            die "user_scripts must have an interval & cmd" unless $cron->{interval} && $cron->{cmd}
        }
    }

    return %vars;
}

sub template_files {
	my ($self) = @_;

	return (
        'cron.root.tt'  => 'root.crontab',
		'cron.user.tt'  => 'user.crontab',
	);
}


1;
