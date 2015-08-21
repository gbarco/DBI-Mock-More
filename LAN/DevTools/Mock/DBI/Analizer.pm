#!/usr/bin/perl -w
package LAN::DevTools::Mock::DBI::Analizer;

use Moose;
use Data::Dumper;
use SQL::Statement;

use lib $ENV{'LAN_APPS_ROOT'} . "/lib/perl";
use Init_Lan_Modules;
use Basic_Services;

# Agrego soporte light para perl_mvc framework
use Mvc_Light;

# Nombre del servicio
has 'service' => ( is => 'rw', isa => 'Str' );

# SQL a ejecutar
has 'statement' => (is => 'rw', isa => 'Str', default => 'db_central');

# Resultado del analisis!
has 'analize' => (is => 'rw', isa => 'HashRef');

# Parametros de la consulta
# TODO Discutir si vale la pena manejarlo y tenerlo... 
has 'params' => (is => 'rw', isa => 'ArrayRef');


has 'database'  => ( is => 'rw', isa => 'Str' );
has 'tables'    => ( is => 'rw', isa => 'Str' );

# Errores detectados en la ejecución...
# TODO: Se está usando???
has 'error' => (is => 'rw', isa => 'Str');

# Nombre del fichero de salida en formato JSON
has 'json_file' => (is => 'rw', isa => 'Str');

# Nombre del fichero de salida en formato Perl
has 'perl_file' => (is => 'rw', isa => 'Str');

# Determina si imprime avances en pantalla
has 'is_verbose' => (is => 'rw', isa => 'Bool', default => 0);

=item Function: prepare
Description:
    Hace el analisis de la SQL y prepara el objeto con los resultados. 

Parameters:
    No recibe, los valores se manejan desde el constructor.

Returns:
    Retorna el objeto con el analisis preparado. Igualmente los datos se guardan en la propiedad "analize".
