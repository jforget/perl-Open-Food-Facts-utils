#!/home/jf/perl5/perlbrew/perls/perl-5.38.2/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test de l'intégration de NutriscoreData avec Nutriscore
# Testing the integration of NutriscoreData with Nutriscore
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
use ProductOpener::Nutriscore0;
use ProductOpener::Nutriscore8;
use ProductOpener::NutriscoreData8;
use Test::More;

my @test_2021 = test_data_2021();
my @test_2023 = test_data_2023();

plan(tests => 4 * @test_2021 + 5 * @test_2023);

for my $nutriscore_data_ref0 (@test_2021) {
  check($nutriscore_data_ref0, 2021);
}

for my $nutriscore_data_ref0 (@test_2023) {
  check($nutriscore_data_ref0, 2023);
}

sub check($nutriscore_data_ref0, $version) {
  my $nutriscore_data_ref8 = ProductOpener::NutriscoreData8->new( %$nutriscore_data_ref0 );

  my ($score0, $grade0) = ProductOpener::Nutriscore0::compute_nutriscore_score_and_grade( $nutriscore_data_ref0, $version );
  my ($score8, $grade8) = ProductOpener::Nutriscore8::compute_nutriscore_score_and_grade( $nutriscore_data_ref8, $version );
  is($score8, $score0, "$version: score is $score8, should be $score0");
  is($grade8, $grade0, "$version: grade is $grade8, should be $grade0");

  my @missing   = ();
  my @different = ();
  for my $key (sort keys %$nutriscore_data_ref0) {
    if ($key eq 'components' or $key eq 'positive_nutrients') {
      next;
    }
    unless ($nutriscore_data_ref8->can($key)) {
      push @missing, $key;
    }
    elsif ($nutriscore_data_ref8->$key ne $nutriscore_data_ref0->{$key}) {
      # numeric test, hoping that no values are alphabetic
      push @different, sprintf("%s (%s <> %s)", $key, $nutriscore_data_ref8->$key, $nutriscore_data_ref0->{$key});
    }
  }
  is(0 + @missing  , 0, "$version: missing keys @missing");
  is(0 + @different, 0, "$version: keys with different values @different");
  if ($version == 2023) {
    my %exist;
    for my $nutrient (@{$nutriscore_data_ref0->{positive_nutrients}}) {
      $exist{$nutrient} ++;
    }
    for my $nutrient (@{$nutriscore_data_ref8->positive_nutrients}) {
      $exist{$nutrient} += 2;
    }
    my @missing = grep { $exist{$_} == 1 } keys %exist;
    my @extra   = grep { $exist{$_} == 2 } keys %exist;
    is(@missing + @extra, 0, "$version positive nutrients, missing: @missing, extra: @extra");
  }
}

sub test_data_2021 {
  return (
     {
      # based on "_id": "0025000044984"
      # Nutrients
        energy        => 192
      , fiber         => 0
      , sugars        => 9.5833333333333
      , saturated_fat => 0
      , sodium        => 0
      , proteins      => 6.7
      , fruits_vegetables_nuts_colza_walnut_olive_oils => 16.14583333333333

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 1
      , is_water              => 0
      , is_cheese             => 0
      , is_fat                => 0 # for 2021 version
    }
    , {
      # based on "_id":"5410556206255"
      # Nutrients
        energy              => 3766
      , sugars              => 0
      , saturated_fat       => 11
      , saturated_fat_ratio => 11
      , sodium              => 0
      , fiber               => 0
      , proteins            => 0
      , fruits_vegetables_nuts_colza_walnut_olive_oils => 0

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 0
      , is_water              => 0
      , is_cheese             => 0
      , is_fat                => 1 # for 2021 version
    }
  );
}

sub test_data_2023 {
  return (
      {
      # based on "_id":"5410556206255"
      # Nutrients
        energy_from_saturated_fat => 407
      , sugars                    => 0
      , saturated_fat_ratio       => 11
      , salt                      => 0
      , fiber                     => 0
      , proteins                  => 0
      , fruits_vegetables_legumes => 0

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 0
      , is_water              => 0
      , is_cheese             => 0
      , is_red_meat_product   => 0
      , is_fat_oil_nuts_seeds => 1 # for 2023 version
    }
    , {
      # based on "_id": "0078742054797",
      # Nutrients
        energy                    => 1272
      , sugars                    => 0
      , saturated_fat             => 10.71
      , salt                      => 7
      , fiber                     => 0
      , proteins                  => 0
      , fruits_vegetables_legumes => 0

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 0
      , is_water              => 0
      , is_cheese             => 0
      , is_red_meat_product   => 1
      , is_fat_oil_nuts_seeds => 0 # for 2023 version
    }
    , {
      # based on "_id": "0025000044984",
      # Nutrients
        energy                    => 192
      , sugars                    => 9.58
      , saturated_fat             => 0
      , salt                      => 0
      , fiber                     => 0
      , proteins                  => 0.83
      , non_nutritive_sweeteners  => 0
      , fruits_vegetables_legumes => 16.1

      # The Nutri-Score computation is different for beverages, waters, cheeses and fats
      , is_beverage           => 1
      , is_water              => 0
      , is_cheese             => 0
      , is_red_meat_product   => 0
      , is_fat_oil_nuts_seeds => 0 # for 2023 version
    }
  );
}

=encoding utf8

=head1 NAME

04-integration.t -- Testing the integration of NutriscoreData with Nutriscore

=head1 USAGE

  prove t8/*.t

=back

=head1 BUGS AND LIMITATIONS

The property C<components> (for version 2023) is not checked.

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
