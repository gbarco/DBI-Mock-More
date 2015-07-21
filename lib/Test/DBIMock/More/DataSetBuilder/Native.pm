package Test::MockDBI::More::DataSetBuilder::Native;

use 5.14.2;
use strict;
use utf8;
use warnings FATAL => 'all';

=head1 NAME
Test::DBIMock::More::DataSetBuilder::Native - Implements "Native" dataset format as interpreted by require by the Perl interpreter.
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

	my $datasetReader = Test::DBIMock::More::DataSetBuilder::Native->new();
	$datasetReader->build('t/DataSet1.pl');

=cut

extends 'Test::MockDBI::More::DataSetBuilder';

=head1 ATTRIBUTES
	Inherits from L<Test::MockDBI::More::DataSetBuilder>
=cut

=head1 SUBROUTINES/METHODS
	Inherits from L<Test::MockDBI::More::DataSetBuilder>

=cut

=head1 createSchema
	Description: 
=cut

sub createSchema {
	my ($self, $options, $schema) = @_;
	my $dbh = $self->getDbh;
	
	$dbh->do("ATTACH DATABASE ':memory:' AS '$schema'") or die $dbh->errstr;
}

=head1 createTable
=cut

sub createTable {
	my ($self, $options, $schema, $table, $data) = @_;
	
	my $createFields = join(', ', map(join(' ', $_, $data->{$schema}{$table}{fields}{$_}), keys(%{$data->{$schema}{$table}{fields}})));
	
	my $dbh = $self->getDbh;
	$dbh->do("DROP TABLE IF EXISTS '$schema.$table'") or die $dbh->errstr;
	$dbh->do("CREATE TABLE '$schema'.'$table' ($createFields)") or die $dbh->errstr;
}

=head1 insertRow
=cut

sub insertRow {
	my ($self, $options, $schema, $table, $data, $row) = @_;
	
	my $dbh = $self->getDbh;
	
	my $fields = join(', ', keys $row);
	my $values = join(', ', map($dbh->quote($_), values($row)));

	$dbh->do("INSERT INTO '$schema'.'$table' ($fields) VALUES ($values)") or die $dbh->errstr;
}

=head1 DATASET FILE FORMAT

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
	
=head2 EXAMPLE
		users => {
			sessions => {
				fields => {
					session => TEXT,
					status => INTEGER,
				},
				result => [
					{ session=>'xy1', status=>1 },
					{ session=>'xy2', status=>0 },
				]
			},
			status => {
				fields => {
					status => INTEGER,
					description  => TEXT,
				},
				result => [
					{ status=>0, description=>'normal' },
					{ status=>1, description=>'locked' },
				]
			},
		}
	
=cut

no Moose;
__PACKAGE__->meta->make_immutable();

1;