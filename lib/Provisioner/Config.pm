package Provisioner::Config;

use strict;
use warnings FATAL => 'all';

use Cwd ();
use File::Basename qw{dirname};
use File::Find ();
use File::Slurper ();
use Hash::Merge ();
use YAML ();

Hash::Merge::set_behavior('STORAGE_PRECEDENT');

=head1 Provisioner::Config

=head2 SYNOPSIS

    use Provisioner::Config;

    my $cfg = Provisioner::Config->new(
        recipes_file => 'recipes.yaml',   # default
        ipmap_file   => 'ipmap.cfg',      # default; optional when _global in recipes.yaml
    );

    my $rc  = $cfg->recipe_config();   # merged recipes.yaml + recipes.d/ + recipes.yaml.d/
    my $map = $cfg->ipmap();           # hashref: global_conf, ip_conf, alias_conf, ns_conf, addons

=head2 DESCRIPTION

Centralises configuration loading for provisioner tools.

Recipe config is loaded from C<recipes_file> then merged with any C<*.yaml> files
found in C<recipes.d/> and C<recipes.yaml.d/> relative to the recipes file's
directory.  C<_base> and C<_shared> keys are stripped from the drop-in files so
they cannot accidentally shadow global config.

IP-map config is loaded from C<ipmap_file> when present.  When that file does not
exist the C<_base._global> section of C<recipes_file> is used as a fallback,
expecting the same keys plus C<ips>, C<aliases>, C<nameservers>, and C<addons>
sub-keys.

=cut

=head2 METHODS

=head3 $class->new(%opts)

Accepted options:

=over 4

=item recipes_file

Path to the primary recipes YAML file.  Defaults to C<recipes.yaml>.

=item ipmap_file

Path to the INI-format IP-map file.  Defaults to C<ipmap.cfg>.
Pass C<undef> to skip ipmap.cfg lookup entirely and always use the YAML fallback.

=back

=cut

sub new {
    my ( $class, %opts ) = @_;

    my $recipes_file = $opts{recipes_file} // 'recipes.yaml';
    my $abs_recipes  = Cwd::abs_path($recipes_file) // $recipes_file;
    my $base_dir     = -f $abs_recipes ? dirname($abs_recipes) : Cwd::getcwd();

    return bless {
        recipes_file => $recipes_file,
        ipmap_file   => exists $opts{ipmap_file} ? $opts{ipmap_file} : 'ipmap.cfg',
        base_dir     => $base_dir,
    }, $class;
}

=head3 $cfg->recipe_config()

Load and return the merged recipe configuration hashref.  Result is memoised.

Drop-in YAML files in C<recipes.d/> and C<recipes.yaml.d/> (relative to the
recipes file's directory) are merged on top of the base file.  Files are
processed depth-first, alphabetical within each level.

=cut

sub recipe_config {
    my ($self) = @_;
    return $self->{_recipe_config} if exists $self->{_recipe_config};

    my $pfile = $self->{recipes_file};
    unless ( -f $pfile ) {
        $self->{_recipe_config} = {};
        return {};
    }

    my $c = YAML::Load( File::Slurper::read_text($pfile) );
    $c //= {};

    my $base = $self->{base_dir};
    for my $dir ( map { "$base/$_" } qw{recipes.d recipes.yaml.d} ) {
        next unless -d $dir;
        File::Find::find(
            {
                wanted => sub {
                    my $object = $_;
                    return unless -f $object && $object =~ m/\.yaml$/;
                    my $frag = YAML::Load( File::Slurper::read_text($object) );
                    return unless ref $frag eq 'HASH';
                    delete $frag->{_base};
                    delete $frag->{_shared};
                    $c = Hash::Merge::merge( $c, $frag );
                },
                no_chdir => 1,
                bydepth  => 1,
            },
            $dir
        );
    }

    $self->{_recipe_config} = $c;
    return $c;
}

=head3 $cfg->ipmap()

Return the IP-map configuration as a hashref with keys:

=over 4

=item global_conf — basedir, admin_user, admin_key, tld, ip, gateway, etc.

=item ip_conf — domain to IP address

=item alias_conf — domain to list of aliases

=item ns_conf — nameserver configuration

=item addons — addon domain mapping

=back

When C<ipmap_file> exists the data is read from it (INI format via Config::Simple).
Otherwise the C<_base._global> section of the recipes YAML is used.  Dies if
neither source provides the data.

=cut

sub ipmap {
    my ($self) = @_;
    return $self->{_ipmap} if exists $self->{_ipmap};

    if ( defined $self->{ipmap_file} && -f $self->{ipmap_file} ) {
        require Config::Simple;
        my $c = Config::Simple->new( $self->{ipmap_file} );
        $self->{_ipmap} = {
            global_conf => $c->param( -block => 'global' )      // {},
            ip_conf     => $c->param( -block => 'ips' )         // {},
            alias_conf  => $c->param( -block => 'aliases' )     // {},
            ns_conf     => $c->param( -block => 'nameservers' ) // {},
            addons      => $c->param( -block => 'addons' )      // {},
        };
        return $self->{_ipmap};
    }

    # Fallback: read from _base._global in recipes.yaml
    my $rc = $self->recipe_config();
    my $g  = $rc->{_base}{_global} // {};
    die "No ipmap.cfg found and no _base._global section in recipes.yaml — "
      . "cannot determine host configuration\n"
      unless %$g;

    my @scalar_keys = qw(
        basedir admin_user admin_key admin_gecos admin_email
        tld ip gateway resolvers bridge_devname dhcp_devname transfer_user
    );
    my $global_conf = { map { $_ => $g->{$_} } grep { exists $g->{$_} } @scalar_keys };

    $self->{_ipmap} = {
        global_conf => $global_conf,
        ip_conf     => $g->{ips}         // {},
        alias_conf  => $g->{aliases}     // {},
        ns_conf     => $g->{nameservers} // {},
        addons      => $g->{addons}      // {},
    };
    return $self->{_ipmap};
}

1;
