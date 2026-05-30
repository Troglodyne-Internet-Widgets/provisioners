package Provisioner::Recipe::koan;

use strict;
use warnings FATAL => 'all';

use parent qw{Provisioner::Recipe};

use List::Util qw{any};

=head1 Provisioner::Recipe::koan

=head2 SYNOPSIS

    somedomain:
        koan:
            user: koan
            koan_email: "koan@somedomain.test"

            # Where to fetch koan from.  Defaults to the troglodyne fork
            # (https://github.com/troglodyne/koan.git, branch add_matrix_e2ee)
            # which carries the Megolm/Olm E2EE rewrite.  Override only if
            # you know upstream sukria/koan has caught up.
            repo_url:    "https://github.com/troglodyne/koan.git"
            repo_branch: "add_matrix_e2ee"

            # CLI provider that drives the agent (claude|codex|copilot|local)
            cli_provider: "claude"

            # Required when cli_provider=claude — the long-lived OAuth token
            # produced by `claude setup-token` on a workstation
            claude_oauth_token: "sk-ant-..."

            # GitHub bot identity (PAT with repo + notifications scopes)
            github_user:  "yourname-koan"
            github_token: "ghp_..."

            # Pretty-name for @mentions (defaults to github_user)
            github_nickname: "yourname-koan"

            # Personal accounts allowed to drive the bot via @mention
            github_authorized_users:
                - "yourname"

            # Messaging — pick exactly one of telegram / slack / matrix
            messaging_provider: "telegram"
            telegram_token:   "123456789:ABC-..."
            telegram_chat_id: "987654321"

            # slack_bot_token: "xoxb-..."
            # slack_app_token: "xapp-..."
            # slack_channel_id: "C01234ABCD"

            # matrix_homeserver: "https://matrix.org"
            # matrix_user_id:    "@koan:matrix.org"
            # matrix_room_id:    "!abcdef:matrix.org"
            # matrix_e2ee:       1                   # default; set 0 for plaintext
            # Credentials — supply EITHER:
            #   matrix_access_token: "syt_..."       # pre-minted token
            #   matrix_device_id:    "BRAND_NEW"     # required when e2ee=1
            # OR (mutually exclusive):
            #   matrix_password:     "hunter2"       # one-shot — bootstrap mints fresh device
            # matrix_pickle_key: "<64-hex>"          # optional; auto-gen if absent

            # Behaviour knobs (all optional)
            max_runs_per_day: 10
            interval_seconds: 60

            # Optional SMTP for session-digest emails
            # smtp_host:     "smtp.example.com"
            # smtp_port:     587
            # smtp_user:     "koan@example.com"
            # smtp_password: "..."
            # email_to:      "you@example.com"

            # Projects the bot collaborates on.  Each entry needs an
            # absolute `path` on the guest.  Optional `github_url`
            # (either "owner/repo" or a full https:// URL) makes the
            # recipe clone the repo to that path at first provision via
            # `gh repo clone`, using the bot's github_token; subsequent
            # provisions skip clone when .git/ already exists.  Without
            # github_url the path must be present by other means (a
            # host bind-mount, a manual clone, or `/add_project` via
            # the bot's chat at runtime).
            projects:
                myapp:
                    path: "/opt/projects/myapp"
                    github_url: "myorg/myapp"          # cloned at provision
                api:
                    path: "/opt/projects/api"
                    github_url: "https://github.com/myorg/api.git"
                    cli_provider: "copilot"
                bind_mounted_thing:
                    path: "/opt/projects/legacy"        # no github_url — must already exist

=head2 DESCRIPTION

