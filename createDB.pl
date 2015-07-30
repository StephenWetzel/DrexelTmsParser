#!/usr/bin/perl
# by Stephen Wetzel May 03 2015

#create empty database tables

use strict;
use warnings;
use DBI;

# This script works directly with our SQLite DB  
my $dbFile = '../database.sqlite';
my $dsn      = "dbi:SQLite:dbname=$dbFile";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
	PrintError       => 0,
	RaiseError       => 1,
	AutoCommit       => 1,
});
 

my $sql = <<'END_SQL';
CREATE TABLE classes (
 year INTEGER,
 term TEXT,
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
 pre_reqs TEXT,
 co_reqs TEXT,
 timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)
END_SQL
$dbh->do($sql);

$sql = <<'END_SQL';
CREATE TABLE class_urls (
 year INTEGER,
 term TEXT,
 crn INTEGER PRIMARY KEY,
 url TEXT,
 timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)
END_SQL
$dbh->do($sql);

$sql = <<'END_SQL';
CREATE TABLE subject_urls (
 year INTEGER,
 term TEXT,
 url TEXT PRIMARY KEY,
 timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)
END_SQL
$dbh->do($sql);

$dbh->disconnect;

print "\nDone\n\n";
