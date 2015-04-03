package Math::Matlab::Engine;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);
our $VERSION = '0.02';

bootstrap Math::Matlab::Engine $VERSION;

sub eval {
	my ($e, $matlab_code) = @_;
	my $output = $e->_eval_helper( $matlab_code );
	print $output;
}

sub put_variable {
	...
}

sub get_variable {
	...
}

1;
__END__

=head1 NAME

Math::Matlab::Engine - Perl extension for using Matlab from within Perl

=head1 SYNOPSIS

  use Math::Matlab::Engine;

  my $ep = Math::Matlab::Engine->new();

  $ep->eval("plot(N)");

=head1 DESCRIPTION

This module is a wrapper around the C library matlab.h.

=head2 CLASS METHODS

=head3 new

  my $ep = Math::Matlab::Engine->new();

Creates a new C<Math::Matlab::Engine> object.

=head2 OBJECT METHODS

=head3 eval

  $ep->eval( Str $matlab_code )


=head1 AUTHOR

O. Ebenhoeh, E<lt>oliver.ebenhoeh@rz.hu-berlin.deE<gt>

=head1 SEE ALSO

L<PDL>.

=cut
