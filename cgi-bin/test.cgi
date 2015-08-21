#!/usr/bin/perl

use lib '/home/andressabini/workspace/Test-DBIMock-More/trunk';

use strict;
use warnings;
use Plack::Builder;
use Data::Dumper;

my $app = sub {
	
	sleep 3;
	
  return [
    '200',
    [ 'Content-Type' => 'text/html' ],
    [ '<html><body><div>Hola Mundo!!!</div></body></html>' ],
  ];
};

builder {
    enable 'Session';
    enable "Plack::Middleware::LAN::Logger";
    $app;
};
