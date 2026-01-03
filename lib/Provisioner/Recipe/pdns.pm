package Provisioner::Recipe::pdns;

use strict;
use warnings;

use parent qw{Provisioner::Recipe};

=head1 Provisioner::Recipe::pdns

=head2 SYNOPSIS

    somedomain:
        pdns:
            extra_records: /opt/domains/dns/sub.somedomain/zonefile_fragment

=head2 DESCRIPTION

Set up powerdns resolver, and install a sensible set of records for your chosen recipe(s).

See templates/files/pdns.zone.tt for what is set up.

The idea here is to allow simple DNS delegation of subdomains to provisioned machines.

Uses the sqlite backend.

Appends arbitrary records specified as extra_records.

=cut

use Text::Xslate;
use Net::IP;
use File::Slurper;

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        return qw{pdns-server pdns-tools pdns-backend-sqlite3 sqlite3 libconfig-simple-perl libnet-dns-perl libjson-perl python3-requests-unixsocket};
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    my $key = $opts{api_key};
    die "Must define api_key in [pdns] section of recipes.yaml" unless $key;

    my $extras = $opts{extra_records};
    die "extra_records defined in [pdns] must be a readable text file" if $extras && !-f $extras;
    $opts{extra_records} = File::Slurper::read_text($extras) if $extras;

    $opts{serial} = time;
    return %opts;
}

sub template_files {
    my ($self) = @_;

    return (
        'pdns.zone.tt'                                 => 'zonefile',
        'pdns.domain.tt'                               => 'pdns-domain.conf',
        'pdns.rsyslog.tt'                              => '10-powerdns.conf',
        'pdns.api.tt'                                  => 'pdns-api.conf',
        'pdns.synczones.tt'                            => 'synczones.conf',
        'pdns.lexicon.tt'                              => 'lexicon-pdns.sh',
        'patches/lexicon-pdns-af-unix.patch'           => 'lexicon-pdns-af-unix.patch',
        'patches/lexicon-arbitrary-record-types.patch' => 'lexicon-arbitrary-record-types.patch'
    );
}

sub formatters {
    my ($class) = shift;
    return (
        reverse_ip => Text::Xslate::html_builder(
            sub {
                my $ip = shift;
                return Net::IP->new($ip)->reverse_ip();
            }
        ),
        email_for_dns => Text::Xslate::html_builder(
            sub {
                my $email = shift;
                $email =~ tr/@/./;
                return $email;
            }
        ),
    );
}

1;
