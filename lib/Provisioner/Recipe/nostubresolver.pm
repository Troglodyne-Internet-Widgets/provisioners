package Provisioner::Recipe::nostubresolver;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::nostubresolver

=head2 SYNOPSIS

    somedomain:
        nostubresolver:

=head2 DESCRIPTION

Remove systemd's "stub resolver".

Particularly useful if you plan on installing an actual DNS server, such as pdns.

Also useful in network environments where its default behavior is unhelpful.

=cut

sub template_files {
	my ($self) = @_;

	return (
		'nostubresolver.tt' => '10-disable-stub-resolver.conf',
	);
}

1;
