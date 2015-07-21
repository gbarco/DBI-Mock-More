package Test::MockDBI::More::DataSetBuilder;

use 5.14.2;
use strict;
use utf8;
use warnings FATAL => 'all';

=head1 NAME
Test::DBIMock::More::DataSetBuilder - Base class for DataSetBuilder implementations.
=head1 VERSION
Version 0.01
=cut
our $VERSION = '0.01';

# OO implemented with Moose
use Moose;
use Try::Tiny;

# Debug module
use Data::Dumper;

=head1 SYNOPSIS

	my $dbiMock = Test::DBIMock::More->new();
	$mock->addDataSet('t/DataSet1.pl');
	$mock->addDataSet('t/DataSet2.json');
	
	print 'Schemas: ' . join(', ', @{$mock->getSchemas}) . "\n";
	
	$result = $dbh->selectall_arrayref("SELECT * FROM schema1.sales JOIN schema2.users USING (session_id);");
	if (ref $result eq 'ARRAYREF') {
		foreach $row (@$$result) {
			print join(', ', values(%$row));
		}
	}
=cut

=head1 ATTRIBUTES
	dbh
	data
=cut

has 'dbh' => (
	isa => 'DBI::db',
	is => 'ro',
	reader => 'getDbh',
	default => &initialize,
);

has 'data' => (
	isa => "HashRef",
	is  => "rw",
	reader => 'getData',
	writer => 'setData',
	default => sub { return {} },
);

=head1 SUBROUTINES/METHODS

=head2 addDataSet
	Description	: Adds a dataset comprising one or more schemas to the internal representation. 
	Params	: $datasource, 
	Returns	: None.
=cut

sub initialize {
	my $dbh  = DBI->connect('dbi:SQLite::memory:','','');
	$dbh->do("PRAGMA synchronous = OFF");
	$dbh->do("PRAGMA cache_size = 1048576");
	return $dbh;
}

=head2 build
	Description	: Generic dataset building algorithm
	Params	: HASHREF $data, data to include within the representation. Format documented in C</"DATASET FORMAT">
	Returns	: None.
=cut

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

=item getSchemas
	Description: Returns a list of schemas
	Parameters: $self should be a reference to a Test::MockDBI::More::DataSetBuilder
	Returns: ARRAYREF of SCALAR ['main','temp','booking_engine_var']
	Call convention: $obj->getSchemas
=cut

sub getSchemas {
	my ($self) = @_;
	
	my $sth = $self->getDbh->table_info('', '%', '');
	return $self->getDbh->selectcol_arrayref($sth, {Columns => [2]});
}

=head1 DATASET FORMAT

=head2 SYNOPSIS
	B<schema> => {
		B<table> => {
			B<fields> => {
				B<field> => sqlFormat
			},
			B<result> => [
				{B<field>=>B<value>},
				...
				{B<field>=>B<value>},
			],
		},
	},

=head2 schema
	B<schema> is a HASHREF which contains keys representing table names. The actual key value defines the name of one schema.
=head2 table
	B<table> is a HASHREF which contains the keys B<fields> and B<result>. The actual key value defines the name of one table.
=head2 fields
	B<fields> is a HASHREF which contains keys representing fields in the given schema and table. Values represente SQL field format.
=head2 result
	B<result> is an ARRAYREF which contains elements representing rows in a given schema and table.
=head2 field
	B<field> is a SCALAR whose value should match a field key in the schema->table->fields HASHREF. Its value defines the value of the field in a given row.
=head2 value
	B<value> is a SCALAR whose value defined the value of the field in a given row.
	
=cut

1;