Installs and runs the Kōan autonomous coding bot
(L<https://github.com/troglodyne/koan>, our fork with Megolm/Olm
end-to-end-encrypted Matrix support; upstream is at
L<https://github.com/sukria/koan>) as a pair of systemd services
(C<koan.service> + C<koan-awake.service>) owned by the recipe's service user.

When C<messaging_provider> is C<matrix>, E2EE is on by default and a
brand-new device must be acquired.  The recipe handles this two ways:

=over 1

=item * B<Pre-mint>: you create a fresh device in Element, pass the
        resulting C<matrix_access_token> and C<matrix_device_id> in
        recipes.yaml.

=item * B<Bootstrap>: you pass C<matrix_password> only.  On first
        provision the recipe runs C<python -m app.matrix_login> as the
        service user, which mints a fresh device and writes
        C<instance/matrix/credentials.env> (0600).  Re-provisions skip
        the bootstrap as long as that file exists.

=back

The Olm/Megolm store lives at C<instance/matrix-store/> and is
preserved across re-deploys by L</remote_files> alongside the rest of
C<instance/>.  Losing it means losing the ability to decrypt past room
sessions, so don't C<rm -rf> the data dir.

The recipe:

=over 1

=item * installs system deps (git, python venv, nodejs+npm, gh)

=item * clones koan into C<install_dir/domain>

=item * renders C<.env>, C<instance/config.yaml> and C<projects.yaml>

=item * builds the python virtualenv

=item * installs C<@anthropic-ai/claude-code> globally (when
        cli_provider=claude)

=item * writes systemd unit files and queues the services to start

=back

Secrets (telegram/slack/matrix tokens, github PAT, claude OAuth, SMTP
password) live only in the rendered C<.env> file, which is installed
0640 root:I<user>.  The C<instance/> tree is preserved across
re-provisions via L</remote_files>, so the bot's memory, journal and
missions survive a rebuild.

=head3 deps

System packages required to build and run koan on a Debian guest.

=head3 validate

Coerces defaults, validates that the messaging provider's credentials
are present, and that a CLI provider token is supplied where required.

=head3 template_files

Renders the env file, behaviour config, project list and two systemd
units into the config bundle.

=head3 datadirs

Pre-creates the C<koan/> data subdir so C<remote_files> has somewhere
to drop preserved instance state on first provision.

=head3 remote_files

Pulls back C<instance/> and C<logs/> from the running guest so the
bot's evolving memory/journal is captured into the data dir for
re-deploy.

=cut

sub deps {
    my ($self) = @_;
    if ( $self->{target_packager} eq 'deb' ) {
        my @pkgs = qw{
          git
          python3
          python3-venv
          python3-pip
          python3-dev
          nodejs
          npm
          gh
          ca-certificates
          make
          build-essential
        };
        # libolm is only strictly required when messaging_provider=matrix
        # with E2EE on, but it's small and the host is single-purpose —
        # always include so the pip install of matrix-nio[e2e] never
        # fails for want of a header.
        push @pkgs, qw{libolm-dev libffi-dev};
        return @pkgs;
    }
    die "Unsupported packager";
}

sub validate {
    my ( $self, %opts ) = @_;

    my $user = $opts{user};
    die "Must set user in _global (or [koan]) section — koan runs as a dedicated service user"
        unless $user;

    # Default to the troglodyne fork — it carries the Megolm/Olm E2EE
    # rewrite of the matrix provider plus the `app.matrix_login` bootstrap
    # helper.  Upstream koan (sukria/koan) explicitly excludes E2EE.
    # HTTPS, not SSH: fresh VMs don't have a key registered with GitHub.
    $opts{repo_url}    //= 'https://github.com/troglodyne/koan.git';
    $opts{repo_branch} //= 'add_matrix_e2ee';

    my $email = $opts{koan_email};
    die "Must set koan_email in [koan] section of recipes.yaml" unless $email;

    my $provider = $opts{messaging_provider} || 'telegram';
    die "messaging_provider must be one of: telegram, slack, matrix"
        unless any { $_ eq $provider } qw{telegram slack matrix};
    $opts{messaging_provider} = $provider;

    if ( $provider eq 'telegram' ) {
        die "Must set telegram_token in [koan] section"   unless $opts{telegram_token};
        die "Must set telegram_chat_id in [koan] section" unless defined $opts{telegram_chat_id};
    }
    elsif ( $provider eq 'slack' ) {
        die "Must set slack_bot_token in [koan] section"  unless $opts{slack_bot_token};
        die "Must set slack_app_token in [koan] section"  unless $opts{slack_app_token};
        die "Must set slack_channel_id in [koan] section" unless $opts{slack_channel_id};
    }
    elsif ( $provider eq 'matrix' ) {
        die "Must set matrix_homeserver in [koan] section" unless $opts{matrix_homeserver};
        die "Must set matrix_user_id in [koan] section"    unless $opts{matrix_user_id};
        die "Must set matrix_room_id in [koan] section"    unless $opts{matrix_room_id};

        # E2EE on by default — opt out with matrix_e2ee: 0.
        $opts{matrix_e2ee} //= 1;
        $opts{matrix_e2ee} = $opts{matrix_e2ee} ? 1 : 0;

        # Credentials: exactly one of (access_token + device_id) or (password).
        # Pre-mint path: operator created a brand-new device in Element,
        # passes both values verbatim.
        # Bootstrap path: provisioner runs app.matrix_login at first install
        # using a one-shot password; resulting credentials end up in
        # instance/matrix/credentials.env (loaded by systemd).
        my $have_token = $opts{matrix_access_token} ? 1 : 0;
        my $have_pw    = $opts{matrix_password}     ? 1 : 0;
        die "matrix needs exactly one of: matrix_access_token (+matrix_device_id), or matrix_password"
            unless $have_token xor $have_pw;
        if ($have_token) {
            die "matrix_device_id is required when matrix_access_token is set"
                if $opts{matrix_e2ee} && !$opts{matrix_device_id};
        }

        # Auto-generate a pickle key if E2EE is on and none supplied.  This
        # encrypts the local olm store on disk — losing it means losing the
        # ability to decrypt past sessions, so the user can supply their
        # own to keep it stable across re-deploys.
        if ( $opts{matrix_e2ee} && !$opts{matrix_pickle_key} ) {
            $opts{matrix_pickle_key} = join '',
                map { ( 0 .. 9, 'a' .. 'f' )[ rand 16 ] } 1 .. 64;
        }
    }

    my $cli = $opts{cli_provider} || 'claude';
    die "cli_provider must be one of: claude, codex, copilot, local"
        unless any { $_ eq $cli } qw{claude codex copilot local};
    $opts{cli_provider} = $cli;

    die "Must set claude_oauth_token in [koan] section when cli_provider=claude"
        if $cli eq 'claude' && !$opts{claude_oauth_token};

    die "Must set github_user in [koan] section"  unless $opts{github_user};
    die "Must set github_token in [koan] section" unless $opts{github_token};
    $opts{github_nickname}         //= $opts{github_user};
    $opts{github_authorized_users} //= [];

    $opts{max_runs_per_day} //= 10;
    $opts{interval_seconds} //= 60;

    $opts{projects} //= {};
    die "projects must be a hash of name => { path => ... }"
        unless ref $opts{projects} eq 'HASH';
    for my $pname ( keys %{ $opts{projects} } ) {
        my $p = $opts{projects}{$pname};
        die "projects.$pname must be a hash"
            unless ref $p eq 'HASH';
        die "projects.$pname.path is required"
            unless $p->{path};
        if ( $p->{cli_provider} ) {
            die "projects.$pname.cli_provider must be one of: claude, codex, copilot, local"
                unless any { $_ eq $p->{cli_provider} } qw{claude codex copilot local};
        }
    }

    # SMTP block is optional but must be all-or-nothing
    if ( $opts{smtp_host} || $opts{smtp_user} || $opts{email_to} ) {
        die "smtp_host, smtp_user, smtp_password and email_to must all be set together"
            unless $opts{smtp_host}
            && $opts{smtp_user}
            && $opts{smtp_password}
            && $opts{email_to};
        $opts{smtp_port} //= 587;
    }

    return %opts;
}

sub template_files {
    return (
        'koan.env.tt'             => 'koan.env',
        'koan.config.yaml.tt'     => 'koan.config.yaml',
        'koan.projects.yaml.tt'   => 'koan.projects.yaml',
        'koan.service.tt'         => 'koan.service',
        'koan-awake.service.tt'   => 'koan-awake.service',
    );
}

sub datadirs {
    return qw{koan};
}

sub remote_files {
    my ( $self, $install_dir, $domain ) = @_;
    return (
        "$install_dir/$domain/instance/" => 'koan/instance/',
        "$install_dir/$domain/logs/"     => 'koan/logs/',
    );
}

1;
