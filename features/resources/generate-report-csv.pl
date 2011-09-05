#!/usr/bin/perl

if ($#ARGV != 1) {
    print "\nGive number of features and number of test cases per feature as arguments.\n";
    exit;
}
    
$features = $ARGV[0];
$cases = $ARGV[1];
@results = ("1,0,0","0,1,0","0,0,1");

print "Feature,Test Case,Pass,Fail,NA,Comment,Measurement Name,Value,Unit,Target,Failure\n";
for ($fc = 0; $fc < $features; $fc++) {
    for ($tc = 0; $tc < $cases; $tc++) {
	$result = $results[int(rand(3))];
	print "Feature $fc,Testcase $tc,$result,comment\n";
    }
}
