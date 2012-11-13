#!/usr/bin/perl -w

use XMLRPC::Lite;
use Data::Dumper;

my $username = shift;
my $password = shift;

my $bug_opendate = "";

sub getBugActivity
{

my ($bugid) = @_;
my $mark_resolved = 0;
my $mark_added_urgent=0;
my $mark_added_high=0;

my $rpc = new XMLRPC::Lite(proxy=>'https://bugzilla.redhat.com/bugzilla/xmlrpc.cgi');

my $call = $rpc->call('bugzilla.getBugActivity', $bugid, $username, $password);

my $result = "";
if ($call->faultstring) {
    print $call->faultstring . "\n";
    exit;
} else {
    $result = $call->result;
}

foreach $a (@{$result})
{
	my $when = $a->{'when'};
	my ($ee,$f) =  split(/\s+/,$when);
	$ee =~ s/\./-/g;

	my $changes = $a->{'changes'};
	my $c = "";
	my $d = "";
	my $e = "";
	foreach $b (@{$changes})
	{
		$c = $b->{'added'};
		$d = $b->{'removed'};
		$e = $b->{'fieldname'};
		if ( $c =~ /urgent/i && $e =~ /priority/i )
		{
			print "$ee=added_urgent,";
			$mark_added_urgent=1;
		}
		if ( $c =~ /high/i && $e =~ /priority/i )
		{
			print "$ee=added_high,";
			$mark_added_high=1;
		}
		if ( $d =~ /urgent/i && $e =~ /priority/i )
		{
			print "$ee=removed_urgent,";
			if($mark_added_urgent == 0)
			{
				print "$bug_opendate=added_urgent,";
			}
			$mark_added_urgent=1;
		}
		if ( $d =~ /high/i && $e =~ /priority/i )
		{
			print "$ee=removed_high,";
			if($mark_added_high == 0)
			{
				print "$bug_opendate=added_high,";
			}
			$mark_added_high=1;
		}
		if ( $c =~ /modified/i || $c =~ /on_qa/i ) 
		{
			if ($mark_resolved == 0)
			{
				print "$ee=resolved,";
				$mark_resolved = 1;
			}
		}
		if ( $c =~ /verified/i )
		{
			print "$ee=verified,";
		}
		if ( $c =~ /closed/i )
		{
			print "$ee=closed,";
		}
	}
}

}

my $rpc;
my $result;
$rpc = new XMLRPC::Lite (proxy=>'https://bugzilla.redhat.com/bugzilla/xmlrpc.cgi');
my $querydata = {
	'bug_status' => ["NEW","VERIFIED","ASSIGNED","REOPENED","NEEDINFO_ENG","NEEDINFO","MODIFIED","ON_DEV","QA_READY","ON_QA","FAILS_QA","UNCONFIRMED","NEEDINFO_REPORTER","POST","CLOSED","VERIFIED"],
	'column_list'       => ['changeddate','opendate', 'bug_severity','priority','assigned_to','bug_status','short_desc','component','product','target_milestone','resolution','version'],
	'product'    => ['Red Hat Storage'],
	'f1' => 'flagtypes.name',
	'o1'  => 'anywords',
	'v1' => 'rhs-2.1.0 rhs-future rhs-2.2.0',
	'f2' => 'keywords',
	'o2'  => 'nowords',
	'v2' => 'FutureFeature',
	'f3' => 'short_desc',
	'o3'  => 'nowords',
	'v3' => 'RFE FEATURE [FEAT] FutureFeature',
	'f4' => 'assigned_to',
	'o4'  => 'nowords',
	'v4' => 'divya asriram',

};
my $call = $rpc->call('bugzilla.runQuery', $querydata, $username, $password);
if ($call->faultstring) {
    print $call->faultstring . "\n";
    exit;
} else {
    $result = $call->result;
}

foreach $bug (@{$result->{'bugs'}})
{

print "$bug->{'bug_id'}";
print ",";

my $d = $bug->{'opendate'} ;
my ($dd,$t) =  split(/\s+/,$d);
print "$dd=opened,";
$bug_opendate = $dd;
print "priority=$bug->{'priority'}";
print ",";
print "status=$bug->{'bug_status'}";
print ",";

# get bug activity
my $result = "";
$result = getBugActivity($bug->{'bug_id'});
print "\n";
}

