# Object Properties
IncludeAllProperties and IncludeNullProperties can be used to further explore AD object properties.

## IncludeAllProperties
This does exactly what it sounds like it would do, includes all properties returned for an object. The thing is, this only returns populated properties. This is the default behavior for the AD searcher.

## IncludeNullProperties
This will also include properties that have no value assigned but are legal (according to the schema) for the returned object. These are derived from the schema definitions which are stored in a lookup table for each LDAP object category you query in this manner. This reduces processing and load on the domain controllers significantly for every other query after the first.

**Example 1 - Return all possible user properties for jdoe**

`get-dsobject jdoe -IncludeAllProperties -IncludeNullProperties`

This includes everything that the schema says we can assign to a user.

**Example 2 - Return extensionattribute9, even if it is not assigned**

`get-dsobject jdoe -IncludeNullProperties -Properties 'extensionattribute9'`

**Example 3 - Query for extensionattribute900, and get nothing**

`get-dsobject jdoe -IncludeNullProperties -Properties 'extensionattribute900'`

As the property doesn't exist for the objectClass we queried, nothing is returned.

**Example 4 - Query for all assigned properties of jdoe**

`get-dsobject jdoe -IncludeAllProperties -Properties 'extensionattribute900'`

Even if you send additional properties it will not matter, all assigned properties will be returned.
