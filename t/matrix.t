use Test::More tests => 16;

use strict;
use warnings;

use Math::Matlab::Engine;

my $ep = Math::Matlab::Engine->new;
ok(defined $ep->PutArray('N',[2,3],[1..6]));
my $n;
ok($n=$ep->GetArray('N'));
is_deeply($n, [ [1, 3, 5],
                [2, 4, 6] ] );

ok(defined $ep->PutArray('E1',[3,1],[1,0,0]));
ok(defined $ep->PutArray('E2',[3,1],[0,1,0]));
ok(defined $ep->PutArray('E3',[3,1],[0,0,1]));

ok(defined $ep->EvalString("N1=N*E1"));
ok(defined $ep->EvalString("N2=N*E2"));
ok(defined $ep->EvalString("N3=N*E3"));

my $n1 = $ep->GetArray('N1');
is_deeply( $n1, [ [1], [2] ] );

{
ok(defined $ep->PutArray('M',[2,3,4],[1..24]));
my $m;
ok($m=$ep->GetArray('M'));
is_deeply($m, [ [ [ 1, 4, 7,10],
				  [ 2, 5, 8,11],
				  [ 3, 6, 9,12] ],
				[ [13,16,19,22],
				  [14,17,20,23],
				  [15,18,21,24] ] ] );

}
{
ok(defined $ep->PutArray('M',[3,4,2],[1..24]));
my $m;
ok($m=$ep->GetArray('M'));
is_deeply($m, [
                [
				  [  1, 5 ],
				  [  2, 6 ],
				  [  3, 7 ],
				  [  4, 8 ], ],
                [
				  [  9,13 ],
				  [ 10,14 ],
				  [ 11,15 ],
				  [ 12,16 ], ],
                [
 				  [ 17,21 ],
				  [ 18,22 ],
				  [ 19,23 ],
				  [ 20,24 ], ], ] );
}

done_testing;
