#!/usr/bin/perl

use strict;
use warnings;

##############################################################################
# MODULES
##############################################################################

use Log::Dispatch;
use XMLRPC::Lite;
use Data::Dumper;
use MIME::Base64;
use AppConfig;

##############################################################################
# VARIABLES
##############################################################################

$| = 1; # auto-flush output as it is written
my $CONFIG_FILE = './minbot.conf';
my @PARAMETERS  = qw ( debug update 
                       database_user=s database_pass=s 
                       database_url=s database_bug_url=s
                       blocker_enabled blocker_query=s% 
                       flag=s@ version=s
                       query_order=s query_column_list=s@
                     );
my $rpc;

##############################################################################
# CONFIGURATION
##############################################################################

my $config = new AppConfig(@PARAMETERS);
$config->file($CONFIG_FILE);
$config->getopt();

##############################################################################
# FORMAT
##############################################################################

#format STDOUT_TOP =
#                          Bug Reports
#@<<<<<<<<<<<<<<<<<<<<<<<     @|||         @>>>>>>>>>>>>>>>>>>>>>>>
#$system,                      $%,         $date
#------------------------------------------------------------------
#.

# Pretty cool!  As for feedback, I'd lose the ID since the number is in 
#the URL and is redundant.  Please add the component and Keywords.  Also 
#can the list be sorted by bugzilla number then component?

my ($bug, $url, $status, $name, $body, $time,$component,$keywords) = "";
$keywords = "";

format STDOUT =
-------------------------------------------------------------------------------
      URL: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
           $url
  Subject: ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
           $bug->{summary}
Component: @<<<<<<<<<<<<<<<<<<<<<<<<    Keywords: @<<<<<<<<<<<<<<<<<<<<<<<
           $component,                     $keywords
 Priority: @<<<<<<<<<<<<                Severity: @<<<<<<<<<
           $bug->{priority},                      $bug->{severity}
 Assigned: @<<<<<<<<<<<<<<<<<<<<<<<<    Reporter: @<<<<<<<<<<<<<<<<<<<<<<<
           $bug->{assigned_to},                   $bug->{creator}
   Status: @<<<<<<<<<<<<<               Platform: @<<<<<<<<<<<<<<<<<
           $bug->{status},                    $bug->{platform}
Dev White: @<<<<<<<<<<<<<<
           $bug->{whiteboard}

Most recent update at @>>>>>>>>>>>>>>> from @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...
                      $time,               $name

^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
$body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
$body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
$body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
$body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
$body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~
$body
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<...~
$body

.

##############################################################################
# METHODS
##############################################################################


sub last_comment($) {
    my $bug1 = shift;
    return "error: no bug provided" unless $bug1;

	my $tmpquerydata = {
		'ids' => "$bug1"
	};
    my $call = $rpc->call('Bug.comments', $tmpquerydata);
    my $result = "";
	my $l;

    if ($call->faultstring) {
       print $call->faultstring . "\n";
       exit;
    } else {
        $result = $call->result;
		my $result1 = $result->{bugs};
		my $result2 = $result1->{$bug1};
		my $result3 = $result2->{comments};
		my $result4 = pop @{$result3} ;
		my $creator = $result4->{creator};
		my $time = $result4->{time};
		my $text = $result4->{text};


		my ($ee,$f) =  split(/T/,$time);
		if ( $ee =~ m/(....)(..)(..)/ )
		{
			my ( $yyyy, $mm, $dd ) = ( $1, $2, $3 );
			$ee = "$yyyy-$mm-$dd";
		}

		$ee =~ s/^\s+//; 
		$ee =~ s/\s+$//; 

        return $creator,$ee,$text;
    }
}

sub do_query_display {
   my $querydata  = shift;
   my $subject;

   $querydata->{column_list} = $config->query_column_list;
#   $querydata->{order}       = $config->query_order;
#   $querydata->{version}     = $config->version;
   $querydata->{query_format} = 'advanced';

   # pickup the flags from the command line
   my $index=1; 
   while (my $flag = pop @{$config->flag}) {
       $querydata->{"f$index"}  = 'flagtypes.name';
       $querydata->{"o$index"}   = 'substring';
       $querydata->{"v$index"}  = $flag;
       $subject .= "$flag: ";
       $index++;
   }

   if ($config->debug) {
     print "querydata:", Dumper($querydata);
   }

   $rpc = new XMLRPC::Lite(proxy => $config->database_url);
   my $u = $config->database_user ;
   my $p = $config->database_pass ;
   my $call = $rpc->call('User.login', {login => $u, password => $p} );
   $call = $rpc->call('Bug.search', $querydata);

   my $result = "";
   if ($call->faultstring) {
       print $call->faultstring . "\n";
       exit;
   } else {
      $result = $call->result;
   }

   print $subject, @{$result->{'bugs'}} . " bug(s) found.\n";
	while ($bug = pop @{$result->{bugs}}) 
	{
		$url    = $config->database_bug_url . $bug->{id};
		($name, $time, $body) = last_comment($bug->{id});
		$component = pop @{$bug->{component}};
		$keywords = join(' ', @{$bug->{keywords}});
		write;
	}
}

##############################################################################
# MAIN
##############################################################################

do_query_display($config->blocker_query) if $config->blocker_enabled;
   
exit 0;

