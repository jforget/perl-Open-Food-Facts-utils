#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test unitaire des accesseurs dans la classe NutriscoreData
# Unit test for NutriscoreData accessors
#
# Copyright (c) 2025 Jean Forget
#
# See the license in the embedded documentation below
#

use v5.38;
use utf8;
use strict;
use warnings;
use lib qw{ lib ../../openfoodfacts-server/lib/ };
use ProductOpener::NutriscoreData7;
use Test::More;

my @test_data = ( [ 'energy', 518, 520 ], [ 'fiber', 2.2, 2.3 ], [ 'is_cheese', 0, 1 ] );

plan(tests => 5 + 2 * @test_data);

my $nutriscore_data_ref = ProductOpener::NutriscoreData7->new(
  # Nutrients
  energy              =>  518,     # in kJ
  sugars              => 3,
  saturated_fat       => 0.7,
  saturated_fat_ratio => 0.7 / 3 * 100,
  sodium              => 0.61 / 2.5 * 1000,                            # in mg, sodium = salt divided by 2.5
  fruits_vegetables_nuts_colza_walnut_olive_oils => 20,   # in %
  fiber               => 2.2,
  proteins            => 6.7,

  # The Nutri-Score computation is different for beverages, waters, cheeses and fats
  is_beverage => 1,
  is_water    => 0,
  is_cheese   => 0,
  is_fat      => 1, # for 2021 version
  is_fat_oil_nuts_seed => 1, # for 2023 version
);
is($nutriscore_data_ref->energy       , 518);
is($nutriscore_data_ref->fiber        , 2.2);
is($nutriscore_data_ref->saturated_fat, 0.7);

$nutriscore_data_ref->sugars(4);
$nutriscore_data_ref->proteins(7.7);

is($nutriscore_data_ref->sugars  , 4);
is($nutriscore_data_ref->proteins, 7.7);

for my $data (@test_data) {
  my ($nutrient, $old, $new) = @$data;
  is($nutriscore_data_ref->$nutrient, $old);
  $nutriscore_data_ref->$nutrient($new);
}

for my $data (@test_data) {
  my ($nutrient, $old, $new) = @$data;
  is($nutriscore_data_ref->$nutrient, $new);
}


=encoding utf8

=head1 NAME

01-accessors.t -- Unit test for NutriscoreData accessors

=head1 USAGE

  prove t7/*.t

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
