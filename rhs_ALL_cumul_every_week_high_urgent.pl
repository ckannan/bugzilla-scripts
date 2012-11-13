#!/usr/bin/perl -w

use GD::Graph::lines;
use GD::Graph::bars;
use Date::Calc qw(:all);

my @lines = "";

# get bug count 
sub get_open_bug_count 
{
	my ($date1) = @_ ;
	my $count = 0;
	my ($x,$y,$z) = split ( /-/ , $date1);
	my $xx = Date_to_Days($x,$y,$z);

	foreach (@lines)
	{
	        chomp($_);
		my $line = $_;
		if ( $line =~ /opened/i && $line =~ /priority=high/i || $line =~ /priority=urgent/i )
		{
			# split by ,
			my @test1 = split ( /,/ , $line);
			foreach (@test1)
			{
				my $test2 = $_;
				if ($test2 =~ /=/)
				{
					my ($a, $b) = split (/=/, $test2);
					if ($b =~ /opened/i)
					{
						my ($p,$q,$r) = split (/-/,$a);
						my $yy = Date_to_Days($p,$q,$r);
						my $zz = $xx - 7;
						if ( $yy <= $xx )
						{
							$count++;
							#print "Oxx=$xx,yy=$yy,zz=$zz,date=$date1,line=$line,count=$count\n";
						}
					}
				}
			}
		}
	}
return $count;
}

sub get_fix_bug_count 
{
	my ($date1) = @_ ;
	my $count = 0;
	my ($x,$y,$z) = split ( /-/ , $date1);
	my $xx = Date_to_Days($x,$y,$z);

	foreach (@lines)
	{
	        chomp($_);
		my $line = $_;
		if ( $line =~ /resolved/i && $line =~ /priority=high/i || $line =~ /priority=urgent/i )
		{
			# split by ,
			my @test1 = split ( /,/ , $line);
			foreach (@test1)
			{
				my $test2 = $_;
				if ($test2 =~ /=/)
				{
					my ($a, $b) = split (/=/, $test2);
					if ($b =~ /resolved/i)
					{
						my ($p,$q,$r) = split (/-/,$a);
						my $yy = Date_to_Days($p,$q,$r);
						my $zz = $xx - 7;
						if ( $yy <= $xx )
						{
							$count++;
							#print "Rxx=$xx,yy=$yy,zz=$zz,date=$date1,line=$line,count=$count\n";
						}
					}
				}
			}
		}
	}
return $count;
}

sub get_verified_bug_count 
{
	my ($date1) = @_ ;
	my $count = 0;
	my ($x,$y,$z) = split ( /-/ , $date1);
	my $xx = Date_to_Days($x,$y,$z);

	foreach (@lines)
	{
	    chomp($_);
		my $line = $_;
		#print "line=$line\n";
		if ( $line =~ /verified/i && $line =~ /priority=high/i || $line =~ /priority=urgent/i )
		{
			# split by ,
			my @test1 = split ( /,/ , $line);
			foreach (@test1)
			{
				my $test2 = $_;
				if ($test2 =~ /=/)
				{
					my ($a, $b) = split (/=/, $test2);
					if ($b =~ /verified/i && $a !~ /status/)
					{
						my ($p,$q,$r) = split (/-/,$a);
						my $yy = Date_to_Days($p,$q,$r);
						my $zz = $xx - 7;
						if ($yy <= $xx)
						{
							$count++;
							#print "Vxx=$xx,yy=$yy,zz=$zz,date=$date1,line=$line,count=$count\n";
						}
					}
				}
			}
		}
	}
return $count;
}

# main program
# read csv file
open (FILE,"rhs_ALL_priority.csv");
@lines = <FILE>;
close (FILE);

my $start_date = "2012-7-1";
my @start = (2012,7,1);
my @stop  = Today([$gmt]);
my @prev = "";

my @date_list = ();
my @resolved_list = ();
my @open_list = ();
my @verified_list = ();

$j = Delta_Days(@start,@stop);


for ( $i = 0; $i <= $j; $i = $i+7 )
{
	@curdate = Add_Delta_Days(@start,$i);

	my $dest = sprintf("%4d-%02d-%02d",@curdate);
	my $open_count = get_open_bug_count($dest);
	my $resolved_count = get_fix_bug_count($dest);
    $open_count = $open_count - $resolved_count;
	my $verified_count = get_verified_bug_count($dest);
    $resolved_count = $resolved_count - $verified_count;
	print ("$dest,$open_count,$resolved_count,$verified_count\n");

	push @date_list , $dest;
	push @resolved_list , $resolved_count;
	push @open_list , $open_count;
	push @verified_list , $verified_count;
}

# draw urgent graph
my @data = ([@date_list],[@open_list],[@resolved_list],[@verified_list]);
# LINE GRAPH
my $mygraph = GD::Graph::bars->new(1024,768);
my $font_file = "/usr/share/fonts/gnu-free/FreeSans.ttf";


$mygraph->set(

    x_label     => 'Dates',
    y_label     => '# of Bugs - Every week',
    title       => 'Red Hat Storage - Release Target: ALL - Cumulative - Bug Graph - Only High/Urgent Bugs',
    bar_spacing => 1,
    bar_width   => 50,
    transparent => 0,
    x_labels_vertical => 1,
    overwrite => 1,
    dclrs       => ['#A4A4A4', '#01DFD7', '#74DF00'],
    x_label_position   => 0.5,
    legend_placement     => 'RC',
    box_axis     => 0,
    x_ticks      => 0,
    legend_marker_width  => 12,
    legend_marker_height => 12,

) or warn $mygraph->error;
$mygraph->set_title_font($font_file, 14);
$mygraph->set_x_label_font($font_file, 16);
$mygraph->set_y_label_font($font_file, 16);
$mygraph->set_x_axis_font($font_file, 11);
$mygraph->set_y_axis_font($font_file, 11);
$mygraph->set_legend_font($font_file, 9);
$mygraph->set_legend_font('/fonts/arial.ttf', 18);
$mygraph->set_legend('NEW/ASSIGNED', 'MODIFIED/ON_QA', 'VERIFIED');

my $myimage = $mygraph->plot(\@data) or die $mygraph->error;

# write to file
open OUT, ">rhs_ALL_cumul_every_week_high_urgent.png";
binmode OUT;
print OUT $myimage->png;
close (OUT);
###