=cut
sub prepare {
    my ($self) = @_;
        
    my $parser                 = SQL::Parser->new();
    $parser->{PrinteError}  = 1;
    my $query                  = SQL::Statement->new($self->statement,$parser);
    
    # Traigo la estructura base de las tablas usadas en la consulta
    my $oquery = $self->describe(@{ $query->{org_table_names} });

    # Preparo los datos para secuenciar segun la estructura de la consulta   
    my $base    = join(",", map { s/\..*$//; ( -1 == index( $_, '"' ) ) ? lc $_ : $_ } @{ $query->{org_table_names} });
    my @columns = map {$_->{value}} @{$query->column_defs()};
    my $tables  = join(",", map {$_->name} $query->tables());

    # Ojo al piojo, solución sencilla y rápida... 
	$self->database($base);
	$self->tables($tables);
    
    $oquery->{$base}->{sql}->{statement}        = $self->statement;
    $oquery->{$base}->{sql}->{params}           = $self->params;

    # sql preparado a lo bruto...
    my $sql = $self->statement;
    foreach my $p(@{$self->params}) {
      $p =~ s/\'/\\'/g;
      $sql =~ s/\?/\'$p\'/;
    }     
    $oquery->{$base}->{sql}->{prepare}          = $sql; 
    @{$oquery->{$base}->{$tables}->{fields}}    = @columns;
    
    $self->analize($oquery);
    return $oquery;
}

=item Function: execute
Description:
    Ejecuta la SQL y guarda el resultado en "analize".

Parameters:
    No recibe, los valores se manejan desde el constructor.

Returns:
    Retorna el resultado de la consulta.
=cut
sub execute {
	my ($self) = @_;
	
    my $conn = db_service_connect($self->service);
    my $sth   = $conn->prepare($self->statement);
    my @result;
    die "Error en $self->statement: " . $conn->errstr . "\n" if (!$sth || !$sth->execute(@{$self->params}));
    # TODO ahora está asumiendose un select, hay que determinar que se hace en caso de insert, update, delete.
    while (my $res = $sth->fetchrow_hashref) {
        push(@result, $res );
    }	
    my $oresult = $self->analize;
    @{$oresult->{$self->database}->{$self->tables}->{result}} = @result;
    $self->analize($oresult);
    
    return @result;
}

=item Function: setResult
Description:
    Setea el resultado que se quiere guardar.  

Parameters:
    Recibe el set de datos a almacenar.

Returns:
    No tiene retorno.
=cut
sub setResult {
    my ($self, @result) = @_;
    my $oresult = $self->analize;
    @{$oresult->{$self->database}->{$self->tables}->{result}} = @result;
    $self->analize($oresult);
    return;
}

=item Function: save
Description:
    Escribe los datos obtenidos en los archivos de salida configurados. En caso de no se hayan configurado los imprime en pantalla.

Parameters:
    Los requiere en el constructor.

Returns:
    No tiene retorno.
=cut
sub save {
    my ($self) = @_;

    $self->is_verbose = 1 if (!$self->json_file && !$self->perl_file);
    
    # Set de datos en formato perl script 
    $self->writePl($self->perl_file,$self->analize);
    
    # Set de datos en formato json 
    $self->writeJSON($self->json_file,$self->analize);
             
    return;
}

=item Function: run
Description:
    Ejecuta el prepare, execute, y save en orden. 

Parameters:
    Los toma del constructor.

Returns:
    No tiene retorno. 
    
=cut
sub run {
	my ($self) = @_;
	
	$self->prepare();
	$self->execute();
	$self->save();
	
	return;
}

=item Function: describe
Description:
    Listamos la estrutura completa de la tabla para obtener los tipos de datos soportados.

Parameters:
    Array con los nombres de las tablas. Los elemementos deben cumplir con la sintaxis "schema.table_name".

Returns:
    Retorna una referecia de hash con la estructura.    
=cut
sub describe {
    my ($self, @tables) = @_;
    my $structures;

    if (@tables > 0) { 
        my $conn   = db_service_connect('db_central');
    
        foreach my $table (@tables) {
            my $sql = "DESCRIBE $table";
            my $sth = $conn->prepare($sql);
            if (!$sth || !$sth->execute()) {
               print "Error en $sql: " . $conn->errstr . "\n";
            } else {
                my @structure;
                while (my $res = $sth->fetchrow_hashref) {
                    push(@structure, { name => $res->{Field}, type => $res->{Type}});
                }
                my @schema = $self->getSchema($table);    
                @{$structures->{$schema[0]}->{$schema[1]}->{structure}} = @structure; 
            }
        }
    }
    return $structures;
}

=item Function: writePl
Description:
    Escribe el archivo de salida en formato Perl

Parameters:
    perlfile: Nombre del archivo de salida
    oquery: Referencia con la estructura de datos a grabar

Returns:
    Vacio
=cut 
sub writePl {
    my ($self, $perlfile, $oquery) = @_; 
    
    my $operlfile = Dumper($oquery);
    $operlfile =~ s/\$VAR1\s\=/return /;
    $operlfile = "use strict;\n\n$operlfile\n\n1;\n";
    
    print $operlfile . "\n" if $self->is_verbose;   
    $self->writeFile($perlfile, $operlfile) if $perlfile;
    
    return;
};

=item Function: writeJSON
Description:
    Escribe el archivo de salida en formato JSON.

Parameters:
    jsonfile: Nombre del archivo de salida
    oquery: Referencia con la estructura de datos a grabar.

Returns:
    Vacio.
=cut 
sub writeJSON {
    my ($self, $jsonfile, $oquery) = @_; 
    
    my $json = JSON->new;
    $json = $json->pretty(1);
    $json->utf8(1);
    my $content = $json->encode($oquery);
    
    print $content . "\n" if $self->is_verbose;   
    $self->writeFile($jsonfile, $content) if $jsonfile;
    
    return;
};

=item Function: writeFile
Description:
    Escribe el archivo de salida.

Parameters:
    file: Nombre del archivo de salida
    content: String a escribir en el archivo.

Returns:
    Vacio.
=cut 
sub writeFile {
    my ($self, $file, $content) = @_;
    my $run = 1;
    
    if (-e $file) {
        print "El archivo ya existe. Desea sobre escribirlo? (s/n) \n";
        my $conf = readline(STDIN);
        chomp ($conf);
        $run = ($conf eq "s" ? 1 : 0);
    }
        
    if ($run) {
        open (OUT, ">$file");
        binmode(OUT, ":utf8");
        print OUT $content;
        close OUT;
        
        if (-e $file) {
            print "Se escribió '$file'\n";
        } else {
            print "Error: No se escribió '$file'\n";
        }   
    } else {
        print "Atención: No se sobre escribe '$file'\n";
    }
    
    return;
}

=item Function: getSchema
Description:
    Devuelve el nombre de la tabla y el schema al que pertenece la misma dividiendo la cadena por el caracter ".". Si no esta definido, en el primer elemento del array se devuelve la palabra "schema". 

Parameters:
    d: String a parsear.

Returns:
    El array con los datos obtenidos.
        
=cut 
sub getSchema {
    my ($self, $d) = @_;
    my @data = split (/\./,$d);   
    unshift(@data, 'schema') if ( @data == 1 );
    return @data;
}

no Moose;
1;
