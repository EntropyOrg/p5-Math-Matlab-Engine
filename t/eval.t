use Test::More tests => 1;

use strict;
use warnings;

use Math::Matlab::Engine;
use Capture::Tiny qw(capture_stdout);

my $e = Math::Matlab::Engine->new;

my ($capture) = capture_stdout {
	$e->eval( '[1 2 3]' );
};

is( $capture, <<EOF, 'correct output' );
>> 
ans =

     1     2     3

EOF

done_testing;
