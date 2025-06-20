#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test unitaire des contrôles dans la classe NutriscoreData
# Unit test for checks inside class NutriscoreData
#
# Copyright (c) 2025 Jean Forget
#
# See the license in the embedded documentation below
#

use v5.38;
use utf8;
use strict;
use warnings;
use lib qw{ . ../../openfoodfacts-server/lib/ };
use ProductOpener::Nutriscore2 qw/:all/;
use YAML::XS;

say "deliberate error on missing properties 'energy' and 'fiber'";
eval {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
};
say $@ if $@;

say "deliberate value error on 'energy' property";
eval {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    energy              =>  518.1,     # in kJ, should be integer
    fiber               => 2.2,
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
};
say $@ if $@;

say "deliberate value error on 'is_beverage' property";
eval {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    energy              =>  518,     # in kJ
    fiber               => 2.2,
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    is_beverage         => 2,                               # boolean = 2 ??!!!
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
};
say $@ if $@;

say "no error in this version on property 'grade'";
eval {
  my $nutriscore_data_ref = ProductOpener::NutriscoreData2->new(
    energy              =>  518,     # in kJ
    fiber               => 2.2,
    proteins            => 6.7,
    saturated_fat       => 0.7,
    sodium              => 0.61 / 2.5 * 1000,               # in mg, sodium = salt divided by 2.5
    sugars              => 3,
    grade               => 'z',                             # grade beyond 'e' ??!!!
    saturated_fat_ratio => 0.7 / 3 * 100,
    fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  );
};
say $@ if $@;


=encoding utf8

=head1 NAME

example-error2.pl -- Unit test for NutriscoreData class

=head1 USAGE

  perl example-error2.pl

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Jean Forget (jforget on Github).

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Jean Forget

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
