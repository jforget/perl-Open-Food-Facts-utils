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

* a third module, the name of which I have forgotten.

On the following  days, I tried to install Moose  on a virtual machine
running  xubuntu-25.04 and  Perl  5.40.1, on  another virtual  machine
running  Fedora-41 and  Perl 5.40.2  and on  my main  computer running
Devuan  and   Perl  5.38.2  through  `perlbrew`   (or  5.32.1  without
`perlbrew`). I did not reproduce the problem in these three cases. For
example, the absence of `DateTime` causes a `SKIP` in the tests, not a
test failure which prevents the installation of `Moose`.

License
=======

This  documentation  is  published under  license  CC-BY-SA:  Creative
Commons with attribution and share-alike.
