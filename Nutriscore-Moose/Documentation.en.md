-*- encoding: utf-8; indent-tabs-mode: nil -*-

Purpose
=======

During the
[24th May 2025 hackathon](https://forum.openfoodfacts.org/t/hackathon-perl-open-food-facts-in-paris-2025/1936),
I opted to work on the subject aiming at replacing the hashmaps with objects
([Moose](https://metacpan.org/pod/Moose)).
The first target for this work is
variable `$nutriscore_data_ref` in
[`ProductOpener::Nutriscore`](https://github.com/jforget/openfoodfacts-server/blob/main/lib/ProductOpener/Nutriscore.pm).

Please note that the experiment is not the comparison of
[`bless`](https://perldoc.perl.org/functions/bless)
with [`Moo`](https://metacpan.org/pod/Moo)
and [Corinna](https://curtispoe.org/articles/corinna-in-the-perl-core.html)
and other object-oriented Perl solutions.  The choice has already been
made, and it is Moose. The experiment  is about how to use Moose in an
actual OFF function.

Installing Moose
================

This chapter does not directly  deal with OpenFoodFacts, but I include
it hoping that any reader might find some useful hints.

On  the computer  I used  for  the hackathon,  the system  interpreter
`perl` has version 5.34.x. It  does not use function signatures, which
are extensively used in OFF. There  is also a `perl-5.38.2`, which can
be enabled with `perlbrew`. Yet, when I installed `Moose`, I forgot to
enable version  5.38.2. So I  had to  run installation a  second time,
after enabling 5.38.2.

Another problem. I run the installation in two steps. During the first
step, I ensure all the prerequisites listed in
[MetaCPAN](https://metacpan.org/pod/Moose)
(left margin) are installed. And in the second step, I install `Moose`
proper. Yet, on the machine I  used for the hackathon, the second step
produced a few errors because  of missing prerequisites. If I remember
correctly, these were:

* [DateTime](https://metacpan.org/pod/DateTime)

* [Params::Validate](https://metacpan.org/pod/Params::Validate)

* [Log::Any](https://metacpan.org/pod/Log::Any)

On the following  days, I tried to install Moose  on a virtual machine
running  xubuntu-25.04 and  Perl  5.40.1, on  another virtual  machine
running  Fedora-41 and  Perl 5.40.2  and on  my main  computer running
Devuan  and   Perl  5.38.2  through  `perlbrew`   (or  5.32.1  without
`perlbrew`).  I did  not reproduce  the whole  problem in  these three
cases. For example,  the absence of `DateTime` causes a  `SKIP` in the
tests, not a test failure  which prevents the installation of `Moose`.
On  the  other hand,  when  I  tried to  run  the  example script  for
`Nutriscore.pm`, there was an error because `Log::Any` was missing.

Modus Operandi
==============

On 24th May,  I did some research  in an intuitive and  fast way. When
working later  on the subject, June  and after, my research  is slower
and more thourough.  I keep all versions in the  directory, because it
will be easier to compare these versions in this way, it would be more
difficult  if the  reader had  to juggle  between versions  using `git
checkout`.

On 24th May, I used a test script based on the POD documentation of `Nutriscore.pm`:

```
    use ProductOpener::Nutriscore qw/:all/;

        my $nutriscore_data_ref = {
                # Nutrients
                energy =>  518, # in kJ
                sugars => 3,
                saturated_fat => 0.7,
                saturated_fat_ratio => 0.7 / 3 * 100,
                sodium => 0.61 / 2.5 * 1000,    # in mg, sodium = salt divided by 2.5
                fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
                fiber => 2.2,
                proteins => 6.7,

                # The Nutri-Score computation is different for beverages, waters, cheeses and fats
                is_beverage => 1,
                is_water => 0,
                is_cheese => 0,
                is_fat => 1, # for 2021 version
                is_fat_oil_nuts_seed => 1, # for 2023 version
        }

        my ($nutriscore_score, $nutriscore_grade) = compute_nutriscore_score_and_grade(
                $nutriscore_data_ref
        );

        print "Rounded value for sugars: " . $nutriscore_data_ref->{sugars_value} . "\n";
        print "Points for sugars: " . $nutriscore_data_ref->{sugars_points}. "\n";
```

Test script `nutriscore.t`?
---------------------------

In June 2025, I tried to add the unit test script for the Nutriscore formula,
[`nutriscore.t`](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/tests/unit/nutriscore.t).
When doing so, I had to create a new module `ProductOpener::Config`  by copying file
[`Config2_sample.pm`](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/lib/ProductOpener/Config2_sample.pm)
into the local directory,
Also, I had to initialise an environment variable

```
export  PRODUCT_OPENER_FLAVOR_SHORT=off
```

Lastly, I had to install a few additional modules:

* [`Log::Any::Adapter::TAP`](https://metacpan.org/pod/Log::Any::Adapter::TAP)

* [`Modern::Perl`](https://metacpan.org/pod/Modern::Perl)

* [`JSON::MaybeXS`](https://metacpan.org/pod/JSON::MaybeXS)

* [`URI::Escape::XS`](https://metacpan.org/pod/URI::Escape::XS)

* [`JSON::Create`](https://metacpan.org/pod/JSON::Create)

* [`File::Find::Rule`](https://metacpan.org/pod/File::Find::Rule)

* [`Locale::Maketext::Lexicon`](https://metacpan.org/pod/Locale::Maketext::Lexicon)

* [`Locale::Maketext::Lexicon::Getcontext`](https://metacpan.org/pod/Locale::Maketext::Lexicon::Getcontext)

* [`CLDR::Number`](https://metacpan.org/pod/CLDR::Number)

* [`CGI`](https://metacpan.org/pod/CGI)

And now I had to install
[`Image::Magick`](https://metacpan.org/pod/Image::Magick).
I canceled this  step. Why do the *unit* tests  for Nutriscore need to
do some graphical file processing? So  I will use only the script from
the POD example.

Version 1, barebones class
==========================

When  we  read  test  program  `example0.pl`,  we  see  that  variable
`$nutriscore_data_ref` contains keys that appear in documentation file
[`product-nutriscore.yaml`](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas-product-nutriscore),
both   in  group   `nutriscore   /   2021  /   data`   and  in   group
`nutriscore_data`. The  only exceptions are  key `saturated_fat_ratio`
which   appears   nowhere  in   this   documentation   file  and   key
`is_fat_oil_nuts_seed`  which appears  in group  `nutriscore /  2023 /
data`, as the comment hints.

Version  1 creates  a class  with  all scalar  properties from  groups
`nutriscore  /  2021   /  data`,  `nutriscore  /  2023   /  data`  and
`nutriscore_data`, while ignoring the structured property `components`
and the additional key `saturated_fat_ratio`.

The tests have shown that  if I ignore property `saturated_fat_ratio`,
the   results  for   `example1.pl`  are   different  from   those  for
`exampl0.pl`:   14   negative   points   instead   of   17.   If   the
`NutriscoreData1` class includes this  property, the computation gives
the proper result.

Which improvements, when compared with plain hashmaps?

* checking the values for strings, integers (including the special case
of integers used as booleans) and reals.

What needs to be done to reach an ideal situation?

* using accessors to get a property and to modify it,

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

* reject any key  which is not declared in the  class (for the moment,
the class  accepts property `saturated_fat_ratio_points`  and property
`saturated_fat_ratio_value`),

* define  the inner  structure  of property  `components`, instead  of
accepting any hashref.

We  can  notice that  module  `Nutriscore1.pm`  is nearly  similar  to
`Nutriscore0.pm`.

License
=======

This  documentation  is  published under  license  CC-BY-SA:  Creative
Commons with attribution and share-alike.
