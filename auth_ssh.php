<?php
/**
 * Auth_SSH
 *
 * Authentication class for SSH purpose.
 *
 * Provides both password-based and keypair authentication against a SSH server.
 * Offers more security than normal authentication methods when used with keypair.
 *
 * In order to use keypair-based authentication, the private key must be on the server where SSH is,
 * the user must be able to input (or upload) their public key, and have a passphrase
 * assigned to the keypair.
 **/
@require_once('auth_ssh_config.php');

class Auth_SSH {
	var $msg;
	var $host_fp;
	var $ssh_conn;
	var $host;
	var $port;

	function SSH_Conn(){
		global $ssh_config;

		if(!$this->ssh_conn){
			if((strlen($ssh_config['host']) > 0) && is_int($ssh_config['port'])){
				$this->ssh_conn = ssh2_connect($ssh_config['host'], $ssh_config['port']);

				if(!$this->ssh_conn){
					$this->msg = "Unable to connect to ". $host .":" . $port;
					return false;
				}

				return $this->ssh_conn;
			}

			return false;
		} else
			return $this->ssh_conn;
	}

	function SSH_Exists(){
		if(!function_exists('ssh2_connect')){
			$this->msg = "SSH2 PHP extension is not installed.";

			return false;
		}

		return true;
	}

	function SSH_FP(){
		global $ssh_config;

		if(strlen($ssh_config['fp']) != 32){
			$this->msg = "Host fingerprint length is incorrect.";
			return false;
		}

		$r = $this->SSH_Conn();

		$finger = ssh2_fingerprint($r, SSH2_FINGERPRINT_MD5 | SSH2_FINGERPRINT_HEX);

		if(strcmp($finger, $ssh_config['fp']) != 0){
			$this->msg = "Invalid server fingerprint.  Closing connection.";
			$this->ssh_conn = null;
			return false;
		}

		return true;
	}

	function SSH_GetFP(){
		$r = $this->SSH_Conn();

		return ssh2_fingerprint($r, SSH2_FINGERPRINT_MD5 | SSH2_FINGERPRINT_HEX);
	}

	function SSH_AuthKey($username, $pubkeyfile, $passphrase){
		global $ssh_config;

		if(!file_exists($privkeyfile)){
			$this->msg = "Unable to find private key file.";
			return false;
		}

		if(empty($passphrase)){
			$this->msg = "Due to security concerns, the private and public keys must have a passphrase.";
			return false;
		}

		$r = $this->SSH_Conn();

		if(!$r){
			$this->msg = "Unable to connect to the host ". $host . ":" . $port;
			return false;
		}

		// Parse the filepath to the private key
		$pkey = str_replace("%u", $username, $ssh_config['priv_key']);

		if(!ssh2_auth_pubkey_file($r, $username, $pubkeyfile, $pkey, $passphrase)){
			$this->msg = "Unable to authenticate user ". $username .".  Please ensure both the public key file and passphrase are correct.";
			$r = null;
			return false;
		}

		$r = null;

		return true;
	}

	function SSH_AuthPass($user, $pass){
		$r = $this->SSH_Conn();

		if(!$r){
			$this->msg = "Unable to connect to ". $host . ":" . $port;
			return false;
		}

		if(!ssh2_auth_password($r, $user, $pass)){
			$this->msg = "Username/password combination is incorrect.";
			$r = null;
			return false;
		}

		$r = null;

		return true;
	}
}
?>
