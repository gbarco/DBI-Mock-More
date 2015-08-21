#!/usr/bin/perl -w

use strict;
use Switch;
use LAN::DevTools::Mock::DBI::Analizer;

my ($analizer, $service, $statement, $json_file, $perl_file, $verbose, $help);
my @params;  

sub init;
sub main;

init();
main();

# Control de argumentos...
sub init {
    my %args = @ARGV;
    for my $key(keys(%args)) {
        switch ($key) {
            case '--service'               { $service = $args{$key};               }
            case '--sql'                   { $statement = $args{$key};             }
            case '--json-file'             { $json_file = $args{$key};             }
            case '--perl-file'             { $perl_file = $args{$key};             }
            case '--verbose'               { $verbose = $args{$key};               }
            case '--params'                { $args{$key} =~ s/\"//g; @params = split(/\s/, $args{$key});   }
            case ['-h','--help','?','-?']  { $help = 1;                            }
        }
    }

    die q/
Ejemplo 1:

~# perl make_data_set.pl --service db_central --json-file myTestSQLiteDataSet1.json --perl-file myTestSQLiteDataSet1.pl --verbose 1 --sql "select session_id, id_venta FROM booking_engine_var.ventas WHERE id_venta LIKE 'www.1002%'"

Ejempĺo 2:
~# perl make_data_set.pl --service db_central --json-file myTestSQLiteDataSet1.json --perl-file myTestSQLiteDataSet1.pl --sql "select session_id, id_venta FROM booking_engine_var.ventas WHERE id_venta LIKE ?" --params '"www.1002%"'

--sql                Query a ejecutar, REQUERIDO!
--params             Listado de parametros separados por espacio y juntados con entrecomillado, ejemplo: '"coso" 1 "la cosa"'
--service            Si no se especifica se usa db_central
--verbose            Apagado normalmente, si no se especifican archicos de salida se activa.
--help, -h, -?, ?    Como llegaste aqui...


Otros casos:

perl make_data_set.pl --service db_central --json-file myTestSQLiteDataSet2.json --perl-file myTestSQLiteDataSet2.pl --sql "SELECT ventas.id, ventas.status, ventas.razon_status, ventas.pnr, ventas.fecha, cotizaciones.id_cotizacion, cotizaciones.routing FROM booking_engine_var.ventas INNER JOIN booking_engine_var.cotizaciones ON cotizaciones.id_cotizacion = ventas.id_cotizacion WHERE NOT ventas.pnr IS NULL AND ventas.fecha BETWEEN '2015-07-01 00:00:00' AND '2015-07-02 00:00:00' LIMIT 10;"

NOTA: Se requiere la librería SQL::Statement moficada, por ahora se encuentra en: https:\/\/github.com\/andressg79\/SQL-Statement

/ if (!$statement || $help);
    
    $service = 'db_central' if (!$service);
    $verbose = 1 if (!$json_file && !$perl_file);
  
    return;        
}

# Ejecucion de consulta y salvado de archivos...
sub main {

    $analizer = LAN::DevTools::Mock::DBI::Analizer->new(
        service => $service,
        statement   => $statement,
        perl_file   => $perl_file, 
        json_file   => $json_file,
        is_verbose  => $verbose,
        params      => \@params
    ); 

    $analizer->run();   
             
    return;
}

1;
    