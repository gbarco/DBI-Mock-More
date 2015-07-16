use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Test::DBIMock::More',
	AUTHOR           => q{Gonzalo Barco <gbarco.public@cys.com.uy>},
	VERSION_FROM     => 'lib/Test/DBIMock/More.pm',
	ABSTRACT_FROM    => 'lib/Test/DBIMock/More.pm',
	LICENSE          => 'Artistic_2_0',
	PL_FILES         => {},
	MIN_PERL_VERSION => 5.14.2,
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 0,
	},
	BUILD_REQUIRES => {
		'Test::More' => 0,
	},
	PREREQ_PM => {
		'Moose'							=> '2.1403',
		'Try::Tiny'					=> '0.22',
		'DBI'								=> '1.633',
		'DBD::SQLite'				=> '1.48',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Test-DBIMock-More-*' },
);
