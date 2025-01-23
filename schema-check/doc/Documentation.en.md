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
[`YAML::XS`](https://metacpan.org/dist/YAML-LibYAML/view/lib/YAML/XS.pod),
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
perl schema-check.pl --schema=schemas/schemas/product.yaml example.txt
```

or:

```
perl schema-check.pl --list-schema --schema=schemas/schemas/product.yaml exemple.txt
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

Actually, as
[explained below](#user-content-implicit-fields),
you can merge several schema files.

```
perl schema-check.pl --schema=schemas/schemas/product.yaml --schema=schemas/schemas/product_hidden.yaml exemple.txt
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

6. closing the shell session and closing the Emacs buffer for the shell

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

Schema Description
==================

Warning
-------

In the following,  you will find the descrition of  the data schema in
_incremental_  fashion. Since  this  description  is incremental,  the
first steps will  be incomplete and even contradicted  by later steps.
Anyhow, this progression will allow  you, I hope, to understand better
and easier how we define a data schema.

Also, I do not  use the current description of the  data schema in the
documentation. On 21 october 2024, there was an overhaul of the schema
source files. This overhaul aimed at increasing the maintainability or
the power of the data schema, but it increased its complexity. So, for
pedagogical reasons, the description below  will refer to the state of
the schema before  21 October 2024. For practical  reasons in addition
to pedagogical reasons, I use  the version from 2024-10-04, before the
application of a pull request I submitted (applied on 2024-10-11). The
pedagogical version  of the  schema can be  found in  the `old-schema`
directory in this repository.

First Step
----------

The data schema is defined in file `product.yaml` within sub-directory
`docs/api/ref/schemas` of  the Git repository. The  2024-10-04 content
of  this  sub-directory  has  been  copied, with  a  few  fixes,  into
sub-directory `old-schema` within the  present repository. The current
version (post  2024-10-21) is copied into  sub-directory `schemas`. If
we remove the documentary label, the file contents is:

```
type: object
allOf:
  - $ref: './product_base.yaml'
  - $ref: './product_misc.yaml'
  - $ref: './product_tags.yaml'
  - $ref: './product_images.yaml'
  - $ref: './product_ecoscore.yaml'
  - $ref: './product_ingredients.yaml'
  - $ref: './product_nutrition.yaml'
  - $ref: './product_quality.yaml'
  - $ref: './product_extended.yaml'
  - $ref: './product_meta.yaml'
  - $ref: './product_knowledge_panels.yaml'
```

The first  line (`type: object`)  tells us that  a document is  a JSON
object,  beginning with  an  open brace,  including several  key-value
pairs and ending with a closing brace. But what is allowed and what is
forbidden within  these key-value pairs?  When reading the  YAML file,
you  guess easily  that you  have to  read other  YAML files,  keyword
`$ref`  acting as  keyword `#include`  in C  and keyword  `require` in
Perl.

The `$ref` keyword is used 12  times in file `product.yaml`, but it is
used also in the other files. All in all, it appears 52 times, with 49
file inclusions and 3 times for another mechanism.

Key-Value Pairs
---------------

Here is an extract of file `product_base.yaml`.

```
type: object
description: |
  Base product data
properties:
  abbreviated_product_name:
    type: string
    description: Abbreviated name in requested language
  code:
    type: string
    description: |
      barcode of the product (can be EAN-13 or internal codes for some food stores),
      for products without a barcode,
      Open Food Facts assigns a number starting with the 200 reserved prefix
  nova_group:
    type: integer
    description: |
      Nova group as an integer from 1 to 4. See https://world.openfoodfacts.org/nova
  product_name:
    type: string
    description: |
      The name of the product
  product_name_en:
    type: string
    description: |
      The name of the product can also
      be in many other languages like
      product_name_fr (for French).
  product_quantity:
    type: string
    description: |
      The size in g or ml for the whole product.
      It's a normalized version of the quantity field.
    example: "500"
```

This extract describes, for example, this document:

```
{
        "code" : "00187251",
        "product_name_en" : "choclatey cats",
        "nova_group" : 4,
        "product_name" : "choclatey cats",
        "product_quantity" : 453.59237
}
```

As you  can see in  this example, the keys  are optional, such  as key
`abbreviated_product_name` which  is missing from the  document above.
Also, the order of the  keys is not significant. Key `product_name_en`
appears after keys  `nova_group` and `product_name` in  the schema and
before them in the document.

This example brings another question, checking the values in key-value
pairs.  For data  `product_quantity`, the  expected data  format is  a
string, yet  the example gives a  float number. Is this  an error that
needs to be reported to the OFF team? Or is this specification nothing
more than a hint?

Generic Keys
------------

Let us take a look at file `product_ingredients.yaml`.

```
type: object
description: Fields about ingredients of a product
properties:
  ingredients_text:
    type: string
  ingredients_text_with_allergens:
    type: string
patternProperties:
  'ingredients_text_(?<language_code>\w\w)':
    type: string
    description: |
      Raw list of ingredients in language given by 'language_code'.

      See `ingredients_text`
  'ingredients_text_with_allergens_(?<language_code>\w\w)':
    description: |
      Like `ingredients_text_with_allergens` for a particular language
    type: string
```

This describes the document below (an excerpt from  document `00187251`):

```
{
        "ingredients_text_en" : "unbleached enriched flour ( wheat  flour, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, soy lecithin (an emulsifier), contain  wheat , soy, may contain traces of peanuts and tree nuts,",
        "ingredients_text_with_allergens_en" : "unbleached enriched flour ( <span class=\"allergen\">wheat  flour</span>, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, <span class=\"allergen\">soy lecithin</span> (an emulsifier), contain  wheat , <span class=\"allergen\">soy</span>, may contain traces of <span class=\"allergen\">peanuts</span> and <span class=\"allergen\">tree nuts</span>,",
        "ingredients_text_with_allergens" : "unbleached enriched flour ( <span class=\"allergen\">wheat  flour</span>, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, <span class=\"allergen\">soy lecithin</span> (an emulsifier), contain  wheat , <span class=\"allergen\">soy</span>, may contain traces of <span class=\"allergen\">peanuts</span> and <span class=\"allergen\">tree nuts</span>,",
        "ingredients_text" : "unbleached enriched flour ( wheat  flour, niacin, reduced iron, thiamine mononitrate, riboflavin, folic acid), sugar, defatted cocoa powder (processed with alkali), invert syrup, palm oil, whole wheat flour, natural flavour, sodium bicarbonate, salt, vegetable mono and diglycerides, soy lecithin (an emulsifier), contain  wheat , soy, may contain traces of peanuts and tree nuts,"
}

```

We recognize the specific keys `ingredients_text` and
`ingredients_text_with_allergens`, but we also find keys
`ingredients_text_en` and `ingredients_text_with_allergens_en` which
are not listed in the data schema. They are implied with the regular
expressions `ingredients_text_(?<language_code>\w\w)` and
`ingredients_text_with_allergens_(?<language_code>\w\w)`.

Within the  existing JSON documents, I  have not found any  example in
which there  generic keys are  used for actual multi-linguism.  Yet, I
suppose there is  no unicity check and that multiple  instances of the
same generic key are allowed in a single document:

```
{
  "ingredients_text_fr": "eau",
  "ingredients_text_en": "water",
  "ingredients_text_de": "wasser"
}
```

In the check program, we need  to bracket the regular expressions with
begin-end  anchors `/^  ... $/`.  Failing that,  we could  find a  key
matching  `"ingredients_text_(?<language_code>\w\w)"` with  a language
code `"with_allergens"`, or more accurately `"wi"`. How silly!

So a typical  use of generic keys is multi-linguism.  Yet, if you read
again the example from the
[last paragraph](#user-content-Key-Value-Pairs)
about specific keys, you will find a specific key `product_name_en` in
addition   to  key   `product_name`,   which  gives   an  attempt   at
multi-linguism using specific keys.

We find also generic keys in files `nutrition_search.yaml` and `product_nutrition.yaml`,
to define a series of properties by combining an explicite use case with
a nutrient. Excerpt from `product_nutrition.yaml`

```
    patternProperties:
      '(?<nutrient>[\w-]+)_unit':
        description: |
          The unit in which the nutrient for 100g or per serving is measured.

          The possible values depends on the nutrient.

          * `g` for grams
          * `mg` for milligrams
          * `μg` for micrograms
          * `cl` for centiliters
          * `ml` for mililiters
          * `dv` for recommended daily intakes (aka [Dietary Reference Intake](https://en.wikipedia.org/wiki/Dietary_Reference_Intake))
          * `% vol` for alcohol vol per 100 ml
        type: string
      '(?<nutrient>[\w-]+)_100g':
        description: |
          The standardized value of a serving of 100g (or 100ml for liquids)
          for the nutrient.
        type: number
      '(?<nutrient>[\w-]+)_serving':
        description: |
          The standardized value of a serving for this product.
        type: number
```

And the document `"00187251"` contains:

```
        "nutriments" : {
                "fruits-vegetables-nuts-estimate-from-ingredients_serving" : 0,
                "fiber_100g" : 3.3333333333333,
                "sugars_unit" : "g",
                "nova-group_serving" : 4,
                "salt_100g" : 0.70833333333333,
                "sodium_100g" : 0.283333333333332,
                "proteins_100g" : 6.6666666666667,
                "energy-kcal_unit" : "kcal",
                "fruits-vegetables-legumes-estimate-from-ingredients_serving" : 0,
                "proteins_unit" : "g",
                "fruits-vegetables-legumes-estimate-from-ingredients_100g" : 0,
                (etc)
        },
```

This corresponds to the following use cases:

* `serving`,
* `100g`,
* `unit`

and the following nutrients:

* `fruits-vegetables-nuts-estimate-from-ingredients`,
* `fiber`,
* `sugar`,
* `salt`,
* `sodium`,
* `proteins`
* `fruits-vegetables-legumes-estimate-from-ingredients`

and even some pseudo-nutrients such as:

* `nova-group`,
* `energy-kcal`.

Implicit Fields
---------------

Let us take again the document from the
[paragraph about specific keys](#user-content-Key-Value-Pairs).
Actually, the contents of this document is rather:

```
{
        "_id" : "00187251",
        "code" : "00187251",
        "product_name_en" : "choclatey cats",
        "nova_group" : 4,
        "product_name" : "choclatey cats",
        "product_quantity" : 453.59237,
        "_keywords" : [
                "cat",
                "trader",
                "joe",
                "choclatey"
        ]
}
```

I have already read about field `_id`. It is mentionned in the O'Reilly
book on MongoDB bases, written by
[Kristina  Chodorow](https://www.oreilly.com/pub/au/4500).
If  we write  into a  MongoDB database  a document  without a  `"_id"`
key-value pair, then MongoDB automatically adds one.

Kristina  Chodorow's  book does  not  mention  the key  `"_keywords"`.
Because it  begins with an underscore,  I suppose it might  be another
implicit key, even  if it does not appear in  every database document.
Yet, I am not  sure of this, so my program will  stil display an error
message when seeing this key.

At first, I decided to:

1. automatically insert filed `"_id"` into the schema,

2. procrastinate,

3. create and submit a pull request, to insert field `"_keywords"`
into file `product_meta.yaml`.

While   I   was   procrastinating,  I   serendipitously   found   file
`product_hidden.yaml`,    which   describes    fields   `"_id"`    and
`"_keywords"`, plus  some others that  I had not considered  yet. This
file is  not included in  schema `product.yaml`, because  it describes
fields for internal uses only  and therefore discarded from the public
API.

The  actual  step  3  consisted  in rolling  back  step  1  (automatic
insertion  of  `"_id"`)  and  modifying  `schema-check.pl`  to  accept
`product_hidden.yaml`  in  addition  to `product.yaml`.  At  first,  I
intended  to add  a new  parameter `--hidden-schema`.  After a  second
round  of procrastination,  I  found  it would  be  simpler to  change
parameter `--schema` from a scalar to an array.

Multi-Level Data
----------------

In a key-value pair, the value  is not always a scalar value: integer,
floating number,  character string.  It can be  an embedded  full JSON
object. Let us take a look at a new excerpt of document `"00187251"`.

```
{
        "_id" : "00187251",
        "ecoscore_data" : {
                "status" : "unknown",
                "missing" : {
                        "origins" : 1,
                        "labels" : 1
                },
                "adjustments" : {
                        "packaging" : {
                                "score" : -79,
                                "non_recyclable_and_non_biodegradable_materials" : 1,
                                "value" : -15,
                        },
                        "production_system" : {
                                "value" : 0,
                                "warning" : "no_label"
                        },
                        "origins_of_ingredients" : {
                                "epi_score" : 0,
                                "epi_value" : -5,
                                "transportation_values" : {
                                        "no" : 0,
                                        ...
                                        "eg" : 0,
                                        "world" : 0,
                                        "ad" : 0,
                                        "se" : 0
                                },
                                "transportation_scores" : {
                                        "va" : 0,
                                        ...
                                        "it" : 0,
                                        "world" : 0,
                                        "ba" : 0,
                                        ...
                                        "at" : 0
                                },
                                "values" : {
                                        "lu" : -5,
                                        ...
                                        "it" : -5,
                                        "world" : -5,
                                        "ba" : -5,
                                        ...
                                        "ax" : -5
                                },
                                "warning" : "origins_are_100_percent_unknown"
                        },
                        "threatened_species" : {
                                "value" : -10,
                                "ingredient" : "en:palm-oil"
                        }
                }
        }
}
```

This corresponds  to the  following data  schema, extracted  from file
`product_ecoscore.yaml`. I have modified  the order of definitions, to
better stick with the actual data shown above.

```
type: object
description: |
  Fields related to Eco-Score for a product.

  See also: `ecoscore_score`, `ecoscore_grade` and `ecoscore_tags`.

properties:
  ecoscore_data:
    type: object
    description: |
      An object about a lot of details about data needed for Eco-Score computation
      and complementary data of interest.
    properties:
      status:
        type: string
      missing:
        type: object
        properties:
          labels:
            type: integer
          origins:
            type: integer
          packagings:
            type: integer
      adjustments:
        type: object
        properties:
          packaging:
            type: object
            properties:
              non_recyclable_and_non_biodegradable_materials:
                type: integer
              score:
                type: integer
              value:
                type: integer
              warning:
                type: string
          production_system:
            type: object
            properties:
              value:
                type: integer
              warning:
                type: string
          origins_of_ingredients:
            type: object
            properties:
              epi_score:
                type: integer
              epi_value:
                type: integer
              transportation_values:
                type: object
                properties:
                  world:
                    type: integer
                patternProperties:
                  (?<country_code>\w\w):
                    type: integer
              transportation_scores:
                type: object
                properties:
                  world:
                    type: integer
                patternProperties:
                  (?<country_code>\w\w):
                    type: integer
              values:
                type: object
                properties:
                  world:
                    type: integer
                patternProperties:
                  (?<country_code>\w\w):
                    type: integer
              warning:
                type: string
          threatened_species:
            type: object
            properties:
              ingredient:
                type: string
              value:
                type: integer
```

As we can see, besides the  types `string` and `integer`, there is the
already mentioned  type `object`,  which is accompanied  by a  list of
`properties` or a list of  `patternProperties` (or both). Within these
`properties`, we  find embedded  types `string`,  `integer as  well as
`object`, with the corresponding sub-description.

A little remark. keys `"transportation_scores"`,
`"transportation_values"`    and     `"values"`    include    sub-keys
`"(?<language_code>\w\w)"`. Yet, we find key  `"world"` which is not a
known language code  and which does not match  the regular expression.
This triggers  an error  message when running  the check.  This remark
gave a  _pull request_,  which was  applied to  the OFF  repository on
2024-10-11, later than the version duplicated onto `old-schema` in the
current  repository.  In  addition, file  `product_ecoscore.yaml`  was
split   on   2024-11-19,   which   gave    way   to   the   new   file
`ecoscore-country-code.yaml`  and the  regular expression  disappeared
from this new file.

In  the  JSON   document  holding  the  data,   each  embedding  level
corresponds to  two embedding levels  in the YAML file  describing the
data. If we number  the YAML levels from 0, the even  levels (0, 2, 4,
etc) contains technical keys:

* `description`,
* `type`,
* `properties`,
* `patternProperties`

and other not yet explained. The odd levels contain "business" keys:

* `ecoscore_data`,
* `status`,
* `missing`,
* `labels`,
* `origins`

and  so on.  In the  following, I  will use  the word  "attribute" for
technical keys and the word "property" for business keys.

There is a special case. `type` is a technical key, as we have already seen.
But in some cases, it is also a business key. For example, see file
fichier `knowledge_panels/panel.yaml`:

<pre>
<em>type:</em> object
description: Each panel contains an optional title and an optional array of elements.
properties:
  <strong>type:</strong>
    <em>type:</em> string
    description: 'Type of the panel. If set to "card", the panel and its sub-panels should be displayed in a card. If set to "inline", the panel should have its content always displayed.'
  expanded:
    <em>type:</em> boolean
    description: 'If true, the panel is to be displayed already expanded. If false, only the title should be displayed, and the user should be able to click or tap it to open the panel and display the elements.'
  expand_for:
    <em>type:</em> string
    description: 'If set to "large", the content of the panel should be expanded on large screens, but it should still be possible to unexpand it.'
</pre>

The  level-1  business  keys  are  `expanded`,  `expanded_for`  and...
`type`. And we also have a technical  key `type` at level 0 (once) and
at level 2 (three times). The same case appears in
`knowledge_panels/elements/table_element.yaml`

<pre>
title: table_element
x-stoplight:
  id: 38zu3z4sruqo7
type: object
description: Element to display a table.
properties:
  id:
    type: string
    description: An id for the table.
  title:
    type: string
    description: |
      Title of the column.
  rows:
    type: string
  columns:
    type: array
    items:
      type: object
      title: table_column
      properties:
        <strong>type:</strong>
          type: string
        text:
          type: string
        text_for_small_screens:
          type: string
        style:
          type: string
        column_group_id:
          type: string
        shown_by_default:
          type: boolean
</pre>

and in `knowledge_panels/elements/text_element.yaml`

<pre>
title: text_element
x-stoplight:
  id: vdwxlt73qnqfa
type: object
description: |-
  A text in simple HTML format to display.

  For some specific texts that correspond to a product field (e.g. a product name, the ingredients list of a product),the edit_field_* fields are used to indicate how to edit the field value.
properties:
  <strong>type:</strong>
    type: string
    description: |
      the type of text, might influence the way you display it.
    enum:
      - summary
      - warning
      - notes
  html:
    type: string
    description: Text to display in HTML format.
...
</pre>

and in `knowledge_panels/elements/title_element.yaml`

<pre>
title: title_element
x-stoplight:
  id: lox0wvl9bdgy2
type: object
description: The title of a panel.
properties:
  title:
    type: string
  grade:
    type: string
    description: Indicates that the panel corresponds to a A to E grade such as the Nutri-Score of the Eco-Score.
    enum:
      - a
      - b
      - c
      - d
      - e
      - unknown
  icon_url:
    type: string
  icon_color_from_evaluation:
    type: string
  icon_size:
    type: string
    description: |
      If set to "small", the icon should be displayed at a small size.
  <strong>type:</strong>
    type: string
    example: grade
    description: 'Used to indicate a special type for the title, such as "grade" for Nutri-Score and Eco-Score.'
</pre>

Arrays
------

The JSON documents from database `off` may contain arrays. Here is yet
another excerpt from product `00187251`:

```
{
        "_id" : "00187251",
        "ingredients_analysis_tags" : [
                "en:palm-oil",
                "en:vegan-status-unknown",
                "en:vegetarian-status-unknown"
        ]
}
```

The file `product_ingredients.yaml`  contains the description of this array:

```
  ingredients_analysis_tags:
    type: array
    items:
      type: string
```

When I wrote about technical keys  and business keys for JSON objects,
I wrote that  technical keys appear at even embedding  levels and that
business  keys  appear at  odd  embedding  levels. When  dealing  with
arrays,  this  is no  longer  the  case.  You  have the  business  key
`ingredients_analysis_tags` at  level 1 and the  technical keys `type`
and `items` at level 2, but at level 3 you find another technical key,
`type`.

Is it possible to define arrays  of `number` or arrays of `integer`? I
guess so, but I have found no example in the data schema.

Other arrays are described in this way (see file `product_ingredients.yaml`):

```
  ingredients_from_palm_oil_tags:
    type: array
    items:
      type: object
```

There is a problem, because the  schema does not list the keys allowed
for  the objects  stored within  the array:  neither `properties`  nor
`patternProperties` at level  3. Is this a mistake in  the data schema
or is this an  idiom allowing any key without any  check for the array
elements? For the  moment, my checking program triggers  an error, yet
noting that the error  applies to the YAML data schema  and not to the
JSON data.

In other cases, yet much fewer than the cases above, the description
of the array elements is complete, with a list of `properties`. Here
is a description merging files `product_misc.yaml`,
`packagings/packagings.yaml`, `packaging_component.yaml` and some
others:

```
  packagings:
    type: array
    items:
      type: object
      properties:
        material:
          type: object
          properties:
            id:
              type: string
            lc_name:
              type: string
        number_of_units:
          type: integer
        quantity_per_unit:
          type: string
        ...
```

Lastly, I found even an array of arrays. This is sub-property `"3"` of
property `"nova_groups_markers"` from file `product_extended.yaml`:

```
  nova_groups_markers:
    type: object
    description: "Detail of ingredients or processing that makes the products having Nova 3 or 4\n"
    properties:
      3:
        type: array
        description: |
          Markers of level 3
        items:
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
```

The Remaining `$ref` Keys
-------------------------

I wrote that the YAML files  contain 52 `$ref` attributes, 49 of which
doing a action similar to `#include`. What about the last 3?

Let  us  consider  again property  `"nova_groups_markers"`  from  file
`product_extended.yaml`. Its full description is:

```
type: object
properties:
  [...]
  nova_groups_markers:
    type: object
    description: |
      Detail of ingredients or processing that makes the products having Nova 3 or 4
    properties:
      "3":
        description: |
          Markers of level 3
        type: array
        items:
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
      "4":
        description: |
          Markers of level 4
        type: array
        items:
          # same as above
          $ref: "#/properties/nova_groups_markers/properties/3/items"
```

This `$ref` attribute  means that we must copy the  description of the
items from  business key `"3"`  into the  description of the  items of
business key  `"4"`. The idea is  still a kind of  `#include`, but the
implementation  is  different.  The  intended  result  is  to  have  a
description equivalent to:

```
type: object
properties:
  [...]
  nova_groups_markers:
    type: object
    description: |
      Detail of ingredients or processing that makes the products having Nova 3 or 4
    properties:
      "3":
        description: |
          Markers of level 3
        type: array
        items:
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
      "4":
        description: |
          Markers of level 4
        type: array
        items:
          # same as above
          # $ref: "#/properties/nova_groups_markers/properties/3/items"
          type: array
          description: |
            This array has two element for each marker.
            One
          items:
            type: string
```

The  last  two  `$ref`  keys appear  in  files  `ingredient.yaml`  and
`nutrients.yaml`. Here is the complete contents of `nutrients.yaml`.

```
type: array
description: |
  Nutrients and sub-nutrients of a product, with their name and default unit.
items:
  type: object
  properties:
    id:
      type: string
      description: id of the nutrient
    name:
      type: string
      description: Name of the nutrient in the requested language
    important:
      type: boolean
      description: Indicates if the nutrient is always shown on the nutrition facts table
    display_in_edit_form:
      type: boolean
      description: Indicates if the nutrient should be shown in the nutrition facts edit form
    unit:
      description: Default unit of the nutrient
      $ref: "./nutrient_unit.yaml"
    nutrients:
      description: |
        Sub-nutrients (e.g. saturated-fat is a sub-nutrient of fat).
      # self recursive
      $ref: "#/"
```

The aim  is copying  an existing description  into another.  But here,
there is no filter on `properties / nova_groups_markers / properties /
3 / items`, and the invoked sub-schema contains a reference to itself.
As hinted  by the comment,  this is a recursive  copy and there  is no
limit to  this recursion.  Of course,  the JSON  document will  have a
finite size, therefore a finite embedding level, so the recursion will
stop sooner or later. But the  recursion cannot be limited in the YAML
data schema. So we will use  a "dynamic" insertion mechanism, that is,
the referred  sub-schema will be  included while the JSON  document is
being analysed, not  during the initialisation of the  program. In the
following, I will use the  phrase "dynamic sub-schema" as a short-hand
for "dynamically included sub-schema".

Just  one remark  about  this  example. I  use  `nutrient.yaml` as  an
example.  Yet,  this file  is  never  included  into the  main  schema
`product.yaml`,  directly  or  indirectly.  On the  other  hand,  file
`ingredient.yaml` is included from `product_ingredients.yaml`.

The char  `"#"` reminds us of  HTML hyperlinks. Can we  imagine mixing
references to external files with references to a hierarchy of keys? I
tried  to  to this  in  file  `parallel-refs-1.yaml` in  sub-directory
`reduced-schema`.  Even if  I  have no  examples of  this  in the  OFF
database, I think it is the way  to go. (This remark is obsolete after
the 2024-10-21 reorganisation, now you can find many references mixing
an external file name with a key hierarchy.)

At first, I  thought that `'$ref'` entries targetting a  file would be
processed with  a static  include mechanism  (full copy  into variable
`$schema`) and `'$ref'` entries containing  a hash char and targetting
a key hierarchy  would be processed with a  dynamic include mechanism.
Actually, even with  `'$ref'` entries targetting files, we  may have a
chicken-and-egg  situation, requiring  a  dynamic  mechanism. You  can
refer   to  schemas   `egg.yaml`  and   `chicken.yaml`  in   directory
`reduced-schema` and  to data file `chicken-and-egg.data.json`  in the
same directory.

The solution in  program `schema-check.pl` is to add  a new parameter,
`max-depth`, with an  integer value. While the include  level is lower
than  parameter  `$max_depth`, the  program  uses  the static  include
mechanism. If the include level reaches this level, the program uses a
dynamic mechanism to include the sub-schema pointed at by the `'$ref'`
key, after checking  it has not already been included.  The problem of
infinite recursion is avoided.

To know whether the sub-schema  has already been dynamically included,
the program first  normalise the key, to have all  three elements, the
file name, the hash char and  the key hierarchy. If necessary, the key
hierarchy is reduced  to a single slash to represent  the inclusion of
the  complete file.  This normalised  value is  used as  a key  to the
hashtable of dynamic sub-schemas.

Value Checking
--------------

As we have already seen, checking the  keys is the essence of a schema
description,  either  through  entry `properties`,  or  through  entry
`patternProperties`.  We have  seen the  language (or  country) codes.
There is  also the image  sizes, as can be  seen in this  excerpt from
`image.yaml`

```
    properties:
      sizes:
        type: object
        description: |
          The available image sizes for the product (both reduced and full).
          The reduced images are the ones with numbers as the key( 100, 200 etc)
          while the full images have `full` as the key.
        patternProperties:
          (?<image_size>100|400):
            type: string
            description: |
              properties of thumbnail of size `image_size`.
              **TODO** explain how to compute name
```

If the  keys are checked,  what about  the values in  key-value pairs?
This  is  seldom  done,  but  this exists.  See  the  example  of  the
sub-properties     of    property     `nutrient_levels`    in     file
`product_misc.yaml`

```
  nutrient_levels:
    type: object
    description: "Traffic light indicators on main nutrients levels\n"
    properties:
      fat:
        type: string
        enum: ["low", "moderate", "high"]
      salt:
        type: string
        enum: ["low", "moderate", "high"]
      saturated-fat:
        type: string
        enum: ["low", "moderate", "high"]
      sugars:
        type: string.
        enum: ["low", "moderate", "high"]
```

But the checking  program does not care (for now).  We find also value
examples  (attribute  `example`) which  are  not  used either  in  the
checking program.

You may have  noticed that in the example above,  arrays are specified
with the JSON syntax instead of  the YAML syntax (dashes on successive
lines). This  is valid, the  YAML specification allows a  "flow style"
which is similar to the JSON syntax.

In the  paragraph about arrays, you  may have noticed that  the values
are very  similar to each other,  with a language code,  followed by a
colon, followed by a label.

```
                "en:palm-oil"
                "en:vegan-status-unknown"
                "en:vegetarian-status-unknown"
```

Nothing  in  the  YAML  files   describes  such  structure  within  an
alphanumeric string and the checking program will do nothing.

Special Case in Type Declarations
---------------------------------

For scalars,  I have already  mentioned types `string`,  `integer` and
`number`. There  is also a  type `null`, used in  property `normalize`
and property `white_magic`,  both in file `image_role.yaml`.  I do not
know what this type `null` represents.

Sometimes, some properties are flagged with:

```
        readOnly: true
```

Even if  I guess  what it  is about,  I do  not care.  This `readOnly`
attribute  does not  apply  to the  checking  program, which  examines
documents as static data, not  dynamic data which are created, updated
and erased at various instants.

Checking the types  of the values (even if not  yet implemented in the
checking program) can be extended.  For example, we can accept several
basic  types instead  of  just one.  This is  the  case with  property
`additionalProperties`   within   property  `owner_fields`   in   file
`product_extended.yaml`. For this  property, we can use  either a char
string,  or an  integer, or  an  object (without  specifying the  keys
within this object), but  we cannot use a float number,  an array or a
`null`.

```
  owner_fields:
    type: object
    description: |
      Those are fields provided by the producer (through producers platform),
      and the value he provided.
    properties:
      additionalProperties:
        description: |
          you can retrieve all kind of properties, the same as on the parent object (the product).
          It's not processed entries (like tags for example) but raw ones.
        oneOf:
          - type: integer
          - type: string
          - type: object
```

In  file `ingredient.yaml`,  I have  found this  syntax, in  which the
attribute `type` is associated to an array.

```
        percent_estimate:
          type:
            - number
        percent_max:
          type:
            - number
```

In this case, the lists have one element each, but we can imagine they
could include several. Is this list syntax equivalent to the attribute
`oneOf` seen above in file `product_extended.yaml`? In other words, is
the following syntax a valid one?

```
        percent_estimate:
          type:
            - integer
            - number
        percent_max:
          type:
            - integer
            - number
```

Another  curious  element,  in  file `knowledge_panels  /  elements  /
element.yaml`, the property `knowledge_panels . additionalProperties .
elements[*]  . type`  (which is  a business  `type`) has  no technical
field `type`, but a technical field `element_type`.

```
                type:
                  element_type: string
                  enum:
                    - text
                    - image
                    - action
                    - panel
                    - panel_group
                    - table
                  description: |
                    The type of the included element object.
                    The type also indicates which field contains the included element object.
                    e.g. if the type is "text", the included element object will be in the "text_element" field.

                    Note that in the future, new type of element may be added,
                    so your code should ignore unrecognized types, and unknown properties.

                    TODO: add Map type
```

And a  last curiosity,  in file `product_extended.yaml`,  the business
field  `category_properties`  has  a `type`  attribute  `object`,  but
neither  `properties`  attribute, nor  `patternProperties`  attribute,
only a key `additionalProperties`.

```
  category_properties:
    type: object
    additionalProperties:
      description: those are properties taken from the category taxonomy
      type: string
```

Do not confuse this `category_properties` key (with an `"y"`) with the
other key, `categories_properties` (with `"ies"`) found elsewhere.

Let us note  that this `additionalProperties` key is a  the same level
than  attribute `type`  and,  therefore, is  itself another  attribut,
while  in   the  `owner_fields`   example  a  few   paragraphs  above,
`additionalProperties` was  a property. Let  us note also that  at the
next level, we find again technical keys `description` and `type`. The
checking program does not pay attention to this `additionalProperties`
attribute and it considers  that the property `category_properties` is
an  object with  unknown properties.  Actually, after  digging in  the
`products`  collection,  I  found  a  few  examples  with  a  property
`category_properties`  and this  property  is nearly  always an  empty
object      `{}`     (exceptions,      products     `"0052833225082"`,
`"0078742054797"`,  `"0078742102047"`   and  a  few  others   in  file
`multiligne`).

```
{
   "_id" : "0052833225082",
   "category_properties" : {
      "ciqual_food_name:en" : "Cheddar cheese, from cow's milk",
      "ciqual_food_name:fr" : "Fromage -aliment moyen-"
   }
}
{
   "_id" : "0078742054797",
   "category_properties" : {
      "ciqual_food_name:en" : "Sausage -average-",
      "ciqual_food_name:fr" : "Saucisse -aliment moyen-"
   }
}
{
   "_id" : "0078742102047",
   "category_properties" : {
      "ciqual_food_name:en" : "Cheddar cheese, from cow's milk",
      "ciqual_food_name:fr" : "Fromage -aliment moyen-"
   }
}
```

Actually, I  do not know  how to  interpret these cases.  The examples
above fail to enlighten my understanding.

Running the Checks
==================

Extracting the Schema
---------------------

Files   `product.yaml`  and   `product_hidden.yaml`  are   loaded  and
converted to a Perl value to initialise the data schema.

For  each file,  the  program  loops over  the  entries of  attributes
`properties` and  `patternProperties`. If also loops  over the entries
of `allOf`, if present. Each entry  is a key-value with key `$ref` and
the value  is another  file describing a  partial data  schema (called
subschema in this documentation). At  each loop iteration, the program
loads the  file and converts the  YAML data to Perl  data. The program
copies each subentry  of entry `properties` to  the entry `properties`
of the  target schema  (possibly auto-vivified).  Same thing  with the
subentries of  `patternProperties`, copied to  the `patternProperties`
attribute in the schema.

Before copying the content of the sub-schema into the main schema, the
program   checks   if   the    sub-schema   contains   references   to
sub-sub-schemas. If this  is the case, the  sub-sub-schema is inserted
into the  sub-schema before the  sub-schema is inserted into  the main
schema. If necessary, this quest  for sub-sub-schemas is recursive. It
will be clearer with an example.

Here is an excerpt from `product.yaml` (before 2024-10-21);

```
type: object
description: |
  This is all the fields describing a product and how to display it on a page.
allOf:
  - $ref: './product_ecoscore.yaml'
```

And now an excerpt from  `product_ecoscore.yaml`:

```
type: object
properties:
  ecoscore_data:
    type: object
    description: |
      An object about a lot of details about data needed for Eco-Score computation
      and complementary data of interest.
    properties:
      agribalyse:
        $ref: "./agribalyse.yaml"
      grade:
        type: string
      previous_data:
        type: object
        properties:
          grade:
            type: string
          score:
            type: integer
          agribalyse:
            $ref: "./agribalyse.yaml"
```

and an excerpt from `agribalyse.yaml`:

```
type: object
properties:
  agribalyse_food_code:
    type: string
  co2_agriculture:
    type: number
```

The data schema will be a Perl  value which could be serialised as the
following YAML text:

```
type: object
allOf:
  - $ref: './product_ecoscore.yaml'
properties:
  ecoscore_data:
    type: object
    properties:
      agribalyse:
        $ref: "./agribalyse.yaml"
        type: object
        properties:
          agribalyse_food_code:
            type: string
          co2_agriculture:
            type: number
      grade:
        type: string
      previous_data:
        type: object
        properties:
          grade:
            type: string
          score:
            type: integer
          agribalyse:
            $ref: "./agribalyse.yaml"
            type: object
            properties:
              agribalyse_food_code:
                type: string
              co2_agriculture:
                type: number
```

You may notice that `$ref` attributes are kept, they may be useful for
some  later  debugging.  On  the other  hand,  the  `description`  and
`example` fields are discarded.

### Recursive References Before 2024-10-21

The  three  special  `'$ref'`  attributes,  in  `nova_groups_markers`,
`nutrients.yaml` and  `ingredient.yaml`, are processed like  all other
`'$ref'` which  just include a  file, with still a  little difference.
When  processing  the   `nova_groups_markers`  property,  the  dynamic
sub-schema   is   not   given   by    the   full   content   of   file
`product_extended.yaml`, but a small part  of the tree structure, with
the selection of `properties /  nova_groups_markers / properties / 3 /
items`.  Before feeding  the value  to the  `schema` attribute  of the
sub-schema, the program executes this selection.

Yet, we pay  attention to the include level of  the reference. If this
include level is greater than the `--max-depth` parameter, the program
switches  from  the static  include  mechanism  to a  dynamic  include
mechanism.  The program  adds a  `dyn_sch` attribute  (dynamic schema)
storing  the full  reference. This  full reference  is built  with the
filepath  (with directories),  a  `'#'` char,  and  the selection  key
hierarchy (with slash separators). If the reference does not specify a
selection with a  key hierarchy, the full reference  includes a single
slash after the hash char. This  full reference is added to the schema
as a `dyn_sch` attribute and at the same time a new entry is pushed to
the  list  `@dyn_sch_to_do`,  holding all  necessary  informations  to
identify and extract the dynamic subschema.

Then, when the main schema is  complete, the program iterates over the
`@dyn_sch_to_do` list  to load all  dynamic subschemas and  store them
into the  `%dyn_schema` hashtable,  while checking that  the subschema
has not been inserted already.

We  can remark  that  if the  program is  run  with a  `--max-depth=1`
parameter,  nearly   all  `'$ref'`  attributes  will   be  dynamically
processed.  The  only  `'$ref'`  attributes that  will  be  statically
inserted  are  the  12  `'$ref'`  from  attribute  `allOf`  from  file
`product.yaml`.  But  if   it  is  run  with   the  default  parameter
`--max-depth=5`,  only the  recursive  reference in  `ingredient.yaml`
will use a dynamic insertion...  after having been statically inserted
three times.

By the  way, when dealing with  static insertions, the schema  tree is
processed in _depth-first_  order, but when the  program processes the
dynamic insertions, they are processed in _breadth-first_ fashion.

### Recursive References After 2024-10-21

Before 21st October, nearly all  `'$ref'` entries were attributes of a
property being defined  in the current YAML file.  The only exceptions
were  the  12 `'$ref'`  entries  in  file `product.yaml`.  Since  21st
October, some other `'$ref'` entries appear at the top level of a YAML
file, or  rather in a hierarchy  that contains no properties.  This is
the case with the `'$ref'` entries  within the `components / schemas /
xxx`  hierarchy  in  file  `api.yml`. With  a  threshold  for  dynamic
insertion equal  to 1, these `'$ref'`  entries were not stored  in the
program's hashtable  storing the  dynamic subschemas,  so in  the JSON
documents, all  first-level keys were  flagged as invalid  (except for
`_id` which was automatically inserted).

The  checking function  processes  a dynamic  reference  only if  this
reference  is  within  the  definition of  a  property.  the  checking
function does not process a `'$ref'`  entry which applies to the whole
hashtable being checked.  I kept this operating way and  I changed the
function  loading the  schema. If  the `'$ref'`  entry appears  at the
first  level of  the YAML  file, it  is _statically_  loaded into  the
schema,  even   if the  current  include  level  is greater  than  the
threshold for  dynamic insertion. So  the checking function  will find
dynamic insertions only for the properties being checked.

Extracting the JSON Documents
-----------------------------

Beyond the YAML files for  the schema, the program receives filenames.
We suppose that these files  contain unformatted text, with from place
to place,  a few JSON  documents. There  are three categories  of JSON
documents. First, single-line objects. It does not matter if this line
is  30_000-char long.  Then, objects  spanning several  lines, with  a
single open  brace and  nothing else  on the first  line and  a single
close brace and nothing else on  the last line. And last, several JSON
objects grouped in a JSON array, with an open bracket and nothing else
on the first line  and a single close bracket and  nothing else on the
last line.

The extraction uses a finite-state automaton. This automaton has three
states, `A`,  `B` and  `C`. The  initial state  is `A`.  The automaton
process is  not a char-oriented  process, but a  line-oriented process
(neither `chop` nor `chomp`).

In state `A`, if we encounter a  line beginning with an open brace and
ending with  a close  brace, the program  calls the  checking function
with this line. The automaton stays at state `A`.

In state `A`,  if we encounter a  line with a single  open brace (plus
the line end LF or CRLF), the automaton initialises a char string with
this brace (and line end) and shifts to state `B`.

In state `B`, we add the current line to this char string. If the line
contains a single  close brace (plus line end), the  program calls the
object-checking function  with the char  string, then shifts  to state
`A`.

In state `A`, if  we encounter a line with a  single bracket (plus the
line end), the  automaton initialises a char string  with this bracket
(and line end) and shifts to state `C`.

In state `C`, we add the current line to this char string. If the line
contains a single close bracket (plus line end), the program adds this
bracket to the char string, calls the array-checking function with the
char string, then shifts to state `A`.

In state `A`, if none of the three cases given above applies, the line
is ignored and the next line is processed.

There is no transition between states `B` and `C`.

The allowed final state should be  state `A`, but the program does not
check this. It  just closes the file and processes  the next data file
if any remains.

Checking the JSON Documents
---------------------------

At  level  1, each  document  is  a hashtable  or  an  array, or  more
precisely the  reference to a  hashtable or  to an array.  The program
loads this  JSON document, converts it  to a Perl hashref  or arrayref
and calls the proper checking function.

### Checking a Hashtable

The checking function begins with checking that the reference received
as a parameter is a hashref.

The function checks  that the schema has a description  for the object
being checked. It  often happens that the schema declares  an array of
objects, without giving  a full description of  these objects. Example
from `product_ecoscore.yaml`:

```
  environment_impact_level_tags:
    type: array
    items:
      type: object
```

Actually, this error applies to the data schema, not the data content.
By the way,  we can find places where the  schema is properly defined,
with a full description for the embedded objets. Example from the same
file `product_ecoscore.yaml`:

```
              aggregated_origins:
                type: array
                items:
                  type: object
                  properties:
                    origin:
                      type: string
                    percent:
                      type: integer
[...]
              packagings:
                type: array
                items:
                  type: object
                  properties:
                    ecoscore_material_score:
                      type: integer
                    ecoscore_shape_ratio:
                      type: integer
                    material:
                      type: string
                    shape:
                      type: string
```

Then the checking  function iterates over the keys  of this hashtable.
For each  key, the  function checks  if this key  appears at  level 2,
within the  `properties` entry of the  schema. If yes, so  good. Else,
the function iterates over the `patternProperties` entries and compare
the key  to each pattern. If  a match occurs, the  function leaves the
loop over the `patternProperties` entries.

If  nothing  appropriate was  found  in  the  `properties` or  in  the
`patternProperties`, this is an error.

If the property  `type` is `string`, `integer` or `number`,  as in the
examples below,

```
properties:
  abbreviated_product_name:
    type: string
    description: Abbreviated name in requested language
  nova_group:
    type: integer
    description: |
      Nova group as an integer from 1 to 4. See https://world.openfoodfacts.org/nova
  completeness:
    type: number
patternProperties:
  abbreviated_product_name_(?<language_code>\w\w):
    type: string
    description: Abbreviated name in language `language_code`.
```

no  further checking  is done,  the key-value  pair is  deemed correct
(maybe the program should still check the value is a proper number for
`integer` or `number`?).

If the property `type` is `object`, as in the example below

```
properties:
  ecoscore_data:
    type: object
    description: |
      An object about a lot of details about data needed for Eco-Score computation
      and complementary data of interest.
    properties:
      adjustments:
        type: object
        properties:
          origins_of_ingredients:
            type: object
            properties:
              epi_score:
                type: integer
```

the function  calls itself recursively,  while going down  one logical
level, that is  going down two levels in the  schema (`properties` and
then the property value).

If  the property  `type`  is  `array`, the  function  calls the  other
checking function, the one which deals with arrays.

If there is  no `type` attribute, but there is  a `dyn_sch` attribute,
the  program fetches  the dynamic  sub-schema, checks  its `type`  and
calls  the  hash-checking  function  or  the  array-checking  function
accordingly.

If there is neither `type`  nor `dyn_sch` attributes, then the program
triggers an error.  There is also an error if  the `dyn_sch` attribute
exists, but  the corresponding  subschema has  no `type`  attribute at
level 0.

### Checking an Array

As it  is done  for objects, the  array-checking function  begins with
checking that the reference it received is an array-ref.

Just like the object-checking function checks that there is at least a
`properties` or `patternProperties` entry, the array-checking function
checks that the schema contains an `items` entry.

If the array  items are supposed to be strings  or numbers, no further
checks are  done. If  they are  supposed to  be objects,  the function
calls the hash-checking  function. If they are supposed  to be arrays,
the function calls itself recursively.

Like the  hash-checking function, the array-checking  function can use
the  `dyn_sch` attribute  to fetch  a dynamic  sub-schema and  get the
proper `type` attribute.

Comments After Implementation
-----------------------------

### Function `find_ref_rec`

(to do)

### Function `check_hash`

(to do)

### JSON or JSON5? Which Perl module?

(to do)

### YAML or YAML::XS? Which Perl module?

Module `YAML` is  better in one way than `YAML::XS`,  it is compatible
with module  `YAML::Node`, which  enables you  to sort  the keys  of a
hashtable in  any way  you want. In  my utility  `schema-check.pl`, it
allows  me to  display the  attributes  of a  property with  attribute
`type`  in  the first  slot  and  then  the other  attributes,  sorted
alphabetically. The readability  is much improved. This  is the reason
why I chose `YAML.pm` at first.

After the  overhaul of  YAML schema files  on 2024-10-21,  some syntax
errors appeared in  some files, mainly because of the  flow style. The
"flow style" is  a style very similar to the  JSON syntax which relies
on brackets and separators, instead  of the "block style" which relies
on linefeeds and indentation.

Example from `product_nutriscore.yaml`

```
      properties:
        id:
          type: string
          examples:
            [
              "energy",
              "sugars",
              "saturated_fat",
              "salt",
              "fiber",
              "fruits_vegetables_legumes",
            ]
        points:
          type: integer
          examples: [5, 6, 7, 2, 1, 0]
        points_max:
          type: integer
          examples: [10, 15, 20, 25, 5, 5]
```

The arrays  associated with attribues  `examples` use the  flow style,
while everything else uses the block style. Both styles are valid with
the YAML syntax.

The problem with `YAML.pm` is that it cannot deal with flow style when
an array or  an object spans several lines. In  the example above, the
module would trigger  an error when dealing with  the `examples` array
from the `id`  property. On the other hand, there  is no problems with
the `examples`  arrays from the `points`  and `points_max` properties.
Yet, module  `YAML::XS` accept  this whole example  without triggering
any error.

I reacted by putting the cart before the horse.

I first rewrote the YAML file  by fixing the points at which `YAML.pm`
triggered errors, for example:

```
        id:
          type: string
          examples:
            - "energy"
            - "sugars"
            - "saturated_fat"
            - "salt"
            - "fiber"
            - "fruits_vegetables_legumes"
```

I created a
[_pull request_](https://github.com/openfoodfacts/openfoodfacts-server/pull/11220)
to send these updates to the
[OFF repository](https://github.com/openfoodfacts/openfoodfacts-server).

Then I reread the 
[YAML specification](https://yaml.org/spec/1.2.2/)
and I realised that the flow  style was supposed to be compatible with
linefeeds.

I wrote a
[much shorter utility](https://github.com/jforget/perl-Open-Food-Facts-utils/tree/master/yaml-check)
to just  check YAML syntax  in a file.  This utility would  use either
`YAML.pm` or `YAML::XS`.

So I found  that `YAML::XS` would accept linefeeds  within flow style.
So  I closed  my pull  request and  I fixed  `schema-check.pl` to  use
`YAML::XS`.

The problem  was that, in  the listings,  the attribute `type`  was no
longer in the  first line after the property name.  So I modified once
more `schema-check.pl` to use both  `YAML.pm` and `YAML::XS`, each one
with its own role:

* `YAML::XS` to read  the YAML files, parse them and  store the result
in the program's memory,

* `YAML.pm` to  print the  full schema into  the listing,  if required
with option `--list-schema`.

License
=======

This  documentation  is  published under  license  CC-BY-SA:  Creative
Commons with attribution and share-alike.
