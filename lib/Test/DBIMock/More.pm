package Test::DBIMock::More;

use 5.14.2;
use strict;
use warnings FATAL => 'all';

=head1 NAME
Test::DBIMock::More - The great new Test::DBIMock::More!
=head1 VERSION
Version 0.01
=cut
our $VERSION = '0.01';

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

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 addDataSet
	Description	:
	Params	: $datasource, 
	Returns	: None.
=cut

sub addDataSet {
	my ($self, $datasource, $formatOrOverrideBuilder) = @_;
	
	my $builderMap = {
		'.json'=> 'Test::MockDBI::DataSetBuilder::JSON',
		'.sql' => 'Test::MockDBI::DataSetBuilder::SQL',
		'.pl'=> 'Test::MockDBI::DataSetBuilder::Native',
		'.sqlite' => 'Test::MockDBI::DataSetBuilder::SQLite',
	};
	
	my $format = $builderMap->{$formatOrOverrideBuilder} || $builderMap->{($datasource =~ /(\.\w+)$/)[0]} || 'Test::MockDBI::DataSetBuilder::Native';
	
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
			$data = require($datasource);
			
			DataSetBuilder->build($data );
		} catch {
			print "NATIVE error!: $_";
		};
	}
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Gonzalo Barco, C<< <gbarco.public at cys.com.uy> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-dbimock-more at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-DBIMock-More>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::DBIMock::More


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-DBIMock-More>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-DBIMock-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-DBIMock-More>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-DBIMock-More/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Gonzalo Barco.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
