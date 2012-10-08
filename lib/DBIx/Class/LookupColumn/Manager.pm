package DBIx::Class::LookupColumn::Manager;

use strict;
use warnings;

=head1 NAME

DBIx::Class::LookupColumn::Manager - A lazzy dbic component caching queries.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use Carp qw(confess);
use Data::Dumper;
use Smart::Comments -ENV;

my %CACHE; # main class variable containing all cached objects




=head1 SYNOPSIS

use DBIx::Class::LookupColumn::Manager;
DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME(  $schema, 'Permission', 'name', 'Administrator' );



=head1 DESCRIPTION

This module does DBIx::Class queries by means of arguments you passed by and stores the result in a nested hashing data structure (cache).
It does a DBIx::Class query if and only if that one is not yet stored in the cache (lazziness).

This module only supports tables having only one single primary key.

The module closely works with the L<DBIx::Class::LookupColumn> package which generates a few convenient methods (accessors) for accessing data in a lookup table from an associated belongs_to table. 
What is meant as lookup table is a table containing some terms definition, such as PermissionType (permission_id, name) with such data (1, 'Administrator'; 2, 'User'; 3, 'Reader') associated 
with a client table (also called target table) such as User, whose metas might look like this : (id, first_name, last_name, permission_id).
Though the module could also be used in an independently way.




=head1 EXPORT

FETCH_ID_BY_NAME

FETCH_NAME_BY_ID

RESET_CACHE

RESET_CACHE_LOOKUP_TABLE




=head1 METHODS

=head2 FETCH_ID_BY_NAME

=over 4

=item Arguments: $schema, $lookup_table, $field_name, $name.

=item Returned value: id in the lookup table.

=item Description : get the id stored in the lookup table for both the column and its value passed by argument.

=item Example: DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME( $schema, 'Permission', 'name', 'Administrator' ).

=back




=head2 FETCH_NAME_BY_ID

=over 4

=item Arguments: $schema, $lookup_table, $field_name, $id.

=item Returned value: the value of the $field_name in the lookup table.

=item Description : get the value stored in the lookup table for the column and the id passed by argument.

=item Example: DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID( $schema, 'Permission', 'name', 1 ).

=back




=head2 RESET_CACHE

=over 4

=item Arguments: no argument.

=item Returned value: no returned value.

=item Description: reset the whole nested hashing data structure.

=item Example: DBIx::Class::LookupColumn::Manager->RESET_CACHE.

=back




=head2 RESET_CACHE_LOOKUP_TABLE

=over 4

=item Arguments: name of the table whose data are stored in the cache.

=item Returned value: no returned value.

=item Description: reset the hashing whose key is the table's name argument.

=item Example: DBIx::Class::LookupColumn::Manager->RESET_CACHE_LOOKUP_TABLE('Permission').

=back




=head2 _ENSURE_LOOKUP_IS_CACHED

=over 4

=item Description: carries about doing a query if and only if that one is not yet stored in the cache. For internal use.

=back




=head2 _GET_CACHE

=over 4

=item Description: only for test purpose.

=back




=cut

sub FETCH_ID_BY_NAME {
    my ( $class, $schema, $lookup_table, $field_name, $name ) = @_;
	confess "Bad args" unless defined $name;
    my $cache	= $class->_ENSURE_LOOKUP_IS_CACHED(  $schema, $lookup_table, $field_name );
    my $id		= $cache->{name2id}{$name} or confess "name [$name] does not exist in (cached) Lookup table [$lookup_table]";
    return $id;
}




sub FETCH_NAME_BY_ID {
    my ( $class, $schema, $lookup_table, $field_name, $id ) = @_;
	confess "Bad args" unless defined $id;
    my $cache	= $class->_ENSURE_LOOKUP_IS_CACHED( $schema, $lookup_table, $field_name );
    my $name	= $cache->{id2name}{$id} or confess "Bad type_name [$id] in Lookup table [$lookup_table]";
    return $name;
}




sub _ENSURE_LOOKUP_IS_CACHED {
    my ( $class, $schema, $lookup_table, $field_name ) = @_;
	
	# check the table and field names
	my $source_table = $schema->source( $lookup_table ) or confess "unknown table called $lookup_table";
    confess "the $field_name as field name does not exist in the $lookup_table lookup table" 
    	unless $source_table->has_column( $field_name );
		
    #### _ENSURE_LOOKUP_IS_CACHED: $lookup_table, $field_name
 
    unless ( $CACHE{$lookup_table} ) {
		$CACHE{$lookup_table} = {};
		
		# get primary key name         
        my @primary_columns = $schema->source( $lookup_table )->primary_columns;
        confess "Error, no primary defined in lookup table $lookup_table" unless @primary_columns;
        confess "we only support lookup table with ONE primary key for table $lookup_table" if @primary_columns > 1; 
        my $primary_key = shift @primary_columns;
        
       	# query for feching all (id, name) rows from lookup table
        my $rs = $schema->resultset($lookup_table)->search( undef, { select=>[$primary_key, $field_name] });
		
		my ($id, $name);
		my $id2name = $CACHE{$lookup_table}{id2name} ||= {};
		my $name2id = $CACHE{$lookup_table}{name2id} ||= {};
		my $cursor =  $rs->cursor;
		# fetch all and fill the cache
		while ( ($id, $name) = $cursor->next ){
			$id2name->{$id} = $name;
			$name2id->{$name} = $id;
		}
    }
    return $CACHE{$lookup_table};
}




sub RESET_CACHE {
	my ( $class ) = @_;
    %CACHE = ();
}




sub RESET_CACHE_LOOKUP_TABLE {
	my ( $class, $lookup_table ) = @_;
    delete $CACHE{$lookup_table};
}


sub _GET_CACHE{
	my ( $class ) = @_;
	return \%CACHE;
}




=head1 AUTHOR

Karl Forner <karl.forner@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-lookupcolumn-manager at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LookupColumn-Manager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LookupColumn::Manager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LookupColumn-Manager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LookupColumn-Manager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LookupColumn-Manager>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LookupColumn-Manager/>

=back



=head1 LICENCE AND COPYRIGHT

Copyright 2012 Karl Forner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms as Perl itself.

=cut

1; # End of DBIx::Class::LookupColumn::Manager
