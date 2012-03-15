<?php
$ssh_config = array();

// Host (FQDN or IP) of SSH server
$ssh_config['host'] = 'localhost';

// Port that the SSH server is listening on on host
$ssh_config['port'] = 22;

/**
 * The path (and filename) to the private key (if used).
 * Possible variables:
 * %u - Username (i.e.: username = bob, path = /home/%u/ expands to /home/bob)
 **/
$ssh_config['privkey_path'] = "/home/%u/.ssh/rsa_id";

// Fingerprint of host (MUST match!!)
$ssh_config['fp'] = "7864E406D00D843BB764B60CAF890465";

/**
 * Security authentication mode.
 * Modes:
 * 0 - password (not recommended)
 * 1 - key (recommended)
 **/
$ssh_config['mode'] = 1;
?>
