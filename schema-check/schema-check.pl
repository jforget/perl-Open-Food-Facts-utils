#!/usr/bin/env perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Vérifie qu'un document est compatible avec le schéma de données
# Check that a document is compatible with the data schema
#
# Copyright (c) 2024 Jean Forget
#
# See the licence in the embedded documentation below
#

use v5.38;
use utf8;
use strict;
use warnings;
use open OUT => ':encoding(UTF-8)';

use YAML;
use YAML::Node;
use JSON::PP;
use Getopt::Long;
use File::Basename;
use File::Spec::Functions;

my $dir_sch = '/home/jf/Documents/prog/perl/openfoodfacts-server/docs/api/ref/schemas';
my $f_sch   = 'product.yaml';
my $schema_file = catfile($dir_sch, $f_sch);
my $list_schema = 0;
my $max_depth   = 5;
my @dyn_sch_to_do   = ();

GetOptions("schema=s"       => \$schema_file
         , "list-schema"    => \$list_schema
         , "max-depth=i"    => \$max_depth
    )
  or die "Error in command line options";
$dir_sch = dirname($schema_file);

my @data_files;
if (@ARGV) {
  @data_files = @ARGV;
}
elsif (!$list_schema) {
  die "Please give the pathname for at least one JSON data file";
}

my $json_parser = JSON::PP->new->allow_singlequote(1)->allow_barekey(1);
my %dyn_schema = ();
my $schema = YAML::Load(slurp($schema_file));
$schema->{properties}{_id} = { type => 'string', description => 'Autogenerated by MongoDB' };

find_ref_rec($schema, $dir_sch, $schema_file, 1);

if ($schema->{allOf}) {
  for my $entry (@{$schema->{allOf}}) {
    my $fname = $entry->{'$ref'};
    my $path  = catfile($dir_sch, $fname);
    if ($list_schema) {
      say "processing 1 $path";
    }
    my $subschema = YAML::Load(slurp($path));
    find_ref_rec($subschema, $dir_sch, $fname, 1);
    #say JSON::PP::encode_json($subschema);
    for my $prop_name (keys %{$subschema->{properties}}) {
      #say "adding $prop_name";
      $schema->{properties}{$prop_name} = $subschema->{properties}{$prop_name};
    }
    for my $pattern (keys %{$subschema->{patternProperties}}) {
      #say "adding $pattern";
      $schema->{patternProperties}{$pattern} = $subschema->{patternProperties}{$pattern};
    }
  }
}

$schema = tweak_hash($schema);

while (my $entry = pop @dyn_sch_to_do) {
  my $dir   = $entry->{dir};
  my $fname = $entry->{fname};
  my $level = $entry->{level};
  my $ref   = $entry->{full_ref};
  my @keys  = split('/', substr($ref, 1 + index($ref, '#')));
  my $path  = catfile($dir, $fname);
  if ($list_schema) {
    say "processing $level $path $ref";
  }
  unless ($dyn_schema{$ref}) {
    my $subschema = YAML::Load(slurp($path));
    for my $key (@keys) {
      $subschema = $subschema->{$key};
    }
    find_ref_rec($subschema, $dir_sch, $fname, $level);
    $dyn_schema{$ref}{schema} = tweak_hash($subschema);
  }
}

if ($list_schema) {
  say '-' x 50;
  say "Main schema";
  say '-' x 50;
  say YAML::Dump($schema);
  say '-' x 50;
  say "Dynamically inserted subschema(s)";
  say '-' x 50;
  say YAML::Dump(\%dyn_schema);
}

