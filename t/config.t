#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use FindBin::libs;
use lib "$FindBin::Bin/../lib";

use Test::More;
use File::Temp qw{tempdir};
use File::Path qw{make_path};
use File::Slurper qw{write_text};
use Cwd qw{getcwd};
use YAML ();

use Provisioner::Config;

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

sub yaml_file {
    my ( $path, $data ) = @_;
    write_text( $path, YAML::Dump($data) );
}

# ------------------------------------------------------------------
# recipe_config() tests
# ------------------------------------------------------------------

{
    my $dir = tempdir( CLEANUP => 1 );

    # No recipes.yaml → empty hashref
    my $cfg = Provisioner::Config->new( recipes_file => "$dir/recipes.yaml" );
    is_deeply( $cfg->recipe_config(), {}, 'missing recipes.yaml returns empty' );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    yaml_file( "$dir/recipes.yaml", { domain1 => { recipe1 => { key => 'base' } } } );

    my $cfg = Provisioner::Config->new( recipes_file => "$dir/recipes.yaml" );
    is_deeply(
        $cfg->recipe_config(),
        { domain1 => { recipe1 => { key => 'base' } } },
        'basic recipes.yaml loaded'
    );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    yaml_file( "$dir/recipes.yaml", { domain1 => { recipe1 => { key => 'base' } } } );
    make_path("$dir/recipes.d");
    yaml_file( "$dir/recipes.d/extra.yaml", { domain1 => { recipe1 => { extra => 'yes' } } } );

    my $cfg = Provisioner::Config->new( recipes_file => "$dir/recipes.yaml" );
    my $rc  = $cfg->recipe_config();
    is( $rc->{domain1}{recipe1}{key},   'base', 'recipes.d: base key preserved' );
    is( $rc->{domain1}{recipe1}{extra}, 'yes',  'recipes.d: drop-in key merged' );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    yaml_file( "$dir/recipes.yaml", { domain1 => { recipe1 => { key => 'base' } } } );
    make_path("$dir/recipes.yaml.d");
    yaml_file( "$dir/recipes.yaml.d/extra.yaml", { domain1 => { recipe1 => { extra2 => 'yes' } } } );

    my $cfg = Provisioner::Config->new( recipes_file => "$dir/recipes.yaml" );
    my $rc  = $cfg->recipe_config();
    is( $rc->{domain1}{recipe1}{extra2}, 'yes', 'recipes.yaml.d: drop-in key merged' );
}

{
    # _base and _shared are stripped from drop-in files
    my $dir = tempdir( CLEANUP => 1 );
    yaml_file( "$dir/recipes.yaml", { domain1 => {} } );
    make_path("$dir/recipes.d");
    yaml_file(
        "$dir/recipes.d/dropin.yaml",
        {
            _base   => { sneaky => 1 },
            _shared => { sneaky => 1 },
            domain1 => { allowed => 1 },
        }
    );

    my $cfg = Provisioner::Config->new( recipes_file => "$dir/recipes.yaml" );
    my $rc  = $cfg->recipe_config();
    ok( !exists $rc->{_base},   'recipes.d: _base stripped' );
    ok( !exists $rc->{_shared}, 'recipes.d: _shared stripped' );
    ok( exists $rc->{domain1},  'recipes.d: domain key kept' );
}

{
    # Both recipes.d and recipes.yaml.d are merged
    my $dir = tempdir( CLEANUP => 1 );
    yaml_file( "$dir/recipes.yaml", {} );
    make_path("$dir/recipes.d");
    make_path("$dir/recipes.yaml.d");
    yaml_file( "$dir/recipes.d/a.yaml",        { dom => { from_d => 1 } } );
    yaml_file( "$dir/recipes.yaml.d/b.yaml",   { dom => { from_yaml_d => 1 } } );

    my $cfg = Provisioner::Config->new( recipes_file => "$dir/recipes.yaml" );
    my $rc  = $cfg->recipe_config();
    is( $rc->{dom}{from_d},      1, 'both dirs: recipes.d contributes' );
    is( $rc->{dom}{from_yaml_d}, 1, 'both dirs: recipes.yaml.d contributes' );
}

