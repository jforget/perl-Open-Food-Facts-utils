# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Tentative pour déclarer une classe pour la variable $nutriscore_data_ref
# Attempt to define a Moose class for variable $nutriscore_data_ref
#
# Copyright (c) 2025 Jean Forget and Association Open Food Facts
#
# See the license in the embedded documentation below
#

package  ProductOpener::NutriscoreDataa;
use Moose;

use Moose::Util::TypeConstraints ;
enum 'ProductOpener::NutriscoreData::grade', [ qw/ a b c d e / ];

has is_beverage           => ( is => 'rw' , isa => 'Bool', required => 0 );
has is_cheese             => ( is => 'rw' , isa => 'Bool', required => 0 );
has is_water              => ( is => 'rw' , isa => 'Bool', required => 0 );
has is_fat                => ( is => 'rw' , isa => 'Bool', required => 0 ); # 2021 version, not in 2023
has is_fat_oil_nuts_seeds => ( is => 'rw' , isa => 'Bool', required => 0 ); # 2023 version, not in 2021
has is_red_meat_product   => ( is => 'rw' , isa => 'Bool', required => 0 ); # 2023 version, not in 2021
# Attributes for the 2021 version, begin
has energy               => ( is => 'rw' , isa => 'Int' , required => 0 );
has energy_points        => ( is => 'rw' , isa => 'Int' , required => 0 );
has energy_points_max    => ( is => 'rw' , isa => 'Int' , required => 0 );
has energy_value         => ( is => 'rw' , isa => 'Int' , required => 0 );
has fiber                => ( is => 'rw' , isa => 'Num' , required => 0 );
has fiber_points         => ( is => 'rw' , isa => 'Int' , required => 0 );
has fiber_points_max     => ( is => 'rw' , isa => 'Int' , required => 0 );
has fiber_value          => ( is => 'rw' , isa => 'Num' , required => 0 );
has fruits_vegetables_nuts_colza_walnut_olive_oils            => ( is => 'rw' , isa => 'Num', required => 0 );
has fruits_vegetables_nuts_colza_walnut_olive_oils_points     => ( is => 'rw' , isa => 'Int', required => 0 );
has fruits_vegetables_nuts_colza_walnut_olive_oils_points_max => ( is => 'rw' , isa => 'Int', required => 0 );
has fruits_vegetables_nuts_colza_walnut_olive_oils_value      => ( is => 'rw' , isa => 'Num', required => 0 );
has proteins             => ( is => 'rw' , isa => 'Num' , required => 0 );
has proteins_points      => ( is => 'rw' , isa => 'Int' , required => 0 );
has proteins_points_max  => ( is => 'rw' , isa => 'Int' , required => 0 );
has proteins_value       => ( is => 'rw' , isa => 'Num' , required => 0 );
has saturated_fat        => ( is => 'rw' , isa => 'Num' , required => 0 );
has saturated_fat_points => ( is => 'rw' , isa => 'Int' , required => 0 );
has saturated_fat_points_max        => ( is => 'rw' , isa => 'Int' , required => 0 );
has saturated_fat_value             => ( is => 'rw' , isa => 'Num' , required => 0 );
has saturated_fat_ratio             => ( is => 'rw' , isa => 'Num', required => 0 ); #  not in docs/api/ref/schema
has saturated_fat_ratio_points      => ( is => 'rw' , isa => 'Int', required => 0 ); #  not in docs/api/ref/schema
has saturated_fat_ratio_points_max  => ( is => 'rw' , isa => 'Int', required => 0 ); #  not in docs/api/ref/schema
has saturated_fat_ratio_value       => ( is => 'rw' , isa => 'Num', required => 0 ); #  not in docs/api/ref/schema
has sodium               => ( is => 'rw' , isa => 'Num' , required => 0 );
has sodium_points        => ( is => 'rw' , isa => 'Int' , required => 0 );
has sodium_value         => ( is => 'rw' , isa => 'Num' , required => 0 );
has sugars               => ( is => 'rw' , isa => 'Num' , required => 0 );
has sugars_points        => ( is => 'rw' , isa => 'Int' , required => 0 );
has sugars_points_max    => ( is => 'rw' , isa => 'Int' , required => 0 );
has sugars_value         => ( is => 'rw' , isa => 'Num' , required => 0 );
# Attributes for the 2021 version, end
# Attributes for the 2023 version, begin
has energy_from_saturated_fat            => ( is => 'rw' , isa => 'Num', required => 0 );
has energy_from_saturated_fat_points     => ( is => 'rw' , isa => 'Int', required => 0 );
has energy_from_saturated_fat_points_max => ( is => 'rw' , isa => 'Int', required => 0 );
has energy_from_saturated_fat_value      => ( is => 'rw' , isa => 'Num', required => 0 );
has fruits_vegetables_legumes            => ( is => 'rw' , isa => 'Num', required => 0 );
has fruits_vegetables_legumes_points     => ( is => 'rw' , isa => 'Int', required => 0 );
has fruits_vegetables_legumes_points_max => ( is => 'rw' , isa => 'Int', required => 0 );
has fruits_vegetables_legumes_value      => ( is => 'rw' , isa => 'Num', required => 0 );
has non_nutritive_sweeteners             => ( is => 'rw' , isa => 'Num', required => 0 );
has non_nutritive_sweeteners_points      => ( is => 'rw' , isa => 'Int', required => 0 );
has non_nutritive_sweeteners_points_max  => ( is => 'rw' , isa => 'Int', required => 0 );
has non_nutritive_sweeteners_value       => ( is => 'rw' , isa => 'Int', required => 0 );
has salt                                 => ( is => 'rw' , isa => 'Num', required => 0 );
has salt_points                          => ( is => 'rw' , isa => 'Int', required => 0 );
has salt_points_max                      => ( is => 'rw' , isa => 'Int', required => 0 );
has salt_value                           => ( is => 'rw' , isa => 'Num', required => 0 );
has positive_nutrients                   => ( is => 'rw' , isa => 'ArrayRef[Str]'
                                              , required => 0
                                              , traits   => ['Array']
                                              , handles  => { positive_nutrients_unshift => 'unshift' }
                                            );
