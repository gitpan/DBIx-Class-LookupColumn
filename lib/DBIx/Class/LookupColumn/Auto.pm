package DBIx::Class::LookupColumn::Auto;

use strict;
use warnings;

=head1 NAME

DBIx::Class::LookupColumn::Auto - A dbic component for detecting lookup tables within a schema and adding accessors to all L<DBIx::Class::ResultSource> classes.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use base qw(DBIx::Class);

use Data::Dumper;
use Smart::Comments -ENV;
use Hash::Merge::Simple qw/merge/;

use DBIx::Class::LookupColumn;


=head1 SYNOPSIS

__PACKAGE__->load_components( qw/+DBIx::Class::LookupColumn::Auto/ );

my @tables = __PACKAGE__-> sources;

__PACKAGE__->add_lookups(
	targets => [ grep { ! /Type$/ } @tables ],
	lookups => [ grep {   /Type$/ } @tables ],
	
	options => {
		relation_name_builder => sub{
			my ( $class, %args) = @_;
			
			$args{lookup} =~ /^(.+)Type$/;
			lc( $1 );
		},
		lookup_field_name => sub{
			'name';	
		}
	}
);






=head1 DESCRIPTION

This module generates a few convenient methods (accessors) for a whole schema's client tables. It makes use of L<DBIx::Class:LookupColumn>. 

What is meant as lookup table is a table containing some terms definition, such as PermissionType (permission_id, name) with such data (1, 'Administrator'; 2, 'User'; 3, 'Reader') associated 
with a client table (also called target table) such as User, whose metas might look like this : (id, first_name, last_name, permission_id).

It is also possible to add accessors in a non-automated way by doing a copy/paste of the code diplayed when verbose is true (See L<add_lookups>).



=head1 EXPORT

add_lookups




=head1 METHODS

=head2 add_lookups

=over 4

=item Arguments: \@target_tables, \@lookup_tables, \%options?

=item Returned value: no return value.

=item Options: 1) func ref for building the accessors' name. 2) func ref for giving the name of the related column in the lookup table. 3) verbose => bolean, displays code to add manually to each L<DBIx::Class::ResultSource> classes.

=item Description: create the methods (accessors) to all client classes whose name is passed as argument.

=item Example: User->find( {last_name => 'uchiwa'} )->permission.



=back




=head2 _target2lookups

=over 4

=item Description: Build a nested hashing. For internal use.

=back



=head2 _guess_relation_name

=over 4

=item Description: Find out by default the appropriate relation name for building the accessors. For internal use.

=back




=head2 _guess_field_name

=over 4

=item Description: Find out by default the appropriate column in the lookup table. For internal use.

=back





=cut


sub _target2lookups {
	my ( $class, $targets_array_ref, $lookups_array_ref ) = @_;
	
	my %lookups = map { ($class->class( $_ ), $_) } @$lookups_array_ref;
	
	my %relationships;
	foreach my $target ( @$targets_array_ref ) {
		#### processing target table: $target		        
		my $target_class = $class->class( $target );
		
		foreach my $rel ($target_class->relationships) {
			#### processing relation : $rel
			my $info = $target_class->relationship_info($rel);
			
			#### relationship_info:  $info
			
			next unless exists $lookups{$info->{source}};  # is the relation to a lookup
			
			my @fk_columns = keys %{$info->{attrs}->{fk_columns}};
			next if @fk_columns > 1; # if multiple foreign keys, not a belongs_to ?
			
			unless (@fk_columns) {
				### skipping relation because there is no foreign key, for table and relation:  $target, $rel
				next;
			}
			my $fk = shift @fk_columns; 
			 
			next unless $info->{attrs}->{accessor} eq 'single'; # heuristic to detect belongs_to relation
			
			$relationships{$target}->{$fk} = $lookups{$info->{source}};
		}	
	}
	
	return \%relationships;
}




sub _guess_relation_name{
	my ( $class, %args ) = @_;
	return lc( $args{lookup});
}


  

sub _guess_field_name {
	my ( $class, %args ) = @_;
	
	my $schema	= $class;
	my $lookup	= $args{lookup};
	
	my @columns = $schema->source( $lookup )->columns;
	my @primary_columns = $schema->source(  $lookup )->primary_columns;
	my @columns_without_primary_keys = grep{ !($_ ~~ @primary_columns) }  @columns;
	my $guessed_field;
	
	# classic lookup table with only two columns
	if ( @columns == 2 && @columns_without_primary_keys == 1){
		$guessed_field = shift @columns_without_primary_keys; 
	}
	# lookup table with more than two columns
	else{
		foreach my $column ( @columns_without_primary_keys ){
			my $column_metas = $schema->source( $lookup )->column_info( $column );
			
			if ( $column_metas->{data_type} =~ /(varchar|text)/ ){
				#select the first varchar column 
				$guessed_field = $column;
				last;
			 }
		}
	}
	return $guessed_field;
}




sub add_lookups {
    my ( $class, %args ) = @_;
    
    my $targets_array_ref	= $args{targets};
    my $lookups_array_ref	= $args{lookups};    
    
    my $options = $args{options} || {};
    
    my $defaults = {  
    				relation_name_builder => \&_guess_relation_name,
    				lookup_field_name  => \&_guess_field_name,
    				verbose => 0
        			}; 

	my $params = merge $defaults, $options;

	my $verbose = $params->{verbose};
	
    my $target2lkp_hash_ref = $class->_target2lookups( $targets_array_ref,  $lookups_array_ref );
    
    #### target2lookups returned: $target2lkp_hash_ref
    
    my ( $target, $fk2lkp_hash_ref);
    while ( ( $target, $fk2lkp_hash_ref ) = each ( %$target2lkp_hash_ref ) ) {
    	 if($verbose) {
 			warn "adding to package $target\n";
 			warn "__PACKAGE__->load_components(+DBIx::Class::LookupColumn)\n";
    	 }
 		foreach my $fk (keys %$fk2lkp_hash_ref) {
 			
 			my $lookup = $fk2lkp_hash_ref->{$fk};
 		
 			my @args = (
 				$params->{relation_name_builder}->( $class, target => $target, lookup => $lookup, foreign_key => $fk ),
 				$fk, $lookup, 
 				{
							field_name => $params->{lookup_field_name}->( $class, target => $target, lookup => $lookup, foreign_key => $fk )
				}
			);

  			if($verbose) {
 				my $s = Dumper(\@args);
 				$s =~ s/^[^\[]*\[(.+)\];.*/$1/s;
 				warn "__PACKAGE__->add_lookup($s)\n" ;
 			}
			DBIx::Class::LookupColumn::add_lookup( $class->class( $target), @args );
 		}
    }
}







=head1 AUTHOR

Karl Forner <karl.forner@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-lookupcolumn-auto at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-LookupColumn-Auto>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::LookupColumn::Auto


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-LookupColumn-Auto>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-LookupColumn-Auto>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-LookupColumn-Auto>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-LookupColumn-Auto/>

=back



=head1 LICENCE AND COPYRIGHT

Copyright 2012 Karl Forner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms as Perl itself.

=cut

1; # End of DBIx::Class::LookupColumn::Auto
