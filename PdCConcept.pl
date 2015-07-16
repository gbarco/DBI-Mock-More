#!/usr/bin/env perl -w
package LAN::DevTools::Mock::DBI;
use strict;
use utf8;
use Moose;
use Try::Tiny;

require DBI;
require DBD::SQLite;

use Data::Dumper;

has 'dbh' => (
	isa => 'DBI::db',
	is => 'ro',
	reader => 'getDbh',
	default => sub {
		my $dbh  = DBI->connect('dbi:SQLite::memory:','','');
		$dbh->do("PRAGMA synchronous = OFF");
		$dbh->do("PRAGMA cache_size = 1048576");
		return $dbh;
	},
);

has 'data' => (
	isa => "HashRef",
	is  => "rw",
	reader => 'getData',
	writer => 'setData',
	default => sub { return {} },
);

LAN::DevTools::Mock::DBI::test();

sub test {
	my $mock = LAN::DevTools::Mock::DBI->new();
	my $dbh = $mock->getDbh;
	
	$mock->mock('conceptTestSQLiteDataSet1.pl');
	
	print 'Schemas: ' . join(', ', @{$mock->getSchemas}) . "\n";
	#my $result = $mock->schemaSerialization;
	#print Data::Dumper::Dumper( $result );
	
	my $result = $dbh->selectall_arrayref("SELECT * FROM sessions.user;");
	print Data::Dumper::Dumper( $result );
	$result = $dbh->selectall_arrayref("SELECT * FROM booking_engine_var.ventas;");
	print Data::Dumper::Dumper( $result );
	
	$result = $dbh->selectall_arrayref("SELECT * FROM booking_engine_var.ventas JOIN sessions.user USING (session_id);");
	print Data::Dumper::Dumper( $result );
	
	$result = $dbh->selectall_arrayref("SELECT * FROM booking_engine_var.ventas JOIN sessions.user USING (session_id);");
	
	my $sth = $dbh->prepare("SELECT * FROM booking_engine_var.ventas JOIN sessions.user USING (session_id);");
	$sth->execute();
	while ( $result = $sth->fetchrow_hashref() ) {
		print Data::Dumper::Dumper( $result );
	}
	
	$result = $dbh->selectall_arrayref("SELECT * FROM booking_engine_var.ventas JOIN sessions.user USING (session_id);", {Slice => {}});
	print Data::Dumper::Dumper( $result );
}

sub mock {
	my ($self, $datasource, $format) = @_;
	
	my $formatGuesser = {
		'.json'=> 'JSON',
		'.sql' => 'SQL',
		'.pl'=> 'NATIVE',
		'.sqlite' => 'SQLITE',
	};
	
	$format = $format || $formatGuesser->{($datasource =~ /(\.\w+)$/)[0]} || 'NATIVE';
	
	my $data;
	if ($format eq 'JSON') {
		require JSON;
		try {
			my $json = require($datasource);
			$data = JSON::to_json($json);
		} catch {
			print "JSON error!";
		}
	} elsif ($format eq 'NATIVE') {
		try {
			my $dbh = $self->getDbh;
			$data = require($datasource);
			
			DataSetBuilder->build($data );
			#foreach my $schema (keys %$data) {
			#	$dbh->do("ATTACH DATABASE ':memory:' AS '$schema'") or die $dbh->errstr;
			#	foreach my $table (keys %{$data->{$schema}}) {
			#		my $createFields = join(', ', map(join(' ', $_, $data->{$schema}{$table}{fields}{$_}), keys(%{$data->{$schema}{$table}{fields}})));
			#		
			#		$dbh->do("DROP TABLE IF EXISTS '$schema.$table'");
			#		$dbh->do("CREATE TABLE '$schema'.'$table' ($createFields)") or die $dbh->errstr;
			#		foreach my $row (@{$data->{$schema}{$table}->{data}}) {
			#			my $fields = join(', ', keys $row);
			#			my $values = join(', ', map($dbh->quote($_), values($row)));
			#
			#			$dbh->do("INSERT INTO '$schema'.'$table' ($fields) VALUES ($values)") or die $dbh->errstr;
			#		}
			#	}
			#}
		} catch {
			print "NATIVE error!: $_";
		};
	}
	
	#LAN::DevTools::Mock::DBI->setData($data) if ($data);
}

