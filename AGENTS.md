# AGENTS.md - Coding Guidelines for Provisioners Repository

This document provides guidelines for AI coding agents working with the Provisioners codebase.

## Overview

Provisioners is a Perl-based configuration file generator for provisioning VMs using a recipe-based approach.
It generates makefiles and configuration files to deploy services easily with backup/restore capabilities.

## Build and Test Commands

### Running the Main Tool
```bash
# Create a new configuration for a domain
bin/new_config test.somedomain

# With custom config files
bin/new_config --ipmap=path/to/ipmap.cfg --recipes=path/to/recipes.yaml domain.name
```

### Perl Module Development
```bash
# Install dependencies (if cpanfile exists)
cpanm --installdeps .

# Run perl syntax check
perl -c lib/Provisioner/Recipe/yourmodule.pm

# Check POD documentation
perldoc lib/Provisioner/Recipe/yourmodule.pm
```

### Testing
Currently, no automated test suite exists. When implementing tests:
- Place test files in a `t/` directory
- Use Test::More or similar testing framework
- Run tests with: `prove -l t/`

## Code Style Guidelines

### Perl Style

#### File Structure
```perl
package Provisioner::Recipe::example;

use strict;
use warnings FATAL => 'all';

use parent qw{Provisioner::Recipe};

# Other module imports
use YAML;
use File::Slurper;
```

#### Imports and Dependencies
- Always use `strict` and `warnings FATAL => 'all'`
- Use `parent` for inheritance, not `use base`
- Group imports logically: core modules first, then CPAN modules
- Avoid experimental features unless with proper warnings handling

#### Naming Conventions
- Package names: `Provisioner::Recipe::recipename` (lowercase recipe names)
- Subroutines: lowercase with underscores (e.g., `remote_files`, `template_files`)
- Variables: lowercase with underscores for locals
- Constants: UPPERCASE with underscores

#### Error Handling
- Use `die` with descriptive messages for fatal errors
- Include context in error messages: `die "Could not open $file: $!"`
- Validate inputs early in subroutines

#### POD Documentation
```perl
=head1 Provisioner::Recipe::example

=head2 SYNOPSIS

    somedomain:
        example:
            option: value

=head2 DESCRIPTION

Brief description of what this recipe does.

=head3 subroutine_name

What it does.

=over 1

=item INPUTS: parameter descriptions

=item OUTPUTS: return value description

=back

=cut
```

### Recipe Development

#### Required Methods
```perl
sub deps {
    my ($self) = @_;
    if ($self->{target_packager} eq 'deb') {
        return qw{package1 package2};
    }
    die "Unsupported packager";
}

sub validate {
    my ($self, %opts) = @_;
    # Validate configuration options
    die "Required option missing" unless $opts{required_option};
    return %opts;
}
```

#### Optional Methods
```perl
sub template_files {
    return (
        'source.tt' => 'destination',
        'config.tt' => 'etc/config.conf',
    );
}

sub remote_files {
    return (
        '/remote/path/file' => 'local/backup/path',
    );
}
```

### Template Style (Text::Xslate TTerse)

- Use `[% %]` for template tags
- Variables: `[% variable_name %]`
- Loops: `[% FOR item IN list %]...[% END %]`
- Conditionals: `[% IF condition %]...[% END %]`
- Raw output: `[% var | mark_raw %]`

### Makefile Generation

Templates generate makefile fragments:
- No leading tabs (added automatically)
- Must be re-entrant for parallel execution
- Use state files: `[% state_dir %]/module_name`
- Touch state files after successful completion

## File Organization

```
provisioners/
├── bin/              # Executable scripts
├── lib/              # Perl modules
│   └── Provisioner/
│       ├── Recipe.pm # Base class
│       └── Recipe/   # Recipe implementations
├── scripts/          # Helper scripts deployed to VMs
├── templates/        # Template files
│   ├── *.tt          # Main recipe templates
│   └── files/        # Config file templates
├── docs/             # Documentation
└── vendor/           # Custom/private modules (gitignored)
```

## Best Practices

1. **Data Persistence**: Use `remote_files()` for backup/restore functionality
2. **File Paths**: Always use absolute paths in templates with `[% install_dir %]` prefix
3. **Permissions**: Set files/dirs to 0750 with `user:admin_user` ownership
4. **Symlinks**: Link configs from install_dir to system locations
5. **Dependencies**: List all package dependencies explicitly in `deps()`
6. **Validation**: Validate all required options in `validate()`
7. **Documentation**: Include POD with SYNOPSIS showing yaml config example

## Common Patterns

### Service User Creation
```perl
# In template
[% IF user %]
useradd -s /usr/sbin/nologin -d [% install_dir %]/[% domain %] [% user %]
[% END %]
```

### State Management
```perl
# In template
[% state_dir %]/module_name: dependencies
    # Commands to execute
    touch $@
```

### Config File Deployment
```perl
# In recipe
sub template_files {
    return ('nginx.conf.tt' => 'nginx/sites-enabled/domain.conf');
}
```

## Recipe Guidelines (from docs/APPROACH.md)

### Networking and Security
- **Unix Sockets**: Use unix sockets for HTTP services when possible, proxy via nginx
- **UFW Rules**: If public sockets are needed, add UFW application config to `/etc/ufw/applications.d`
- **SSL**: Update letsencrypt and pdns templates for DNS DCV when service requires SSL

### Execution and Dependencies
- **Order Not Guaranteed**: Use `queue_postrun_task` for service restarts or dependent operations
- **No Static Sleeps**: Use polling loops to check readiness, never static sleep times
- **Recipe Dependencies**: Don't list packages from dependent recipes in `deps()`. Instead validate:
  ```perl
  die "This recipe requires the nginxproxy recipe" 
      unless List::Util::any { $_ eq 'nginxproxy' } @{$opts{modules}};
  ```

## Debugging Tips

1. Check generated makefile in target directory
2. Verify template variables with debug output
3. Test recipes individually before combining
4. Use `make -n` to preview commands without execution
5. Check state files in `[% state_dir %]` for completion status