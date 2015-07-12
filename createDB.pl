#!/usr/bin/perl
# by Stephen Wetzel May 03 2015


use strict;
use warnings;
use DBI;




#subject_code text
#course_no text
#instr_type text
#instr_method text
#section text
#crn integer primary key
#course_title text
#day text
#time text
#instructor text
#campus text
#max_enroll integer
#enroll integer
#building text
#room text
#description text
#pre_reqs text


my $dbfile = 'tms.db';
my $dsn      = "dbi:SQLite:dbname=$dbfile";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
	PrintError       => 0,
	RaiseError       => 1,
	AutoCommit       => 1,
});
 

my $sql = <<'END_SQL';
CREATE TABLE classes (
 subject_code TEXT,
 course_no TEXT,
 instr_type TEXT,
 instr_method TEXT,
 section TEXT,
 crn INTEGER PRIMARY KEY,
 course_title TEXT,
 credits REAL,
 day TEXT,
 time TEXT,
 instructor TEXT,
 campus TEXT,
 max_enroll INTEGER,
 enroll INTEGER,
 building TEXT,
 room TEXT,
 description TEXT,
 pre_reqs TEXT
)
END_SQL
 
$dbh->do($sql);











 
$dbh->disconnect;





print "\nDone\n\n";