=item schemaSerialization
	Description: Returns a list of arrays with indexed open databases (i.e. schemas)
	Parameters: $self should be a reference to a LAN::DevTools::Mock::DBI
	Returns: ARRAYREF of ARRAYREF [[database_index,database_name,filename_or_undef_for_memory]]
	Call convention: $obj->schemaSerialization
=cut
sub schemaSerialization {
	my ($self) = @_;

	return $self->getDbh->selectall_arrayref("PRAGMA database_list;");
}

=item schemaSerialization
	Description: Returns a list of schemas
	Parameters: $self should be a reference to a LAN::DevTools::Mock::DBI
	Returns: ARRAYREF of SCALAR ['main','temp','booking_engine_var']
	Call convention: $obj->getSchemas
=cut
sub getSchemas {
	my ($self) = @_;
	
	my $sth = $self->getDbh->table_info('', '%', '');
	return $self->getDbh->selectcol_arrayref($sth, {Columns => [2]});
}

sub sqlImport {
	sub exec_sql_file {
    my ($dbh, $file) = @_;

    my $sql = do {
        open my $fh, '<', $file or die "Can't open $file: $!";
        local $/;
        <$fh>
    };

    $dbh->do("BEGIN $sql END;");
	}
	sub get_sql_from_file {
    open my $fh, '<', shift or die "Can't open SQL File for reading: $!";
    local $/;
    return <$fh>;
	};
	my $dbh1;

	my $SQL = get_sql_from_file("SQL/file_which_holds_sql_statements.sql");
	my $sth1 = $dbh1->prepare($SQL);
	$sth1->execute();
}

no Moose;
__PACKAGE__->meta->make_immutable();

package LAN::DevTools::Mock::DBI::DataSetBuilder;

use Moose;

sub build {
	my ( $self, $data) = @_;
	my $dbh = $self->getDbh;
			
	foreach my $schema (keys %$data) {
		createSchema({}, $schema);
		foreach my $table (keys %{$data->{$schema}}) {
			createTable({},$schema, $table, $data);
			foreach my $row (@{$data->{$schema}{$table}->{data}}) {
				insertRow({}, $schema, $table, $data, $row);
			}
		}
	}
}

sub serialize {
}

sub createSchema {
	my ($self, $options, $schema) = @_;
	my $dbh = $self->getDbh;
	
	$dbh->do("ATTACH DATABASE ':memory:' AS '$schema'") or die $dbh->errstr;
}

sub createTable {
	my ($self, $options, $schema, $table, $data) = @_;
	
	my $createFields = join(', ', map(join(' ', $_, $data->{$schema}{$table}{fields}{$_}), keys(%{$data->{$schema}{$table}{fields}})));
	
	my $dbh = $self->getDbh;
	$dbh->do("DROP TABLE IF EXISTS '$schema.$table'") or die $dbh->errstr;
	$dbh->do("CREATE TABLE '$schema'.'$table' ($createFields)") or die $dbh->errstr;
}

sub insertRow {
	my ($self, $options, $schema, $table, $data, $row) = @_;
	
	my $dbh = $self->getDbh;
	
	my $fields = join(', ', keys $row);
	my $values = join(', ', map($dbh->quote($_), values($row)));

	$dbh->do("INSERT INTO '$schema'.'$table' ($fields) VALUES ($values)") or die $dbh->errstr;
}

no Moose;
__PACKAGE__->meta->make_immutable();


package LAN::DevTools::Mock::DBI::DataBuilderNative;
use Moose;
extends 'LAN::DevTools::Mock::DBI::StorageFormat';

no Moose;
__PACKAGE__->meta->make_immutable();