# ------------------------------------------------------------------
# ipmap() tests — YAML fallback
# ------------------------------------------------------------------

{
    my $dir = tempdir( CLEANUP => 1 );

    # No ipmap.cfg, no recipes.yaml → should die
    my $cfg = Provisioner::Config->new(
        recipes_file => "$dir/recipes.yaml",
        ipmap_file   => "$dir/ipmap.cfg",
    );
    eval { $cfg->ipmap() };
    ok( $@, 'ipmap() dies when neither source is present' );
}

{
    my $dir = tempdir( CLEANUP => 1 );

    # No ipmap.cfg, but recipes.yaml has _base._global
    yaml_file(
        "$dir/recipes.yaml",
        {
            _base => {
                _global => {
                    basedir      => '/opt/domains',
                    admin_user   => 'deploy',
                    admin_key    => 'gh:deploy',
                    admin_gecos  => 'Deploy Bot',
                    admin_email  => 'ops@example.com',
                    tld          => 'example.com',
                    ip           => '203.0.113.1',
                    gateway      => '203.0.113.254',
                    resolvers    => ['8.8.8.8'],
                    bridge_devname => 'virbr0',
                    dhcp_devname   => 'eth0',
                    transfer_user  => 'provision',
                    ips          => { 'vm1.example.com' => '203.0.113.10/24' },
                    aliases      => { 'vm1.example.com' => ['mail.vm1.example.com'] },
                    nameservers  => ['ns1.example.com'],
                    addons       => {},
                },
            },
        }
    );

    my $cfg = Provisioner::Config->new(
        recipes_file => "$dir/recipes.yaml",
        ipmap_file   => "$dir/ipmap.cfg",
    );
    my $m = $cfg->ipmap();
    is( $m->{global_conf}{basedir},    '/opt/domains', 'yaml fallback: basedir' );
    is( $m->{global_conf}{admin_user}, 'deploy',       'yaml fallback: admin_user' );
    is( $m->{global_conf}{admin_email},'ops@example.com', 'yaml fallback: admin_email' );
    is( $m->{ip_conf}{'vm1.example.com'}, '203.0.113.10/24', 'yaml fallback: ips' );
    is_deeply( $m->{alias_conf}{'vm1.example.com'}, ['mail.vm1.example.com'],
        'yaml fallback: aliases' );
    is_deeply( $m->{ns_conf}, ['ns1.example.com'], 'yaml fallback: nameservers' );
}

{
    # ipmap_file takes precedence over recipes.yaml _global when both exist
    my $dir = tempdir( CLEANUP => 1 );
    yaml_file(
        "$dir/recipes.yaml",
        { _base => { _global => { admin_email => 'from_yaml@example.com' } } }
    );

    # Minimal ipmap.cfg via Config::Simple INI format
    write_text( "$dir/ipmap.cfg", join( "\n",
        '[global]',
        'basedir=/opt/test',
        'admin_user=testuser',
        'admin_key=gh:testuser',
        'admin_gecos=Test User',
        'admin_email=from_cfg@example.com',
        'tld=test.example.com',
        'ip=10.0.0.1',
        'gateway=10.0.0.254',
        'resolvers=8.8.8.8',
        'bridge_devname=virbr0',
        'dhcp_devname=eth0',
        'transfer_user=prov',
        '',
        '[ips]',
        'vm1.test.example.com=10.0.0.10',
        '',
    ) );

    my $cfg = Provisioner::Config->new(
        recipes_file => "$dir/recipes.yaml",
        ipmap_file   => "$dir/ipmap.cfg",
    );
    my $m = $cfg->ipmap();
    is( $m->{global_conf}{admin_email}, 'from_cfg@example.com',
        'ipmap.cfg takes precedence over yaml _global' );
}

done_testing;
