-*- encoding: utf-8; indent-tabs-mode: nil -*-

Purpose
=======

The Open Food  Facts database is a MongoDB database,  in the big realm
of no-SQL databases. A property of  no-SQL databases is that when some
data  is inserted  into  the  database, it  is  not  checked against a
pre-defined schema.  Thus, you may  have two documents  with different
structures within  the same collection  (or "table" in  SQL parlance).
This  does not  allow you  to store  any garbage  into a  collection's
documents. There is no discipline  required by the database, but there
is self-discipline voluntarily adopted by the developpers.

In the  case of Open Food  Facts, the self-discipline takes  form as a
data schema which can be read at
[this address](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas),
or as
[YAML files](https://github.com/jforget/openfoodfacts-server/tree/main/docs/api/ref/schemas)
in the local copy of the Github repository.

Yet, some infringements  to this self-discipline can  be found: traces
for a debugging session, or there  was an evolution to the data schema
and some documents were not updated to fit this evolution. The purpose
of  this  utility is  to  check  that  the documents  from  `products`
collection  match  the  data  schema  and,  if  they  fail,  list  the
differences, especially  the keys which  are not declared in  the data
schema.

The checked documents use JSON format.  They can be extracted from the
database with a query within the `mongosh` or `mongo` clients, or they
can be mass-extracted  with `mongoexport`, or an other  method.

Usage
=====

Installation
------------

You need Perl  5.38 (or later), with modules
[`YAML`](https://metacpan.org/dist/YAML/view/lib/YAML.pod),
[`YAML::Node`](https://metacpan.org/dist/YAML/view/lib/YAML/Node.pod)
and [`JSON::PP`](https://metacpan.org/pod/JSON::PP).
I briefly intended to  require `YAML::Any`, but as the
[POD documentation of this module](https://metacpan.org/dist/YAML/view/lib/YAML/Any.pod)
explains, the module is deprecated and  in the end it will be replaced
by `YAML` which will function as a `xxx::Any` module.

Your computer must have access to a local copy of the
[`openfoodfacts-server`](https://github.com/openfoodfacts/openfoodfacts-server)
repository, or of a clone.

In  the `schema-check.pl`  program,  you  need to  check  and fix  the
initial value  of the  `$dir_sch` variable,  so it  will point  to the
directory containing the YAML file describing the data schema.

Usage
-----

If the version of the system Perl is too old (less than 5.38), you must switch
to a recent version, for example with
[`perlbrew`](https://metacpan.org/dist/App-perlbrew/view/script/perlbrew).

To check the JSON documents within the file `example.txt`, enter this
command line:

```
perl schema-check.pl example.txt
```

Let us suppose the file contents is:

```
dummy line
{ "_id": "abcdef", "deliberate_error": 1 }
another dummy line
{
  "code": "ghijkl",
  "nutriments" : {
    "another_deliberate_error": 2
  }
}
a last dummy line
```

The result is:

```
--------------------------------------------------
examples/example.txt abcdef
--------------------------------------------------
invalid property deliberate_error (top)
--------------------------------------------------
examples/example.txt ghijkl
--------------------------------------------------
invalid property another_deliberate_error (top nutriments)
```

Here is what  happened. First, the program loads the  data schema into
its  memory.  Then,  the  program opens  the  `example.txt`  file  and
extracts the  JSON documents it  contains, or more exactly  what looks
like a JSON document. This can be:

* a  single-line JSON  object,  starting  at a  left  curly brace  and
stopping at a right curly brace, such as

```
        { "_id": "abcdef", "deliberate_error": 1 }
```

* a JSON  object spanning several  lines, with a  hopefully consistent
indentation, starting with  a line containing only a  left curly brace
(and nothing  else) and stopping  at a  line containing a  right curly
brace and nothing else, such as

```
        {
          "code": "ghijkl",
          "nutriments" : {
            "another_deliberate_error": 2
          }
        }
```

* a JSON  array containing  JSON objects.  This array  is laid  out on
several  lines,  the first  one  containing  only one  opening  square
bracket (and nothing  else), the last one containing  only one closing
square bracket  (and nothing  else). The layout  of the  inner objects
does not matter.

```
        [
          {
            "code": "ghijkl",
            "nutriments" : {
              "nouvelle_erreur_volontaire": 2
            }
          },
          { "_id": "abcdef", "erreur_volontaire": 1 }
        ]
```

Everything else  is ignored.  Let us  note that  the program  will not
extract  the JSON  documents with  a layout  different from  the three
layouts above. For instance, it will not extract:

```
        { "code": "ghijkl",
          "nutriments" : {
            "another_deliberate_error": 2
          }
        }
```

And it will extract a truncated document with:

```
        { "code": "ghijkl", "nutriments" : { "another_deliberate_error": 2 }
        }
```

because it considers that the curly brace ending the first line is the
brace closing the JSON document,  while actually this brace closes the
sub-document.

For each JSON object, the standard output contains:

1. a divider line,
2. a header line, with the filename and the product code,
3. another divider line,
4. the errors found by the program.

The product code  comes from either the `code` property,  or the `_id`
property. If an object contains both properties, usually they have the
same value. This is not checked.

In an  error line, you  have of course the  error label and  the wrong
value. The line contains also  a parenthesized error location, listing
the hierarchical key of the erroneous element. If you look at object
`abcdef` above, you  see that there is an error  at the document root,
since the location  is `(top)`. If you look at  object `ghijkl`, the
location  is  `(top  nutriments)`,  so the  error  occurs  within  the
`nutriments` sub-object.

If you  want a  listing of  the full data  schema (about  2000 lines),
mention this option in the command line:

```
perl schema-check.pl --schema-listing example.txt
```

In  this case,  the presence  of one  or more  filenames is  no longer
mandatory. The program will load the schema and print its description,
thus giving some information in its standard output.

Using Another Schema
--------------------

When using the data schema from the `openfoodfacts-server` repository,
you may encounter an error such as:

```
YAML Error: Expected separator '---'
   Code: YAML_PARSE_ERR_NO_SEPARATOR
   Line: 24
   Document: 2
 at /home/jf/perl5/lib/perl5/YAML/Loader.pm line 88.
```

In this case, you should fix  the error in your repository local copy,
check  the fix,  commit  it, create  a pull  request,  send this  pull
request to the OFF team, wait for the PR to be applied to the main OFF
repository and refresh your clone repository.

Or you can copy all schema files  into a local directory, fix them and
use  these files  when  checking JSON  documents. I  did  this when  I
created the  `schemas` subdirectory of this  repository. When checking
the JSON documents, the command line expands to:

```
perl schema-check.pl --schema=schemas/product.yaml example.txt
```

Do not forget to check, from time to time, whether the data schema has
evolved in the main `openfoodfacts-server` repository.

Another use of  this option is to  test a feature, by  creating a much
reduced data  schema. The feature  test does not  have to deal  with a
cumbersome complete data schema. I  did this with the `reduced-schema`
in this repository. The commande line is:

```
perl schema-check.pl --schema=reduced-schema/product_meta.yaml reduced-schema/off1
```

Where To Find Test Data
-----------------------

You can  type your  JSON test  data directly within  Vi, Emacs  or any
source editor  that fits your  needs. But  this is rather  lengthy and
error-prone.

You can download an archive which  gives the same data as the complete
OFF database. See the explanations
[on the OFF website](https://world.openfoodfacts.org/data),
especially the  "JSONL data export"  paragraph. The JSONL file  can be
processed  directly with  `schema-check.pl`.  Yet,  beware, this  file
contains more than 3  million lines for a size of 53  Gb (as of summer
2024).

Since you have a local  copy of the `openfoodfacts-server` repository,
you  also have  a test  database and  you can  extract data  from this
database and submit these data to `schema-check.pl`. Here is how to do
this.

To load the test database with data,  run one of these two commands (I
did not try to find what are the differences between these commands).

```
  make dev
  make import_sample_data
```

Then, you can use the local test instance of the web server to add new
products, if you want.

### Before 21st June 2024

Before 2024-06-21, there was a Docker service for MongoDB. Here is the
procedure  I  used   then,  from  which  I  obtained   the  test  file
`example/multiligne`.  Since my  notes are  sparse and  since I  am no
expert about Docker, there may be errors.

To extract a few documents from the  database, I use a shell buffer in
Emacs.

1. opening a shell buffer

```
        M-x shell
```

2. opening a session on the database container (the currently failing
step)

```
        docker compose exec mongodb mongo
```

3. extracting a few documents from the `products` collection, in this
case the `00187251` product and the cheese products

```
        use off
        db.products.findOne( { '_id': '00187251' } );
        db.products.find( { 'food_groups' : 'en:cheese' } )
```

4. closing the session on the container

```
        exit
```

5. saving the extracted data into a `result` file.

```
        C-x C-w result
```

6. closing the shell session and shutting the shell buffer

```
        exit
        C-x C-k
```

The test file `examples/multiligne` has been built with this procedure.

If you  want to extract the  whole `products` collection, here  is the
procedure. In  this case, there  is no benefit  to use an  Emacs shell
buffer, you can work within a xterm.

1. Extracting the database to the `/tmp` directory of the database container

```
      docker compose exec mongodb bash
      cd tmp
      mongoexport -doff -cproducts --type=json -o/tmp/products.json
      exit
```

2. reading the Docker ID for the container. Here is the command and its output

```
      $ docker ps
      CONTAINER ID   IMAGE                                   COMMAND                  CREATED         STATUS         PORTS                        NAMES
      12345678       openfoodfacts-server/frontend:dev       "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   127.0.0.1:80->80/tcp         po_off-frontend-1
      89abcdef       openfoodfacts-server/backend:dev        "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   80/tcp                       po_off-backend-1
      87654321       openfoodfacts-server/dynamicfront:dev   "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes                                po_off-dynamicfront-1
      fedcba98       openfoodfacts-server/backend:dev        "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   80/tcp                       po_off-minion-1
      babeb1b0       openfoodfacts-server/backend:dev        "/docker-entrypoint.…"   5 minutes ago   Up 5 minutes   80/tcp                       po_off-incron-1
      cacec1c0       postgres:12-alpine                      "docker-entrypoint.s…"   5 minutes ago   Up 5 minutes   5432/tcp                     po_off-postgres-1
      daded1d0       memcached:1.6-alpine                    "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes   11211/tcp                    po_off-memcached-1
      cafebabe       redis:7.2-alpine                        "docker-entrypoint.s…"   2 days ago      Up 5 minutes   127.0.0.1:6379->6379/tcp     off_shared-redis-1
      deadbeef       mongo:4.4                               "docker-entrypoint.s…"   2 days ago      Up 5 minutes   127.0.0.1:27017->27017/tcp   off_shared-mongodb-1
```

3. file transfer

```
      docker cp deadbeef:/tmp/products.json /home/jf/tmp
```

_Beware_. With either procedure (or both), some numbers are
printed in the JSON file with a type in this way:

```
NumberLong(123456789)
```

See for example property  `popularity_key` in document `"04148623"` in
file `multiligne`.

### After 21st June 2024

Since  2024-06-21,  the  Docker  service  for  MongoDB  is  no  longer
available. Also, I  updated my computer, disabling  the local instance
of MongoDB. Therefore, there is  no longer a TCP-port conflict between
the local instance and the Docker instance of MongoDB.

To extract  the full contents of  the database, you now  need a single
commande line:

```
      mongoexport -doff -cproducts --type=json -o/tmp/products.json
```

To extract a few documents, the new procedure is:

1. opening a shell buffer

```
        M-x shell
```

2. opening a session on the database

```
        mongosh
```

3. extracting a few documents from the `products` collection, in this
case the `00187251` product and the cheese products

```
        use off
        db.products.findOne( { '_id': '00187251' } );
        db.products.find( { 'food_groups' : 'en:cheese' } )
```

4. closing the session on the database

```
        exit
```

5. saving the extracted data into a `result` file.

```
        C-x C-w result
```

6. closing the shell session and the shell buffer

```
        exit
        C-x C-k
```

The test file `example/multiline` has  been generated in this fashion.
You   may   notice    that   this   file   does    not   contain   any
`NumberLong(123456789)`. Maybe  this results from using  the `mongosh`
client instead of the `mongo` client as before.

On the  other hand, as mentioned in the
[mongosh documentation](https://www.mongodb.com/docs/mongodb-shell/reference/compatibility/#object-quoting-behavior),
in a key-value pair, now the key has rarely any double-quote delimiter
and the  value is often delimited  by single quotes instead  of double
quotes. It is a partial step toward
[JSON5](https://json5.org/).
Example:

```
    _id: '0052833225082',
```

instead of

```
    "_id": "0052833225082",
```

The  solution   suggested  by  the  mongosh   documentation,  applying
`EJSON.stringify()`  to each  request,  is  cumbersome. Instead,  with
`JSON::PP`,  we  can  define  a  parser  which  accepts  keys  without
delimiters and  values with single  quote delimiters. Yet,  the parser
will still detect errors  when a single-quote-delimited value contains
double quotes. See for example property `ingredients_text_with_allergens`
in document `"5000169107829"` in file `multiline-1` :

```
    ingredients_text_with_allergens: 'Cheddar cheese (<span class="allergen">milk</span>), potato starch.',
                                                                  ..........
```

The fix consists in eliminating these inner double quotes, even if the
resulting HTML is  no longer some clean HTML. See  the fixed test file
in `examples/multiline-2`.

```
    ingredients_text_with_allergens: 'Cheddar cheese (<span class=allergen>milk</span>), potato starch.',
                                                                  ........
```

This fix is  not executed within `schema-check.pl`, you have  to do it
before submitting the file to `schema-check.pl`.

License
=======

This  documentation  is  published under  license  CC-BY-SA:  Creative
Commons with attribution and share-alike.
