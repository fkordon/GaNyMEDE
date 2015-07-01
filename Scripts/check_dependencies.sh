#!/bin/bash

#
#    Contact            : Fabrice Kordon (fabrice.Kordon@lip6.fr)
#    Web                : https://github.com/fkordon/GaNyMEDE
#    Description        : "GaNyMEDE" Is a script to ease the deployment
#                          of any web site of MOOC based on metadata describing
#                          a course.
#    Licence            : GPL3
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

DOT_HERE=$(which dot)
if [ -z "$DOT_HERE" ] ; then
	echo
	echo "========================================================="
	echo " WARNING: dot (from graphwiz) should be installed"
	echo "          see http://www.graphviz.org"
	echo "========================================================="
	echo
	exit
fi

PERL_TOMAN=$( perl  -e 'use Roman ; print uc roman(100)')
if [ "$PERL_TOMAN" != "C" ] ; then
	echo
	echo "========================================================="
	echo " WARNING: perl package Roman should be installed "
	echo "          see http://search.cpan.org/~chorny/Roman-1.22/lib/Roman.pm"
	echo "========================================================="
	echo
	exit
fi