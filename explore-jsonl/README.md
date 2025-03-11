-*- encoding: utf-8; indent-tabs-mode: nil -*-

explore-jsonl
=============

This directory  contains programs that  read a JSONL file  and extract
all  OFF   documents  matching  some  criteria.   These  programs  are
complements to  `schema-check.pl`, to learn  more about such  and such
special case.

updated-or-modified.pl
----------------------

Read all  Open Food Facts  documents to  check the existence  of field
`last_updated_t`  and to  compare its  value with  the value  of field
`last_modified_t`

See Also
========

The [Open Food Facts blog](https://blog.openfoodfacts.org/)
contains an
[entry](https://blog.openfoodfacts.org/en/news/food-transparency-in-the-palm-of-your-hand-explore-the-largest-open-food-database-using-duckdb-%f0%9f%a6%86x%f0%9f%8d%8a)
about using
[DuckDB](https://duckdb.org/)
to write similar requests.

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Jean Forget

This  repository contains  free  software; you  can redistribute  this
software and  modify it  under the GNU  Affero General  Public License
version 3 or  later (the same as the Open  Food Fact main repository).
See the
[FSF website](https://www.gnu.org/licenses/agpl-3.0.en.html)
or the `LICENSE` file in the root directory of this repository.
