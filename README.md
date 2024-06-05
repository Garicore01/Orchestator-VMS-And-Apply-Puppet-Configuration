# Remote Machine Orchestrator with Puppet

## Description

This Ruby script is designed to orchestrate remote commands, check connectivity, and apply Puppet manifests on multiple machines using SSH. It can verify if machines are listening on port 22, execute specified commands remotely, and apply Puppet manifests.

## Features

- **Check Connectivity**: Ping machines to see if they are listening on port 22.
- **Remote Command Execution**: Execute specified commands on remote machines via SSH.
- **Puppet Manifest Application**: Apply Puppet manifests on specified machines or groups of machines.

## Usage

### Help

To get help on using the script, run:

```sh
ruby checkConnection help
