#!/usr/bin/perl
# by Stephen Wetzel May 03 2015
#Requires cURL is installed

#Run this first to get a list of detailed pages for each class stored in crns.csv.
#Will do a search for courses that contain the letter 'a', then 'e' and so on.  It'll dump the detailed page url to a file and the script getClassDetails.pl can be used to go through them and get the course details.

use strict;
use warnings;
use List::MoreUtils qw(any uniq);
use DBI;
use HTML::Entities;

#use autodie; #die on file not found
$|++; #autoflush disk buffer

#curl --header 'cookie: JSESSIONID=DAFD862E73D3B79F02A873681C5FADDF;' --data 'formids=term%2CcourseName%2CcrseNumb%2Ccrn&component=searchForm&page=Home&service=direct&session=T&submitmode=submit&submitname=&term=4&courseName=test&crseNumb=&crn=' -X POST https://duapp2.drexel.edu/webtms_du/app


my $dbFile = 'tms.db';
my $dsn      = "dbi:SQLite:dbname=$dbFile";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
	PrintError       => 0,
	RaiseError       => 1,
	AutoCommit       => 1,
});

my $url = "https://duapp2.drexel.edu/webtms_du/app";
my $sessionId = '2357A293F0608215F6D989A989D17BE1';
my $body=''; #response body
my $data='formids=term%2CcourseName%2CcrseNumb%2Ccrn&component=searchForm&page=Home&service=direct&session=T&submitmode=submit&submitname=&crseNumb=&crn=&courseName=';
my $year = 2014; #these will need to be set programtically at some point
my $term = 'Fall';



#It seems on the TMS search page, the terms 1-4 are always fall through summer of this academic year.
#Next year is terms 5-8, but don't seem to work

my @termNames = ('', 'Fall', 'Winter', 'Spring', 'Summer');
#my @letters = ('a', 'e', 'i', 'o', 'u', 'y');
my @letters = ('z');


sub getTimeStamp {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
}

#get the JSESSIONID:
#X-Powered-By: Servlet 2.5; JBoss-5.0/JBossWeb-2.1
#Set-Cookie: JSESSIONID=4B8CFED15E5B0566D67F70FFB8F570D0; Path=/webtms_du; Secure
#Content-Type: text/html;charset=UTF-8

my $temp = `curl -s -D -  --data 'formids=term%2CcourseName%2CcrseNumb%2Ccrn&component=searchForm&page=Home&service=direct&submitmode=submit&submitname=&term=1&courseName=test&crseNumb=&crn=' -X POST https://duapp2.drexel.edu/webtms_du/app -o /dev/null`; #Note the lack of &session=T, that's important

$temp =~ m/Set-Cookie: JSESSIONID=([A-F0-9]{32})/ or die "Can't find JSESSIONID";
$sessionId = $1; #found the current session ID

for (my $termNum = 1; $termNum <= 4; $termNum++)
{
	my %maxEnrolls;
	my %enrolls;
	my %urls;
	my $timestamp = getTimeStamp();
	if ($termNum == 2) { $year++; } #term 2 is winter
	print "\n\nDownloading data for $termNames[$termNum] $year";
	my @allUrls;
	foreach my $letter (@letters)
	{
		print "\n\ncurl --header 'cookie: JSESSIONID=$sessionId;' --data '$data$letter&term=$termNum' -X POST $url 2>/dev/null";
		$body = `curl --header 'cookie: JSESSIONID=$sessionId;' --data '$data$letter&term=$termNum' -X POST $url 2>/dev/null`; #get response body from curl
		print "\nLetter: $letter";
		my @newUrls = ();
		
		my $newUrlCount = 0;
		while ($body =~ m/.+<p title="Max enroll=(\d+); Enroll=(\d+).+&amp;page=CourseSearchResult&amp;service=direct&amp;session=T(&amp;sp=.+;sp=0)">(\d+)<\/a>/g)
		{
			my $crn = int($4);
			my $maxEnroll = $1;
			my $enroll = $2;
			my $detailUrl = decode_entities($3);
			$detailUrl = decode_entities($detailUrl);
			$urls{$crn} = $detailUrl;
			$maxEnrolls{$crn} = $maxEnroll;
			$enrolls{$crn} = $enroll;
			$newUrlCount++;
		}
		
		print "\nNew URLs: ", $newUrlCount;
	}
	
	foreach my $crn (keys %urls)
	{
		my $thisUrl = $urls{$crn};
		my $thisMax = $maxEnrolls{$crn};
		my $thisEnroll = $enrolls{$crn};
		$dbh->do('INSERT OR REPLACE INTO class_urls (year, term, crn, url, timestamp) 
		VALUES (?, ?, ?, ?, ?)', undef, $year, $termNames[$termNum], $crn, $thisUrl, $timestamp);
		
		$dbh->do('UPDATE classes SET 
		max_enroll = ?, enroll = ?
		WHERE crn = ?', undef, $thisMax, $thisEnroll, $crn);
	}
}


$dbh->disconnect;
print "\nDone\n\n";
