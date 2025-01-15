#!/usr/bin/env perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Vérifie qu'un document est compatible avec la syntaxe YAML
# Check that a document is compatible with the YAML syntax
#
# Copyright (c) 2025 Jean Forget
#
# See the license in the embedded documentation below
#

use v5.38;
use utf8;
use strict;
use warnings;
use open OUT => ':encoding(UTF-8)';

use YAML;
use YAML::XS;
use File::Find;

for my $arg (@ARGV) {
  if (-d $arg) {
    find( sub { if ($_ =~ /.ya?ml$/) { check($_, $File::Find::name) } }, $arg);
  }
  else {
    check($arg, $arg);
  }
}

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  local $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}

sub check($fname, $path) {
  $@ = '';
  eval {
    #YAML::Load(slurp($fname));
    YAML::XS::Load(slurp($fname));
  };
  if ($@) {
    say "$path incorrect syntax, $@";
  }
  else {
    say "$path              correct syntax";
  }
}


=encoding utf8

=head1 NAME

yaml-check.pl -- checking that a document is compatible with the YAML syntax

=head1 VERSION

Version 0.01

=head1 USAGE

  perl yaml-check.pl file1 [ file2 [ directory3]]

=head1 REQUIRED ARGUMENTS

One or more filenames or directory names.

=head1 OPTIONS

None.

=head1 DESCRIPTION

When dealing with a filename, the program only checks the YAML syntax
within this file and displays the result.

When dealing with  a directory name, the program  scans this directory
and all sub-directories  looking for YAML filenames  (according to the
filename extension). For each file, the program checks the YAML syntax
and displays the result.

=head1 DEPENDENCIES

This Perl program requires Perl 5.38 or greater.

Modules used (outside the core): C<YAML> and C<YAML::XS>

=head1 CONFIGURATION

To choose between C<YAML> and C<YAML::XS>, you have to edit the source
file,  go  to  C<sub  check> and  uncomment  either  C<YAML::Load>  or
C<YAML::XS::Load> while commenting out the other.

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
