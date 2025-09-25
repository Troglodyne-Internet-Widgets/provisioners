package Provisioner::Recipe::letsencrypt;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::letsencrypt

=head2 SYNOPSIS

    somedomain:
        letsencrypt:

=head2 DESCRIPTION

Configures lexicon to be able to update TXT records for your domain with your registrar so you can do DNS DCV.

Configures dehydrated to use lexicon to do DNS DCV w/ lexicon.

Sets up convenience scripts in /opt/lexicon per domain to run lexicon manually:

    /opt/lexicon/my.domain.name list TXT

=cut

sub deps {
	my ($self) = @_;
	if ($self->{target_packager} eq 'deb') {
		return qw{certbot lexicon dehydrated};
	}
	die "Unsupported packager";
}

sub template_files {
	my ($self) = @_;

	return (
		'ssl.get_cert.tt'          => 'get_cert',
        'ssl.dehydrated.conf.tt'   => 'dehydrated.conf',
        'ssl.dehydrated.domain.tt' => 'dehydrated.domain',
        'ssl.dehydrated.hook.tt'   => 'domain.hook',
        'ssl.domains.tt'           => 'domains.txt',
        'ssl.lexicon.sh.tt'        => 'lexicon.sh',
	);
}

1;
