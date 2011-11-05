# Cushion

A HashWithIndifferentAccess with a CouchDB persistence layer.

## Synopsis

Using Cushion is as simple as this:

    hash = Cushion.new('/db/document')
    hash.load
    hash[:foo] = 'bar'
    hash.save

When the document's URI consists only of the database part (`/db`), the id will be a UUID, set by CouchDB on `.save`.

Cushion can also be inherited from, which will lead to the database name being taken from the inheriting classes name. Like this:

    class MyCushion < Cushion; end
    hash = MyCushion.new
    hash.save

In this case a document URI doesn't have to be given explicitly (even though, it can be given). For the above example, the URI would be `/my_cushions/<UUID set by CouchDB>`.


