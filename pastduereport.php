#!/usr/bin/php -q
<?php
/**
 * Blesta v2.5.2 3-day past due invoice report generator
 *
 * This is nothing special, but since Blesta doesn't have something like this in by default, a hack was developed.
 * If you want to change the x-days past due amount (a.k.a.: 5 days past due), just modify
 * strtotime("+3 days", ...) to be the day.  So if 5 days, it would be strtotime("+5 days", ...)
 *
 * Author: Eric Hansen
 * Company: Security For Us, LLC (https://www.securityfor.us)
 * Last modified: April 07, 2012 (04/07/2012)
 * License: Free (preference to leave this code block in place for due-credit purpose)
 * Blesta compatibility: only tested on v2.5.2
 **/
// Basic info (pointless really?)
$msg = "This report was started on ". date("m-d-Y") . " at " . date("h:i:s A") .".\n\n";

// Database connection stuff
$l = mysql_connect("localhost", "username", "password");
mysql_select_db("database");

// We get the date due, invoice ID and client ID from invoices where due date is less (before) current date AND have not been paid yet
$q = mysql_query("SELECT i_dated,i_id,i_uid FROM invoices WHERE i_dated < '". date("Y-m-d") ."' AND i_dater = '0000-00-00'");

// Basic info (how many total late invoices were found)
$msg .= "A total of ". mysql_num_rows($q) ." entries in the database were found to be past due.\nChecking to see if any are at least 3 days late...\n\n";
mysql_close();

// Entry position
$i = 0;

// Loop through each invoice
while($r = mysql_fetch_array($q)){
	/*
	 * If the due date of the invoice (+3 days) is less than current time, store some info
	 * This works because we already know the records we're sifting through are late invoices,
	 * so all we are doing is seeing if their due date + 3 days has already passed.
	 */
	if(strtotime("+3 days", strtotime($r['i_dated'])) < time()){
		$msg .= "-- Entry #". $i ."\n";

		// Provide link to user ID who invoice is assigned to
		$msg .= ">> User ID: ". $r['i_uid'] ." ( https://URL.to/Blesta/a-center.php?uid=". $r['i_uid'] ." )\n";

		// View the past-due invoice
		$msg .= ">> Invoice ID: ". $r['i_id'] ." ( https://URL.to/Blesta/b-invoice.php?iid=". $r['i_id'] ." )\n";

		// Get the days past x-days due point (i.e.: 2 days past 3-day late point)
		$days = 0;
		$dtime = time() - strtotime($r['i_dated']);

		while($dtime > 1){
			$days++;
			$dtime = $dtime / 86400;
		}

		// What was the due date?
		$msg .= ">> Due Date: ". $r['i_dated'] ." (past late day by ~". $days ." days.)\n\n";

		$i++;
	}
}

// Show how many were 3+ days past due
$msg .= "A total of ". $i ." invoices are at least 3 days past due.\n";

// Only mail out report if at least one invoice fits the criteria
if($i > 0){
	mail("admin@example.com", "3-day Late Invoices", $msg);
}
?>
