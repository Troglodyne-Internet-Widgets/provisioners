# Backups in Provisioners

This repository uses a standardized approach to handling data persistence and backups across deployments through the `remote_files` subroutine in provisioner recipes.

## How It Works

Each recipe that needs to persist data between deployments implements a `remote_files` subroutine that returns a hash mapping source paths on the remote server to local storage paths in the provisioner's data directory.

Example from a recipe:

```perl
sub remote_files {
    return (
        '/path/on/remote/server/file.db' => 'local/data/file.db',
        '/path/on/remote/server/config.yaml' => 'local/config/config.yaml',
    );
}
```

## Backup Process

- **During Deployment**: The framework automatically fetches files listed in `remote_files` from the previous deployment (if available) and stores them locally.
- **Data Storage**: Files are stored in the provisioner's data directory structure, typically under subdirectories named after the recipe.
- **Restoration**: On subsequent deployments, these files are restored to their original locations on the target server.

## Key Benefits

- **Automated**: No manual backup scripts needed for deployment-related persistence.
- **Self-Contained**: Keeps data within the provisioner's directory structure for easy management.
- **Chroot-Friendly**: Supports isolated deployments where data is contained within templated paths.
- **Version Control**: Changes to persisted data can be tracked if committed to the repository.

## Recipe Implementation

When adding a new recipe that requires data persistence:

1. Implement the `remote_files` subroutine in your recipe module.
2. Map critical data files (databases, configs, keys) to appropriate local paths.
3. Ensure the `datadirs` subroutine includes any directories needed for data storage.
4. The framework handles the rest automatically.

## Additional Backup Strategies

For ongoing backups beyond deployment persistence (e.g., daily snapshots), implement separate cron jobs or external backup solutions as needed. The `remote_files` mechanism is specifically for ensuring data continuity across provisioner runs.