for my $fname (@data_files) {
  open my $f, '<', $fname
    or die "opening $fname $!";
  my $state = 'A';
  my $doc   = '';
  while (my $line = <$f>) {
    if ($state eq 'A') {
      if ($line =~ /\A \{ \Z/x) {
        $doc   = $line;
        $state = 'B';
      }
      elsif ($line =~ /\A \[ \Z/x) {
        $doc   = $line;
        $state = 'C';
      }
      elsif ($line =~ /\A \{ .* \} \Z/x) {
        check_json($line, $fname);
      }
    }
    elsif ($state eq 'B') {
      $doc .= $line;
      if ($line =~ /\A \} \Z/x) {
        check_json($doc, $fname);
        $state = 'A';
      }
    }
    else {
      $doc .= $line;
      if ($line =~ /\A \] \Z/x) {
        check_json_array($doc, $fname);
        $state = 'A';
      }
    }
  }
  close $f
    or die "closing $fname $!";
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

sub find_ref_rec($schema, $dir, $fname, $level) {

  # basic schema entry (no loop for '$ref' entry)
  if ($schema->{properties}) {
    for my $key (keys %{$schema->{properties}}) {
      find_ref_rec( $schema->{properties}{$key}, $dir, $fname, $level);
    }
  }
  if ($schema->{items}) {
    find_ref_rec( $schema->{items}, $dir, $fname, $level);
  }

  my $ref = $schema->{'$ref'} // '';
  if ($ref eq '') {
    return;
  }

  # now we are dealing only with a '$ref' schema entry
  my $full_ref = '';
  my $path     = '';
  my $hier     = '';
  if (index($ref, '#') >= 0) {
    ($path, $hier) = $ref =~ / ^ (.*) (\#.*) $/x;
  }
  else {
    $path = $ref;
    $hier = '#/';
  }
  if ($path eq '') {
    $path = catfile($dir, $fname);
  }
  else {
    my $sub_dir = '';
    ($sub_dir, $fname) = "./$path" =~ / ^ (.*) \/ (.*) $ /x;
    $dir  = catdir( $dir, $sub_dir);
    $path = catfile($dir, $fname);
  }
  $full_ref = "$path$hier";

  my $new_level = $level + 1;
  my $entry = { ref      => $ref
              , dir      => $dir
              , fname    => $fname
              , path     => $path
              , full_ref => $full_ref
              , level    => $new_level
  };
  if ($list_schema) {
    say YAML::Dump($entry);
  }
  if ($new_level > $max_depth) {
    say "Break the recursivity (dir $dir, fname $fname, ref $full_ref)";
    push @dyn_sch_to_do, $entry;
    $schema->{dyn_sch} = $full_ref;
    return;
  }

  if ($list_schema) {
    say "processing $new_level $path";
    say $full_ref;
  }
  my $subschema = YAML::Load(slurp($path));
  my @keys  = split('/', substr($full_ref, 1 + index($full_ref, '#')));
  for my $key (@keys) {
    if ($key) {
      $subschema = $subschema->{$key};
    }
  }
  my $subpath = dirname($fname);
  for my $prop_name (keys %{$subschema->{properties}}) {
    find_ref_rec( $subschema->{properties}{$prop_name}, catdir($dir, $subpath), $fname, $new_level);
  }
  if ($subschema->{items}) {
    find_ref_rec( $subschema->{items}, catdir($dir, $subpath), $fname, $new_level);
  }
  if ($subschema->{type}) {
    $schema->{type} = $subschema->{type};
  }
  if ($subschema->{items}) {
    $schema->{items} = $subschema->{items};
  }
  for my $prop_name (keys %{$subschema->{properties}}) {
    #say "adding $prop_name";
    $schema->{properties}{$prop_name} = $subschema->{properties}{$prop_name};
  }
  for my $pattern (keys %{$subschema->{patternProperties}}) {
    #say "adding $pattern";
    $schema->{patternProperties}{$pattern} = $subschema->{patternProperties}{$pattern};
  }
}

# Ensure that the "type" property is dumped first
sub tweak_hash($schema) {
  my $ynode = YAML::Node->new($schema);
  my @keys = keys %$schema;
  if (exists $schema->{type}) {
    ynode($ynode)->keys( [ 'type', sort grep { $_ ne 'type' } @keys ] );
  }
  if (exists $schema->{patternProperties}) {
    for my $pat (keys %{$ynode->{patternProperties}}) {
      $ynode->{patternProperties}{$pat} = tweak_hash($ynode->{patternProperties}{$pat});
    }
  }
  if (exists $schema->{properties}) {
    for my $prop (keys %{$ynode->{properties}}) {
      $ynode->{properties}{$prop} = tweak_hash($ynode->{properties}{$prop});
    }
  }
  if (exists $schema->{items}) {
    $ynode->{items} = tweak_hash($ynode->{items});
  }
  return $ynode;
}

sub check_json_array($json, $fname) {
  my $data = '';
  eval { $data = $json_parser->decode($json); };
  if ($@) {
    say '?' x 50;
    say "Invalid JSON";
    say $@;
    say '?' x 50;
    return;
  }
  for my $datum (@$data) {
    say '-' x 50;
    say join ' ', $fname, $datum->{code} // $datum->{_id} // '???';
    say '-' x 50;
    check_hash($datum, 'top', $schema);
  }
}

sub check_json($json, $fname) {
  #my $data = JSON::PP::decode_json($json);
  my $data = '';
  eval { $data = $json_parser->decode($json); };
  if ($@) {
    say '?' x 50;
    say "Invalid JSON";
    say $@;
    say '?' x 50;
    return;
  }
  say '-' x 50;
  say join ' ', $fname, $data->{code} // $data->{_id} // '???';
  say '-' x 50;
  check_hash($data, 'top', $schema);
}

sub check_hash($data, $stack, $schema) {
  if (ref($data) ne 'HASH') {
    say "invalid data, should be a hash ref ($stack)";
    return;
  }
  unless ($schema->{patternProperties} or $schema->{properties}) {
    say "Invalid schema, no properties defined for $stack";
    return;
  }
  for my $key (sort keys %$data) {
    #say "checking $key";
    my $found_in_prop = 0;
    my $found_in_patt = 0;
    if ($schema->{properties}{$key}) {
      $found_in_prop = 1;
    }
    else {
      for my $patt (keys %{$schema->{patternProperties}}) {
        if ($key =~ /^ $patt $/x) {
          #say "matching $key -> $patt, ($stack)";
          $found_in_patt = 1;
          last;
        }
      }
    }
    if ($found_in_patt == 1) {
      # All pattern properties are strings, no need to check more
      next;
    }
    if ($found_in_prop == 0) {
      say "invalid property $key ($stack)";
      next;
    }
    if ($schema->{properties}{$key}{dyn_sch}) {
      my $dyn_sch = $schema->{properties}{$key}{dyn_sch};
      my $dynamic_schema = $dyn_schema{$dyn_sch}{schema};
      if ($dynamic_schema->{type} eq 'object') {
        check_hash($data->{$key}, "$stack $key", $dynamic_schema);
        next;
      }
      if ($dynamic_schema->{type} eq 'array') {
        check_array($data->{$key}, "$stack $key", $dynamic_schema);
        next;
      }
      say "Invalid dynamic sub-schema $dyn_sch, no item type for $stack";
      next;
    }
    if (not exists $schema->{properties}{$key}{type}) {
      say "Invalid schema, no type defined for property $key ($stack)";
      next;
    }
    if ($schema->{properties}{$key}{type} eq 'object') {
      check_hash($data->{$key}, "$stack $key", $schema->{properties}{$key});
    }
    if ($schema->{properties}{$key}{type} eq 'array') {
      check_array($data->{$key}, "$stack $key", $schema->{properties}{$key});
    }

  }
}

sub check_array($data, $stack, $schema) {
  if (ref($data) ne 'ARRAY') {
    say "invalid data, should be an array ref ($stack)";
    return;
  }
  if ($schema->{items}{dyn_sch}) {
    my $dyn_sch = $schema->{items}{dyn_sch};
    my $dynamic_schema = $dyn_schema{$dyn_sch}{schema};
    if ($dynamic_schema->{type} eq 'object') {
      my $n = 0;
      for my $datum (@$data) {
        check_hash($datum, "$stack [$n]", $dynamic_schema);
        $n++;
      }
      return;
    }
    if ($dynamic_schema->{type} eq 'array') {
      my $n = 0;
      for my $datum (@$data) {
        check_array($datum, "$stack [$n]", $dynamic_schema);
        $n++;
      }
      return;
    }
    say "Invalid dynamic sub-schema $dyn_sch, no item type for $stack";
    return;
  }
  if (not exists $schema->{items}{type}) {
    say "Invalid schema, no item type for $stack";
  }
  elsif ($schema->{items}{type} eq 'object') {
    my $n = 0;
    for my $datum (@$data) {
      check_hash($datum, "$stack [$n]", $schema->{items});
      $n++;
    }
  }
  elsif ($schema->{items}{type} eq 'array') {
    my $n = 0;
    for my $datum (@$data) {
      check_array($datum, "$stack [$n]", $schema->{items});
      $n++;
    }
  }
}

=encoding utf8

=head1 NAME

schema-check.pl -- checking that a document is compatible with the data schema

=head1 VERSION

Version 0.01

=head1 USAGE

  perl schema-check.pl [--schema=schemas/product.yaml] [--list-schema] data1 [data2 data3]

=head1 REQUIRED ARGUMENTS

One or more filenames where the JSON documents are stored (as plain text, UTF-8).

Note:  if  using  the  C<--list-schema>   option,  you  may  omit  the
filenames.

=head1 OPTIONS

=head2 C<--schema>

Pathname of a YAML file describing the schema of the data.

The default value is the pathname for
F<docs/api/ref/schemas/product.yaml> from the local work copy of the
C<openfoodfacts-server> repository.

Allowing the user to specify another file has two purposes:

=over 4

=item  * In  case  the C<openfoodfacts-server>  repository contains  a
(temporarily)  erroneous  schema,  the   user  can  copy  this  schema
elsewhere, fix it and use it.

=item * For test purposes, the user may use a much simpler schema.

=back

=head2 C<--list-schema>

By default,  the program does not  list the full data  schema. If this
option is  activated, the  schema is  displayed before  displaying the
error messages for the JSON documents.

Note: if  this option  is activated, the  filename arguments  for JSON
data  are now  optional. The  program will  still produce  interesting
information in its standard output.

=head2 C<--max-depth>

Integer  option, to  control the  choice between  static insertion  of
subschemas and dynamic insertion of subschemas.

Default value is 5, so with schema C<product.yaml>, all insertions are
static, except for recursive insertion of C<ingredient.yaml>.

=head1 DESCRIPTION

The program  loads a YAML file  containing the schema of  the database
documents. If necessary, it loads  also other YAML files referenced by
the  first file  and merges  them. Then  the program  prints the  full
schema (this printing is optional).

In a  second step, the program  reads one or several  files containing
JSON documents  and checks their  data to  ensure they match  the data
schema. Any errors are printed on standard output.

=head1 CONFIGURATION AND ENVIRONMENT

The pathname for the default schema  is hard-coded in the program. You
should enter I<your> hard-coded value instead of mine when you install
the program on your computer.

I know,  this is not  a good  practice. But I  did not want  to bother
about adding the processing of a configuration file.

=head1 DEPENDENCIES

This Perl program requires Perl 5.38 or greater.

Modules used (outside the core):

=over 4

=item * C<YAML>

=item * C<YAML::Node>

=item * C<JSON::PP>

=back

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Jean Forget (jforget on Github).

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2024 Jean Forget

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
