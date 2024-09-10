#!/bin/sh
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test complet, avec les valeurs habituelles des paramètres
# Full test, with the usual values for the parameters
#
# See the licence in the POD documentation below.
#

export dir_res=results

export base=$1
echo $1


perl schema-check.pl --schema=schemas/product.yaml examples/off* examples/test-errors         > $dir_res/$base-basic
perl schema-check.pl --schema=schemas/product.yaml examples/off* examples/test-errors -l      > $dir_res/$base-listing
perl schema-check.pl --schema=schemas/product.yaml examples/off* examples/test-errors -l -m 1 > $dir_res/$base-dyn
perl schema-check.pl -s schemas/product.yaml examples/example.txt examples/ingredients examples/nova-groups > $dir_res/$base-other
perl schema-check.pl -s schemas/product.yaml examples/products-324.json > $dir_res/$base-324
perl schema-check.pl -s schemas/product.yaml examples/multi*            > $dir_res/$base-multi
perl schema-check.pl -s reduced-schema/chicken.yaml         reduced-schema/chicken-and-egg.data.json > $dir_res/$base-egg
perl schema-check.pl -s reduced-schema/product_meta.yaml    reduced-schema/product_meta.data.json    > $dir_res/$base-meta
perl schema-check.pl -s reduced-schema/parallel-refs.yaml   reduced-schema/parallel-refs.data.json   > $dir_res/$base-parallel
perl schema-check.pl -s reduced-schema/parallel-refs-1.yaml reduced-schema/parallel-refs.data.json   > $dir_res/$base-parallel-1
perl schema-check.pl -s reduced-schema/parallel-refs-2.yaml reduced-schema/parallel-refs.data.json   > $dir_res/$base-parallel-2

perl -n -e 'print if (/^Main schema/ .. eof)' < $dir_res/$base-listing > $dir_res/$base-list-short
perl -n -e 'print if (/^Main schema/ .. eof)' < $dir_res/$base-dyn     > $dir_res/$base-dyn-short

exit;

=begin POD

=encoding utf8

=head1 NAME

full-test.sh -- Full test, with the usual values for the parameters

=head1  DESCRIPTION

Conveniency script to run the tests, using the proper parameters.

Since the parameters are the same from one run to the next, 
this allows the programmer to execute regression tests.

=head1 USAGE

  sh full-test.sh test1
  #
  # make a few modifications in program C<schema-check.pl>
  #
  sh full-test.sh test2
  cd results
  diff test1-basic test2-basic
  diff test1-list-short test2-list-short
  # ...

=head2 Parameter

The basename for the listing files.

=head2 Remark

When requesting the listing of the schema (C<--list-schema> option
for C<schema-check.pl>), the program displays several trace messages
about the processing of C<'$ref'> entries. Since this processing
uses an loop over the keys of a hashtable, the order of the individual
iterations is not constant. Therefore, when invoking C<diff>, you
will find many differences between, say, F<test1-listing> and F<test2-listing>.
This is normal. What would show a regression is differences
within the schema listing part and within the data checking part.

Therefore you should not check

  diff test1-listing  test2-listing
  diff test1-dyn      test2-dyn

but rather
  
  diff test1-list-short test2-list-short
  diff test1-dyn-short  test2-dyn-short

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024, Jean Forget, all rights reserved

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

=end POD
