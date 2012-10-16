Description
--------------

This distribution written in Perl provides some convenient methods (accessors) to table classes
on the top the DBIx::Class (object relational-mapping).

Terminology
---------------

What is meant as a lookup table is a table containing some terms definition, such as PermissionType (permission_id, name) with such data 
(1, 'Administrator'; 2, 'User'; 3, 'Reader') associated 
with a client table (also called target table) such as User, whose metas might look like this : (id, first_name, last_name, permission_id).


Functionality
---------------

The three major functionalities this present distro offer are :

* generates accessors to table classes for fectching data stored in the associated lookup table. 
* manages a cache system which does one query to the DB if and only if that one is not yet stored in the cache (lazziness).
* automatizes the accessors' generating form a whole DB schema.  