has components                           => ( is => 'rw' , isa => 'Hashref' , required => 0 ); # for the moment, basic type checking
# Attributes for the 2023 version, end
has count_proteins        => ( is => 'rw' , isa => 'Num' , required => 0 ); # in 2023 version, not in 2021
has count_proteins_reason => ( is => 'rw' , isa => 'Str' , required => 0 ); # in 2023 version, not in 2021
has negative_points       => ( is => 'rw' , isa => 'Int' , required => 0 );
has positive_points       => ( is => 'rw' , isa => 'Int' , required => 0 );
has negative_points_max   => ( is => 'rw' , isa => 'Int' , required => 0 );
has positive_points_max   => ( is => 'rw' , isa => 'Int' , required => 0 );
has grade                 => ( is => 'rw' , isa => 'ProductOpener::NutriscoreData::grade', required => 0 );
has score                 => ( is => 'rw' , isa => 'Int'  , required => 0 );

# really useful:  negative_points
#                 positive_points
#                 negative_points_max
#                 positive_points_max
# just for t<n>/03-incr.t, even if it is silly: energy
# (also in t<n>/02-error.t)                     fiber
#                                               proteins
#                                               sugars
#                                               is_cheese
for my $prop (qw / negative_points
                   positive_points
                   negative_points_max
                   positive_points_max
                   energy_from_saturated_fat
                   energy
                   fiber
                   proteins
                   sugars
                   is_cheese /) {
    eval sprintf(<<'EOF', ($prop) x 3);
    sub %s_incr {
      my ($self, $delta) = @_;
      $self->%s( ($self->%s // 0) + ($delta // 1) );
    }
EOF

}

8_000_000;


=encoding utf8

=head1 NAME


=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS


=head1 DEPENDENCIES


=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Jean Forget (jforget on Github).

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Jean Forget and Association Open Food Facts

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
