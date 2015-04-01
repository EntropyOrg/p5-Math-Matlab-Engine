use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use File::Which;
use File::Spec;

die "mex is not in path" unless which('mex');
# see example_mex_config for what the mex output looks like
# after running
#     mex -v  2>/dev/null | grep '='
my $mex_config_output = `mex -v -n`;

# remove the -> line prefixes
(my $mex_config_clean = $mex_config_output) =~ s/^->//gm;

# only get lines that have an equal sign in them
my @variable_lines = $mex_config_clean =~ /^.*=.*$/gm;

my $mex_config;
for my $line (@variable_lines) {
	next unless $line =~ /\s*(?<variable>[A-Z]*)\s*=\s*(?<data>.*)$/;
	$mex_config->{ $+{variable} } = $+{data};
}

my $matlab_INC = File::Spec->catfile( $mex_config->{MATLAB}, qw(extern include) );
die "No engine.h in $matlab_INC" unless -f File::Spec->catfile( $matlab_INC, qw(engine.h) );

WriteMakefile(
    'NAME'		=> 'Math::Matlab::Engine',
    'VERSION_FROM'	=> 'lib/Math/Matlab/Engine.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    CONFIGURE_REQUIRES  => {
        'File::Which' => 0,
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Math/Matlab/Engine.pm', # retrieve abstract from module
       AUTHOR     => 'Oliver Ebenhoeh <oliver.ebenhoeh@rz.hu-berlin.de>') : ()),
    'LIBS'		=> "$mex_config->{CLIBS} -leng", # e.g., '-lm'
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    'INC'		=> "-I$matlab_INC", # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);
