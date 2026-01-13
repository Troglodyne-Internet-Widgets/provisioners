package Provisioner::Recipe;

use strict;
use warnings FATAL => 'all';

use Text::Xslate;
use Text::Xslate::Bridge::TT2;

=head1 Provisioner::Recipe

=head2 SYNOPSIS

    package Provisioner::Recipe::example;
    use parent qw{Provisioner::Recipe};

    sub deps { qw{nginx-full} }
    sub validate { my ($self, %opts) = @_; return %opts; }
    sub template_files { ('example.conf.tt' => 'example.conf') }

=head2 DESCRIPTION

Base class for provisioner recipes. Provides framework for building deployment makefiles via templated fragments.

=cut

=head3 new

Create new recipe instance.

=over 1

=item INPUTS: %opts hash containing template_dirs

=item OUTPUTS: blessed recipe object

=back

=cut

sub new {
    my ( $class, %opts ) = @_;

    my ($tname) = $class =~ m/^Provisioner::Recipe::(\w+)$/;
    die "Could not extract recipe name.  Recipes must be of form Provisioner::Recipe::*" unless $tname;

    $opts{template} = "$tname.tt";

    $opts{tt} = Text::Xslate->new(
        {
            path     => $opts{template_dirs},
            syntax   => 'TTerse',
            module   => [qw{Text::Xslate::Bridge::TT2}],
            function => { $class->formatters() },
        }
    ) || die "Could not initialize template dir";

    return bless( \%opts, $class );
}

=head3 formatters

Define custom template formatters. Override in subclasses.

=over 1

=item INPUTS: none

=item OUTPUTS: list of formatter key-value pairs

=back

=cut

sub formatters {
    return ();
}

=head3 vars

Define default template variables.

=over 1

=item INPUTS: none

=item OUTPUTS: list of variable key-value pairs

=back

=cut

sub vars {
    return ();
}

=head3 deps

Define system package dependencies.

=over 1

=item INPUTS: none

=item OUTPUTS: list of package names

=back

=cut

sub deps {
    return ();
}

=head3 validate

Validate recipe configuration.

=over 1

=item INPUTS: %opts configuration hash

=item OUTPUTS: validated %opts hash

=back

=cut

sub validate {
    shift;
    return @_;
}

=head3 datadirs

Define data directories to create.

=over 1

=item INPUTS: none

=item OUTPUTS: list of directory names

=back

=cut

sub datadirs {
    return ();
}

=head3 remote_files

Define files to backup/restore between deployments.

=over 1

=item INPUTS: none

=item OUTPUTS: hash of remote_path => local_path

=back

=cut

sub remote_files {
    my ( $self, $install_dir, $domain ) = @_;
    return ();
}

=head3 template_files

Define template files to process.

=over 1

=item INPUTS: @recipes list of enabled recipes

=item OUTPUTS: hash of template => output_filename

=back

=cut

sub template_files {
    my ( $self, @recipes ) = @_;
    return ();
}

=head3 makefile_vars

Define makefile variables.

=over 1

=item INPUTS: none

=item OUTPUTS: hash of variable_name => value

=back

=cut

sub makefile_vars {
    return ();
}

# Global parameter validation
my $validate = sub {
    my %params = @_;
    return %params;
};

=head3 render

Render recipe's main template.

=over 1

=item INPUTS: @_ template variables

=item OUTPUTS: rendered template string

=back

=cut

sub render {
    my ($self) = shift;
    return $self->render_file( $self->{template}, @_ );
}

=head3 render_file

Render specified template file.

=over 1

=item INPUTS: $file template filename, @_ template variables

=item OUTPUTS: rendered template string

=back

=cut

sub render_file {
    my ( $self, $file ) = ( shift, shift );
    my %vars = $self->validate(

        # Sane defaults
        $self->vars(),

        # Config overrides
        @_,
    );
    %vars = $validate->(%vars);
    return $self->{tt}->render( $file, \%vars );
}

1;
