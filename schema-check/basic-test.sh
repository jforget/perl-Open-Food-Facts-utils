#!/bin/sh
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Test basique, avec les valeurs habituelles des paramètres
# Basic test, with the usual values for the parameters
#

perl schema-check.pl --no-schema-listing --schema=schemas/product.yaml examples/*

