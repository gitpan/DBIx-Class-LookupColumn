package DBIx::Class::LookupColumn;

use strict;
use warnings;

=head1 NAME

DBIx::Class::LookupColumn - A dbic component for building accessors for a lookup table.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use base qw(DBIx::Class);
use Carp qw(confess);
use Class::MOP;
use Data::Dumper;
use Smart::Comments -ENV;
use Hash::Merge::Simple qw/merge/;

use DBIx::Class::LookupColumn::Manager;




=head1 SYNOPSIS

__PACKAGE__->load_components( qw/+DBIx::Class::LookupColumn/ );

__PACKAGE__->table("user");

__PACKAGE__->add_columns(

	"user_id",	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"first_name", { data_type => "varchar2", is_nullable => 0, size => 45 },
	"last_name", { data_type => "varchar2", is_nullable => 0, size => 45 },
	"permission_type_id", { data_type => "integer", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("user_id");

__PACKAGE__->add_lookup(  'permission', 'permission_type_id', 'PermissionType' );




=head1 DESCRIPTION

This module generates a few convenient methods (accessors) for accessing data in a lookup table from an associated belongs_to table.
It plays with L<DBIx::Class::LookupColumn::Manager>.

What is meant as lookup table is a table containing some terms definition, such as PermissionType (permission_id, name) with such data 
(1, 'Administrator'; 2, 'User'; 3, 'Reader') associated 
with a client table (also called target table) such as User, whose metas might look like this : (id, first_name, last_name, permission_id).



=head1 EXPORT

add_lookup




=head1 METHODS

=head2 add_lookup

=over 4

=item Arguments: $relation_name, $foreign_key, $lookup_table, \%options?

=item Returned value: no return value.

=item Example: __PACKAGE__->add_lookup(  'permission', 'permission_type_id', 'PermissionType',
	{name_accessor => 'get_the_permission',
	name_setter   => 'set_the_permission,
	name_checker  => 'is_the_permission'
	} 
);

=back



=head1 GENERATED METHODS

=head2 $relation_name

=over 4

=item Arguments: no argument.

=item Returned value: value in the related $name_field within lookup table.

=item Example: User->find( 1 )->permission

=back




=head2 set_$relation_name

=over 4

=item Arguments: new_value related to the $field_name within the lookup table.

=item Returned value: no return value.

=item Description : set the id related to the new_value in the L<DBIx::Class::Row> object.

=item Example: User->find( 1 )->set_permission( 'Administrator' ).

=back




=head2 is_$relation_name

=over 4

=item Arguments: any value related to the $field_name within the lookup table.

=item Returned value: boolean.

=item Description : tell if the value in the lookup table as argument is true or not.

=item Example: User->find( 1 )->is_permission( 'Administrator' ).

=back


=cut




sub add_lookup {
    my ( $class, $relname, $foreign_key, $lookup_table, $options ) = @_;
    
 	#### add_lookup relation_name, foreign_key, lookup_table, options: $relation_name, $foreign_key, $lookup_table, $options
 
    # as it suggests $options is an optional argument
   	$options ||= {};
        
    my $defaults = {  
    				name_accessor => $relname,
    				name_setter   => "set_$relname",
    				name_checker  => "is_$relname",
    				field_name    => 'name',
        			}; 
    
    my $params = merge $defaults, $options;
    
    my $field_name	= $params->{field_name};
    
    my $fetch_id_by_name = sub { 
   		my ($self, $name) = @_;
   		DBIx::Class::LookupColumn::Manager->FETCH_ID_BY_NAME(  $self->result_source->schema, $lookup_table, $field_name, $name);
    };
    
    my $meta = Class::MOP::Class->initialize($class) or die;
        # test if not already present
        foreach my $method ( @$params{qw/name_accessor name_setter name_checker/} ) {
            confess "ERROR: method $method already defined"
                if $meta->get_method($method);
        }

        $meta->add_method( $params->{name_accessor}, sub {
            my $self = shift; # $self isa Row
            my $schema = $self->result_source->schema;
            return DBIx::Class::LookupColumn::Manager->FETCH_NAME_BY_ID( $schema, $lookup_table, $field_name, $self->get_column($foreign_key) );
        });
        
        
        $meta->add_method( $params->{name_setter}, sub {
            my ($self, $new_name) = @_; 
            my $schema = $self->result_source->schema;
            my $id = $fetch_id_by_name->( $self, $new_name );
            $self->set_column($foreign_key, $id);
        });
        

         $meta->add_method( $params->{name_checker}, sub {
            my ($self, $name) = @_; # $self isa Row
            my $schema = $self->result_source->schema;
            my $id = $self->get_column( $foreign_key );
            return unless defined $id;
            return $fetch_id_by_name->( $self, $name ) eq $id;
        });
}











=head1 AUTHOR

Karl Forner <karl.forner@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-lookupcolumn at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LookupColumn>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LookupColumn


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LookupColumn>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LookupColumn>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LookupColumn>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LookupColumn/>

=back




=head1 LICENCE AND COPYRIGHT

Copyright 2012 Karl Forner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms as Perl itself.

=cut

1; # End of DBIx::Class::LookupColumn
