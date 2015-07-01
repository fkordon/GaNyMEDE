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

baseDir=$(pwd)
cartoDir=$baseDir/ConstructionData/Cartographie

# Il est possible de paramétrer le fichier de prologue via une variable d'environnement
# (pratique lorsque l'on a plusieurs MOOCs issus du même cours)

do_the_work () {
	if [ -z "$CONSTRAINTS_FILE" ] ; then
		CONSTRAINTS_FILE="contraintes.dot"
	fi

	if [ $# -eq 1 ] ; then
		NUM_SEMAINE=$1
		sed -n $(cat $cartoDir/elements-cours.csv | tr '\t' '@' | cut -d @ -f 2 | grep -n ^${NUM_SEMAINE}$ | cut -d : -f 1 | sed -e 's/$/p/' | tr '\n' ';' ;) $cartoDir/elements-cours.csv | grep -v \# | tr '\t' '@' > /tmp/selected_data.$$
		Target="$cartoDir/cartographie-"$(perl -e 'printf "%0.2d", '$1).dot
		cat $cartoDir/prologue.dot > $Target
		grep sem_${NUM_SEMAINE}_ $cartoDir/$CONSTRAINTS_FILE >> $Target
	else
		# get smallest week number
		NUM_SEMAINE=$(grep -v ^$ $cartoDir/elements-cours.csv | grep -v '#' | cut -f 2 | sort -u | sort -n | head -1)
		### sort -u | sort -n parce que sort -un ou sort -u -n fait sauter les 0 s'il y en a
		cat $cartoDir/elements-cours.csv | tr '\t' '@' | grep -v "^#" | grep -v '^$' > /tmp/selected_data.$$
		Target="$cartoDir/cartographie.dot"
		globalSeqNumber=1
		cat $cartoDir/prologue.dot $cartoDir/$CONSTRAINTS_FILE > $Target
	fi

	echo > $cartoDir/tmp_nodes
	echo > $cartoDir/tmp_links


	cat /tmp/selected_data.$$ | while read LINE ; do
		ID=$(echo $LINE | cut -d '@' -f 1 | cut -d ':' -f 2)
		NUMC=$(echo $LINE | cut -d '@' -f 2)
		NUMS=$(echo $LINE | cut -d '@' -f 3)
		TITRE=$(echo $LINE | cut -d '@' -f 4)
		TYPE=$(echo $LINE | cut -d '@' -f 5)
		DUREE=$(echo $LINE | cut -d '@' -f 6)
		SUCC=$(echo $LINE | cut -d '@' -f 7)
		DEPEND=$(echo $LINE | cut -d '@' -f 8)
		PREREQ=$(echo $LINE | cut -d '@' -f 9)
		MOTSCLEF=$(echo $LINE | cut -d '@' -f 10)
		URLVIDEO=$(echo $LINE | cut -d '@' -f 11)
		if [ "$TYPE" = "DEB" ] ; then
			echo >> $cartoDir/tmp_nodes
			echo $ID' [label="Semaine '$NUM_SEMAINE'\n\n'$TITRE'";fontsize=10;style=filled;fillcolor="#dddddd"]' >> $cartoDir/tmp_nodes
			CUMULDUREE="0"
		elif [ "$TYPE" = "FIN" ] ; then
			echo $ID' [shape="invhouse";label="'$(expr $CUMULDUREE / 60)' mn max\n de vid&eacute;o";style=filled;fillcolor="#dddddd"]' >> $cartoDir/tmp_nodes
			echo >> tmp_nodes
			NUM_SEMAINE=$(expr $NUM_SEMAINE + 1)
		else
			if [ "$globalSeqNumber" ] ; then
				romancounter=$(perl  -e 'use Roman ; print uc roman('$globalSeqNumber')')
				TITRE=$romancounter' - '$TITRE
				globalSeqNumber=$(expr $globalSeqNumber + 1)
			fi
			if [ "$TYPE" = "BASE" ] ; then
				COLOR="#ea9a9a"
			elif [ "$TYPE" = "OPTIONNEL" ] ; then
				COLOR="#9ee19e"
			elif [ "$TYPE" = "DEMONSTRATION" ] ; then
				COLOR="#c08fca"
			elif [ "$TYPE" = "EXERCICE" ] ; then
				COLOR="#ffcc33"
			elif [ "$TYPE" = "ILLUSTRATION" ] ; then
				COLOR="#66ccff"
			fi
			if [ "$URLVIDEO" ] ; then
				echo $ID' [href="'$URLVIDEO'";label="'$TITRE'";fillcolor="'$COLOR'";style=filled;color="'$COLOR'"];' >> $cartoDir/tmp_nodes
			else
				echo $ID' [href="#";label="'$TITRE'";fillcolor="'$COLOR'";style=filled;color="#000000";peripheries=2];' >> $cartoDir/tmp_nodes
			fi
			if [ "$DUREE" ] ; then
				CUMULDUREE=$(expr $CUMULDUREE + $DUREE)
			fi
		fi
	
		for S in $(echo $SUCC | tr ',' ' ') ; do
			echo "$ID -> $S" >> $cartoDir/tmp_links
		done

		for S in $(echo $DEPEND | tr ',' ' ') ; do
			echo "$ID -> $S "'[style="dotted"]' >> $cartoDir/tmp_links
		done
	
	#echo $ID,$NUMC,$NUMS,$TITRE,$TYPE,$DUREE,'('$SUCC'),('$PREREQ'),('$MOTSCLEF'),'$IDVIDEO
	done

	cat $cartoDir/tmp_nodes $cartoDir/tmp_links >> $Target
	echo '}' >> $Target
	rm -f $cartoDir/tmp_nodes $cartoDir/tmp_links /tmp/selected_data.$$

	dot -Tpdf $Target > $cartoDir/$(basename $Target .dot).pdf
}

if [ $# -eq 0 ] ; then
	echo "Generating map for the entire course"
	do_the_work
else
	for arg in $* ; do
		echo "Generating map for chapter/week $arg"
		do_the_work $arg
	done
fi
