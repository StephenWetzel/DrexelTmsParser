#!/usr/bin/perl
# by Stephen Wetzel May 03 2015
#Requires cURL is installed

#Use getSchedule.pl first to get a list of URLs of detail pages for each course.

use strict;
use warnings;
#use List::MoreUtils qw(any uniq);
use DBI;

#use autodie; #die on file not found
$|++; #autoflush disk buffer

my $dbFile = 'tms.db';
my $dsn      = "dbi:SQLite:dbname=$dbFile";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
	PrintError       => 0,
	RaiseError       => 1,
	AutoCommit       => 1,
});
my $inFileName = 'crns.csv';
my $outFileName = 'classes.tsv';
my $baseUrl = 'https://duapp2.drexel.edu';
my $sessionId = '2357A293F0608215F6D989A989D17BE1';
my $body=''; #response body
my $count = 0;


my $temp = `curl -s -D -  --data 'formids=term%2CcourseName%2CcrseNumb%2Ccrn&component=searchForm&page=Home&service=direct&submitmode=submit&submitname=&term=1&courseName=test&crseNumb=&crn=' -X POST https://duapp2.drexel.edu/webtms_du/app -o /dev/null`; #Note the lack of &session=T, that's important

$temp =~ m/Set-Cookie: JSESSIONID=([A-F0-9]{32})/ or die "Can't find JSESSIONID";
$sessionId = $1; #found the current session ID



open my $ifile, '<', $inFileName;
my @fileArray = <$ifile>;
close $ifile;

open my $ofile, '>', $outFileName;




foreach my $thisLine (@fileArray)
{
	chomp($thisLine);
	my $curlRequest = "curl --header 'cookie: JSESSIONID=$sessionId;' -X GET \"$baseUrl$thisLine\" 2>/dev/null";
	
	#print "\n$curlRequest";
	$body = `$curlRequest`; #get response body from curl
	
	my ($crn, $subject, $cNum, $credits, $title, $campus, $prof, $type, $comments, $time, $day, $desc, $preq) = ('', '', '', '', '', '', '', '', '', '', '', '', '');
	
	$body =~ m/CRN<\/td>\s+<td class.+>(\d+)<\/td>/ and $crn = $1;	
	$body =~ m/Subject Code<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $subject = $1;
	$body =~ m/Course Number<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $cNum = $1;
	$body =~ m/Credits<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $credits = $1;
	$body =~ m/Title<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $title = $1;
	$title =~ s/&amp;/&/g;
	$body =~ m/Campus<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $campus = $1;
	$body =~ m/Instructor\(s\)<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $prof = $1;
	$body =~ m/Instruction Type<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $type = $1;
	$type =~ s/&amp;/&/g;
	#$body =~ m/Section Comments<\/td>\s+<td class.+>([^<>]+)<\/td>/ and $comments = $1;
	
	$body =~ m/<td align="center" >(\d{2}:\d{2} [amp]{2} - \d{2}:\d{2} [amp]{2})<\/td>/ and $time = $1;
	$body =~ m/<td align="center" >([MTWRFSTBD]{1,6})<\/td>/ and $day = $1;
	
	$body =~ m/<div class="courseDesc">(.+)<\/div>/ and $desc = $1;
	$body =~ m/<div class="subpoint"><B>Pre-Requisites:<\/B> <span>(.+)<\/span><\/div>/ and $preq = $1;
	
	
	print "\n\n$count $subject \t$cNum \t$credits \t$title \t$campus \t$prof \t$type \t$time \t$day\n";
	
	print $ofile "\n$subject \t$cNum \t$crn \t$credits \t$title \t$campus \t$prof \t$type \t$time \t$day \t$preq \t$desc";
	
	$dbh->do('INSERT INTO classes (subject_code, course_no, crn, credits, course_title, campus, instructor, instr_type, time, day, pre_reqs, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', undef, $subject, $cNum, int($crn), $credits, $title, $campus, $prof, $type, $time, $day, $preq, $desc);
	
	$count++;
	#sleep(1);
	
}

$dbh->disconnect;

print "\nDone\n\n";
