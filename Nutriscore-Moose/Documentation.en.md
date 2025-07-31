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
actual OFF  function. There is also  in Open Food Facts  some thoughts
about the use of
[PostgreSQL](https://www.postgresql.org/),
but this is a  topic different from the use of  Moose. For the moment,
Moose is about storing transient  program variables, not about storing
permanent data.

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

By the  way, in  the POD documentation,  `is_fat_oil_nuts_seed` should
really be `is_fat_oil_nuts_seeds` with a final "s".

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

In  the  end  (after  writing  version  7),  I  wrote  a  test  script
`04-integration.t` which would compare the results of `Nutriscore7.pm`
with the results  of `Nutriscore0.pm` for the same  input values. This
test script uses very few modules:

* `Test::More` because this a test script,

* `ProductOpener::Nutriscore0` to generate reference data,

* `ProductOpener::Nutriscore7` to generate test data,

* `ProductOpener::NutriscoreData7` because this is the module being tested.

This test script has been retroactively included in versions 1 to 6.

Successive Versions
-------------------

Replacing  hashmaps by  `Moose` is  not a  "all-or-nothing" operation,
especially during  the exploratory phase, but  a step-by-step process.
To allow  a better comparison of  these steps, I have  decided to keep
all versions together as permanent  files, instead of relying on Git's
history mechanism.

Reference version is version 0, which contains:

* module `lib/ProductOpener/Nutriscore0.pm`

* test script `example0.pl`

The first exploratory version contains;

* class `lib/ProductOpener/NutriscoreData1.pm`

* module `lib/ProductOpener/Nutriscore1.pm`

* script `example1.pl`, which  is a test script  for integrating class
lib/PO/ND1.pm with module lib/PO/N1.pm

* test scripts `t1/*.t`,

and  similar for  the following  versions. Version  10 is  tagged with
`"a"` (you are not surprised) and thus contains:

* class `lib/ProductOpener/NutriscoreDataa.pm`

* module `lib/ProductOpener/Nutriscorea.pm`

* script `examplea.pl`, which  is a test script  for integrating class
lib/PO/NDa.pm with module lib/PO/Na.pm

* test scripts `ta/*.t`

And version 16 is tagged with`"g"` (what a surprise!).

Prerequisites
------------

To run the scripts in this directory, you need a clone for this Github
repo, as well as a clone of the
[openfoodfacts-server](https://github.com/jforget/openfoodfacts-server)
repository (mine or
[Open Food Facts' repo](https://github.com/openfoodfacts/openfoodfacts-server)),
in the same directory as the clone of perl-Open-Food-Facts-utils.

You need to install these Perl modules:

* [Moose](https://metacpan.org/pod/Moose) (of course),

* [Log::Any](https://metacpan.org/pod/Log::Any),

* [YAML::XS](https://metacpan.org/dist/YAML-LibYAML/view/lib/YAML/XS.pod),

* [Test::Exception](https://metacpan.org/pod/Test::Exception).

```
git clone https://github.com/jforget/openfoodfacts-server.git
git clone https://github.com/jforget/perl-Open-Food-Facts-utils.git
cpan
install Moose
install Log::Any
install YAML::XS
install Test::Exception
exit
```

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

Much  later, I  realised that the  `$nutriscore_data_ref` variable
was actually described in the comments of `ProductOpener::Nutriscore`,
especially in lines
[149 to 175](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/master/Nutriscore-Moose/lib/ProductOpener/Nutriscore0.pm#L149)
and [494 to 524](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/master/Nutriscore-Moose/lib/ProductOpener/Nutriscore0.pm#L494).
In  this actual  description, there  is  no multi-level  data such  as
`components` like I thought when I was paying attention only to
[`product-nutriscore.yaml`](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas-product-nutriscore),

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of  integers used  as booleans) and  reals (check  effective when
creating an instance).

What needs to be done to reach an ideal situation?

* using accessors to get a property and to modify it,

* checking the values for strings, integers, booleans and reals (check
to be done when updating an instance).

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

* reject any key  which is not declared in the  class (for the moment,
the class  accepts property `saturated_fat_ratio_points`  and property
`saturated_fat_ratio_value`),

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref.

We  can  notice that  module  `Nutriscore1.pm`  is nearly  similar  to
`Nutriscore0.pm`.

Version 2, with accessors
=========================

Class  `NutritionData2.pm` is  nearly similar  to `NutritionData1.pm`,
the only  difference being the  number within  its name. On  the other
hand, the usage of class `NutritionData2.pm` by module `Nutrition2.pm`
is much  different, it uses  accessors instead of the  hashmap syntax.
Yet, for  the moment, accessors are  limited to reading a  property or
updating it with operator "`=`". Updating a property with "`+=`" still
uses the hashmap  syntax. Also, if the property name  is computed, for
example  concatenating variable  `$nutrient`  with string  `'_value'`,
module `Nutrution2.pm` still uses the hashmap syntax.

Problem:  test  script `example2.pl`  does  not  ensure complete  code
coverage, far from it. I have modified many property accesses that are
not checked in this test script.

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of integers used as booleans)  and reals. This check is done both
when creating an instance and when updating it through accessors.

* using accessors  to read a  property with  a hard-coded name  and to
replace its value (after checking it),

What needs to be done to reach an ideal situation?

* using  accessors to  read a  property with  a variable  name and  to
replace its value,

* using accessors to modify a property  in an incremental way (such as
`+=`)

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

* reject any key  which is not declared in the  class (for the moment,
the class  accepts property `saturated_fat_ratio_points`  and property
`saturated_fat_ratio_value`),

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and that it would require jumping through several hoops.

Version 3, indirect method names
================================

No  changes in  classe  `NutriscoreData3` (except  for two  properties
forgotten until now). In module  `Nutriscore3`, the accessor syntax is
extended to the  cases where the method name is  variable (stored in a
Perl  variable  or  computed  with  a formula).  On  the  other  hand,
complicated updates (such as "`+=`" or "`push`") still use the hashmap
syntax.

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of integers used as booleans)  and reals. This check is done both
when creating an instance and when updating it through accessors.

* using accessors to  read a property and to replace  its value (after
checking it),

* reject any key which is not declared in the class,

What needs to be done to reach an ideal situation?

* using accessors to modify a property  in an incremental way (such as
`+=` or `push`),

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and that it would require jumping through several hoops.

Remark:  the missing  properties are  `saturated_fat_ratio_points` and
`saturated_fat_ratio_value`,  following   the  addition   of  property
`saturated_fat_ratio`  in  version 1  to  get  the proper  results  in
`example1.pl`.

Version 4, checking values for property `grade`
===============================================

Just add an `enum`, using the advice from the
[`Moose` documentation](https://metacpan.org/dist/Moose/view/lib/Moose/Manual/Types.pod#TYPE-CREATION-HELPERS)
and, in a lesser way, from
[Stack Overflow](https://stackoverflow.com/questions/473666/does-perl-have-an-enumeration-type)
and
[best pratices](https://metacpan.org/dist/Moose/view/lib/Moose/Manual/BestPractices.pod#Namespace-your-types)
about type names.

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of integers used as booleans)  and reals. This check is done both
when creating an instance and when updating it through accessors.

* using accessors to  read a property and to replace  its value (after
checking it),

* reject  any property  which  is  not declared  in  the class  (check
enabled  when using  an accessor,  not  enabled if  using the  hashmap
syntax),

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

What needs to be done to reach an ideal situation?

* using accessors to modify a property  in an incremental way (such as
`+=` or `push`),

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and that it would require jumping through several hoops.

Version 5, incremental update
=============================

Versions 5 to 7 give some  suggestions for incremental updates such as
"`+=`" and "`-=`" (but not yet "`push`").

Version  5  consists  in  unraveling incremental  updates  into  basic
updates and  then encapsulating these  basic updates. For  example, we
have in succession:

```
$nutriscore_data_ref->{negative_points} +=                                          $points;
$nutriscore_data_ref->{negative_points} = $nutriscore_data_ref->{negative_points} + $points;
$nutriscore_data_ref->negative_points(    $nutriscore_data_ref->negative_points   + $points);
```

It is not pretty, it applies a WET style instead of a DRY style (Write
Everything Twice / Don't Repeat Yourself), but it works.

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of integers used as booleans)  and reals. This check is done both
when creating an instance and when updating it through accessors.

* using  accessors to  read a  property, to  replace its  value (after
checking it) and sometimes to increment it,

* reject  any property  which  is  not declared  in  the class  (check
enabled  when using  an accessor,  not  enabled if  using the  hashmap
syntax),

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

What needs to be done to reach an ideal situation?

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* using accessors  to modify a  array-like property in  an incremental
way (such as `push`),

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and that it would require jumping through several hoops.

Version 6, stylish incremental updates
======================================

In version 6,  updating a property can be done  in two different ways:
replacing the old value with the  new one, using the method homonymous
to the property (as with the  Moose standard), or incrementing the old
value, using a method with a `_incr` suffix.

```
$nutriscore_data_ref->negative_points_incr($points);
```

For a decrement operation "`-=`", you just need to insert a minus sign:

```
$nutriscore_data_ref->negative_points_incr( - $points );
```

Other incremental updates  are not coded in the example  class, but it
is  easy to  copy-paste the  additive methods  into multiplîcative  or
similar methods

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of integers used as booleans)  and reals. This check is done both
when creating  an instance  and when updating  it through  an accessor
replacing the old value by a new one.

* using  accessors to  read a  property, to  replace its  value (after
checking it) and sometimes to increment it,

* reject  any property  which  is  not declared  in  the class  (check
enabled  when using  an accessor,  not  enabled if  using the  hashmap
syntax),

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

What needs to be done to reach an ideal situation?

* checking the values for strings, integers and reals, when a property
is updated by an incrementation accessor,

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* using accessors  to modify a  array-like property in  an incremental
way (such as `push`),

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and that it would require jumping through several hoops.

Version 7, incrementation
=========================

In  this version,  the  incrementation methods  are  not written,  but
generated.  Since  they   come  from  a  code   generation,  the  code
duplication  that was  bad  in version  5  is no  longer  bad here.  A
positive  result  is  that  now,  type checking  is  done  during  the
incrementation.

Another  new feature  is  that  the incrementing  value  is no  longer
mandatory and its default value is 1.

While doing this  test, I noticed that I needed  to declare properties
`negative_points_max` and  `positive_points_max`, which  are commented
neither in
[`Nutriscore.pm` lines 494 to 524](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/master/Nutriscore-Moose/lib/ProductOpener/Nutriscore0.pm#L494)
nor in
[`product-nutriscore.yaml`](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-v2/#cmp--schemas-product-nutriscore).
If the code coverage had been  more extensive, it would have triggered
a program error when using the corresponding increment method.

I am surprised that Moose contains no facilities to generate increment
methods.
[Metacpan](https://metacpan.org/search?q=moose+increment)
gives me no useful results and the (French-speaking) search engine
[Qwant](https://www.qwant.com/?q=perl+moose+incr%C3%A9mentation&t=web&llm=2)
answers with a flash answer which translates to

> Moose provides some  facilities to manage Perl  classes, by defining
> attributes with accessor methods and bespoke traits, but it does not
> provide  directly an  incrementation feature;  this feature  must be
> implemented through a  specific method or using an  attribute with a
> builder which can manage automatic incrementation.

Can we trust the artificial intelligence that wrote this flash answer?
It does not matter. In the end, I generated the incrementation methods
in the class.

Which improvements, when compared with plain hashmaps?

* checking  the values  for strings,  integers (including  the special
case of integers used as booleans)  and reals. This check is done both
when creating  an instance  and when updating  it through  an accessor
(replacement or incrementation).

* using  accessors to  read a  property, to  replace its  value (after
checking it) and sometimes to increment it (with type check),

* reject  any property  which  is  not declared  in  the class  (check
enabled  when using  an accessor,  not  enabled if  using the  hashmap
syntax),

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

What needs to be done to reach an ideal situation?

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* same thing with property  `positive_nutrients`, which for the moment
accepts any arrayref,

* using accessors  to modify a  array-like property in  an incremental
way (such as `push`),

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and  that  it would  require  jumping  through  several hoops.  Is  it
possible to  fill these  properties with  `undef` instead  of deleting
them?

Version 8, 2023 algorithm
=========================

Version 8 is  just an attempt to improve code  coverage, especially by
using the 2023 version of nutriscore.

This required a bunch of modifications, a big one if measured as lines
of code, yet a small one on the concept level.

* Adding several attributes  dealing with nutrients that  are not used
in version 2021 or that have a different name.

* Adding an `xxx_points_max` attribute for each nutrient.

* Adding a  default value  to each  required attribute  (spoiler: this
update will be rolled back in version 10).

I  do  not give  the  comparisons  with  hashmaps  and with  an  ideal
situation, they are the same as in version 7.

Code coverage has improved when compared to version 7, but it is still
partial. You can check with:

```
cover --delete
PERL5OPT=-MDevel::Cover prove t8/*
cover
firefox cover_db/coverage.html &
```

I  do not  strive  to obtain  a  100% code  coverage.  Doing so  would
generate quirks associated with
[Goodhart's](https://fourweekmba.com/goodharts-law/)
[law](https://xkcd.com/2899/).
Moreover, as I explained (in French) during the
[French Perl Workshop in 2015](https://journeesperl.fr/fpw2015/talk/6309),
a 100% code coverage is no  warranty for the complete absence of bugs.
On the other hand, as I explained (in French) during the
[French Perl Workshop in 2013](http://www.youtube.com/watch?v=eXRPWdoLBzA),
improving  code coverage,  even if  we  do not  reach 100%,  sometimes
exposes bugs that would have kept  un-noticed else. See lines 779, 784
and 787 of
[Nutriscore7.pm](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/8d2629f533e6bae0e1dda412da7bd4e6569e1377/Nutriscore-Moose/lib/ProductOpener/Nutriscore7.pm#L779)
and
[Nutriscore8.pm](https://github.com/jforget/perl-Open-Food-Facts-utils/blob/8d2629f533e6bae0e1dda412da7bd4e6569e1377/Nutriscore-Moose/lib/ProductOpener/Nutriscore8.pm#L779)

As for
[issue 12172](https://github.com/openfoodfacts/openfoodfacts-server/issues/12172),
at first I had included fuctions
`get_value_with_one_less_negative_point` and
`get_value_with_one_more_positive_point` in the test scripts, which
would implicitly add `get_value_with_one_less_negative_point_2023` and
`get_value_with_one_more_positive_point_2023` to the covered code.
Unfortunately, these functions were buggy and they would crash the
test script. So I replaced them in the test script by a direct call to
functions `xxx_2023` and I submitted
[issue 12172](https://github.com/openfoodfacts/openfoodfacts-server/issues/12172).
The Open Food Facts team then decided to
[remove](https://github.com/openfoodfacts/openfoodfacts-server/pull/12176/commits/ec66bff057c4692ca61eb56775374be387865838)
functions `get_value_with_one_less_negative_point` and
`get_value_with_one_more_positive_point`.

Version 9, array `positive_nutrients`
=====================================

This  version aims  at  eliminating the  hashmap  syntax for  property
`positive_nutrients`.  There is  a single  remaining one,  a `unshift`
with string value  `"proteins"`. Also, we want type  checking for each
element of the array.

I have used the following pages:

* [Stack overflow](https://stackoverflow.com/questions/3487559/accessing-a-moose-array),

* [the Moose manual](https://metacpan.org/dist/Moose/view/lib/Moose/Manual/Delegation.pod#NATIVE-DELEGATION).

Which improvements, when compared with plain hashmaps?

* checking  the  values  for   scalar  properties:  strings,  integers
(including the special  case of integers used as  booleans) and reals.
This check is done both when creating an instance and when updating it
through an accessor (replacement or incrementation).

* using  accessors to  read a  scalar property,  to replace  its value
(after checking it) and sometimes to increment it (with type check),

* checking list properties,  by applying a type check  to each element
of the list,

* using accessors  to read a  list property,  to replace its  value by
overwriting it or by incrementally updating it (e.g. `unshift`),

* reject  any property  which  is  not declared  in  the class  (check
enabled  when using  an accessor,  not  enabled if  using the  hashmap
syntax),

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

What needs to be done to reach an ideal situation?

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and  that  it would  require  jumping  through  several hoops.  Is  it
possible to  fill these  properties with  `undef` instead  of deleting
them? Yet, this update to `undef` may trigger problems with properties
declared as mandatory.

Version 10, no default values
=============================

The addition of  default values in version 8 was  necessary to prevent
warning  messages  when calling  a  `xxx_incr`  method on  a  property
undefined or  not existing in  the `PO::ND` instance. By  refining the
coding of these  `xxx_incr` methods, the default values  are no longer
necessary and missing  nutrients now have an `undef`  value instead of
`0`.

Which improvements, when compared with plain hashmaps?

* checking  the  values  for   scalar  properties:  strings,  integers
(including the special  case of integers used as  booleans) and reals.
This check is done both when creating an instance and when updating it
through an accessor (replacement or incrementation).

* using  accessors to  read a  scalar property,  to replace  its value
(after checking it) and sometimes to increment it (with type check),

* checking list properties,  by applying a type check  to each element
of the list,

* using accessors  to read a  list property,  to replace its  value by
overwriting it or by incrementally updating it (e.g. `unshift`),

* reject  any property  which  is  not declared  in  the class  (check
enabled  when using  an accessor,  not  enabled if  using the  hashmap
syntax),

* stricter checks on  property `grade`, which should  be "`a`", "`b`",
"`c`", "`d`" or "`e`" and nothing else,

What needs to be done to reach an ideal situation?

* encapsulation:  forbid  accesses  to properties  using  the  hashmap
syntax, now only accessors are allowed,

* imagine how a multi-level structured data such as `components` would
be implemented, instead of accepting any hashref,

* decide  on the  deletion of  some properties  (ses `Nutriscore0.pm`,
lines 861 to 871); I doubt that  this would be allowed in standard OOP
and  that  it would  require  jumping  through  several hoops.  Is  it
possible to  fill these  properties with  `undef` instead  of deleting
them?

License
=======

This  documentation  is  published under  license  CC-BY-SA:  Creative
Commons with attribution and share-alike.
