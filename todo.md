# Todo

1. Support for child classes inheriting PostJson::Document.
Foreign key for collection has to be 'text'. This way default_scope for the child class can have a condition, where foreign key should equal the class name.

A dynamic collection (with no class representing it) should have the name as a primary key. This will allow the scope to use the same for matching documents.

Accessing documents through the collection class should not require a collection record to exists. This will allow work on documents, if child class has been removed or deleted.

Settings should be used from child class if it exists (constanize the foreign key and read the class attributes). Otherwise work (create or update) on documents should create the collection record with the default settings.
