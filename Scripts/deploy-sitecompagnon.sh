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

display_usage() {
	echo "usage : $0 [-help] [-debug -leger]"
	echo "       -help : cette aide en ligne (avorte l'exécution)"
}

format_number() {
	perl -e 'printf "%0.2d", '$1
}

if [ "$1" = "-help" ] ; then
	display_usage
	exit 0
fi

gen_cartographie() {
	fname=$(basename $(basename $1) .dot)
	# pdf
	dot -Tpdf $1 > $webDir/pdf/$fname.pdf
	# svg
	dot -Tsvg $1 -Gcharset=latin1 | sed -n '7,$p' > $webDir/svg/$fname.svg
	# il faut enlever les 6 premieres lignes pour inserer le svg produit dans une page web ensuite
}

source ./Scripts/check_dependencies.sh

# pour créer des archives sans fichiers parasites(sous MacOS)...
export COPYFILE_DISABLE=true

######################################################################
# constantes pour le déployement en local d'une copie du site

baseDir=$(pwd)
dataDir=ConstructionData
cartoDir=$dataDir/Cartographie
webDir=WebSite
webPdfDir=$webDir/pdf
webDataDir=$webDir/data
webcontentDir=$webDir/content
webfunctionDir=$webDir/functions
webTdmDir=$webDir/TdM
syllDir=$dataDir/Syllabus-MOOC

source $syllDir/configure-mooc.sh

rm -f $webDataDir/*

LISTE_SEMAINES=$(grep -a -v ^# $cartoDir/elements-cours.csv | cut -f 2 | sort -u | sort -n)
### sort -u | sort -n parce que sort -un ou sort -u -n fait sauter les 0 s'il y en a

######################################################################
# preparation du fichier de metadonnees dans le repertoire des chapitres

echo "Dispatching global metadata"
echo -n "   "
for semaine in $LISTE_SEMAINES  ; do
	formatted_semaine=$(format_number $semaine)
	EXO=""
	echo -n "."
	if [ -f $dataDir/semaine-$formatted_semaine.csv ] ; then
		rm -f $dataDir/semaine-$formatted_semaine.csv
	fi
	liste_elem=$(cut -f 2 $cartoDir/elements-cours.csv | grep -a -n ^${semaine}$ | cut -d ':' -f 1)
	for elem in $liste_elem ; do
		sed -n ${elem}p $cartoDir/elements-cours.csv >> $dataDir/semaine-$formatted_semaine.csv
	done
	# generation de la page principale de la semaine sur le site compagnon...
	if [ ! -f $dataDir/resumes/resume-$formatted_semaine.html ] ; then
		echo
		echo "Le résumé $dataDir/resume-$formatted_semaine.html n'existe pas"
		exit 1
	fi
	echo '<h1>R&eacute;sum&eacute; de la semaine</h1>' > $webcontentDir/semaine-$formatted_semaine.html
	cat $dataDir/resumes/resume-$formatted_semaine.html >> $webcontentDir/semaine-$formatted_semaine.html
	liste_exo=$(cut -f 5 $dataDir/semaine-$formatted_semaine.csv | grep -a -n ^EXERCICE$ | cut -d ':' -f 1)
	if [ "$liste_exo" ] ; then
		echo '<h1>Mise en pratique des connaissances</h1>' >>  $webcontentDir/semaine-$formatted_semaine.html
		for exo in $liste_exo ; do
			if [ -z "$EXO" ] ; then
				EXO="Un exercice est propos&eacute; cette semaine. "
			else
				EXO="Des exercices sont propos&eacute;s cette semaine. "
			fi
		done
		echo '<p>'$EXO'Un lien vers la pr&eacute;sentation orale de ces exercices, de m&ecirc;me'  >>  $webcontentDir/semaine-$formatted_semaine.html
		echo 'que les vid&eacute;os de l&#x27;application t&eacute;moin sont accessibles'  >>  $webcontentDir/semaine-$formatted_semaine.html
		echo 'ci-dessous:</p>' >>  $webcontentDir/semaine-$formatted_semaine.html
		echo '<ul>' >>  $webcontentDir/semaine-$formatted_semaine.html
		for exo in $liste_exo ; do
			LINE=$(sed -n ${exo}p $dataDir/semaine-$formatted_semaine.csv)
			numseq=$(echo "$LINE" | cut -f 3)
			exoname=$(echo "$LINE" | cut -f 4 | sed -e s'/\\\\n/ /g')
			echo '<li><a href="index.php?C='$formatted_semaine'&amp;S='$(format_number $numseq)'">'$exoname'</a></li>' >>  $webcontentDir/semaine-$formatted_semaine.html
		done
		echo '</ul>' >>  $webcontentDir/semaine-$formatted_semaine.html
	fi
	echo '<h1>La carte de la semaine</h1>' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo '<p>Elle est &eacute;galement disponible <a href="pdf/cartographie-'$formatted_semaine'.pdf">ici au format pdf</a>.' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo 'Vous pouvez acc&eacute;der aux s&eacute;quences et aux informations qui y sont associ&eacute;es' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo 'soit par le biais de la carte, soit via la table des mati&egrave;res ci-contre. La signification des' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo 'codes de couleur est situ&eacute;e juste apr&egrave; la carte.' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo '<div align="center"><?php	include("svg/cartographie-'$formatted_semaine'.svg");?></div>' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo '<?php 	include("content/legende-signalisation.html");?>' >>  $webcontentDir/semaine-$formatted_semaine.html
	echo '<?php
$level1='$semaine';

// definition des valeurs par defaut des parametres
$level2=0;
$level3=-1;
$HEADER="";
$TITLE="";
$CONTENT="";
$cours="";
$sequence="";
$DEEPPAGETITLE="";
$DEEPPAGEFLOAT="semaine-'$formatted_semaine'.html";

include ("functions/content.php");
?>
'> $webDir/semaine-$formatted_semaine.php
	echo '<div class="TdMl1">S&eacute;quences de la semaine</div>' > $webTdmDir/semaine-$formatted_semaine.html
done
echo


######################################################################
# générer les fonctions php utilisées pour récupérer les différents éléments de la page

echo "Generating php dispatching functions"
echo -n "   "
grep -a -v ^# $cartoDir/elements-cours.csv | grep -a -v ^$ | grep -a DEB > /tmp/part0.$$
NUMSEM=$( wc -l /tmp/part0.$$ | tr -s ' ' | cut -d ' ' -f 2)
cat /tmp/part0.$$ | (output="$webfunctionDir/functions.php"
	file_part1="/tmp/part1.$$"
	echo '      function getMenuTitle ($l1, $l2, $l3) {
         $menuTitle = array();
         $menuTitle[0] = array("Accueil",
                               "Nouvelles",
                               "Cartographie");// 1er item = menu, suivants = sous-menus' > $file_part1
	file_part2="/tmp/part2.$$"
	echo '      function getPageTitle ($l1, $l2, $l3) {
         $sectionsTitle = array();
         $sectionsTitle[0] = array("'$K_TITLE' <br /> site compagnon",
                                   "'$K_TITLE' — les news",
                                   "Cartographie globale du cours");// 1er item = menu, suivants = sous-menus' > $file_part2
	file_part3="/tmp/part3.$$"
	echo '      function getPageUrl ($l1, $l2, $l3) {
         $sectionsURL = array();
         $sectionsURL[0] = array("index.php", "news.php", "cartographie.php");// 1er item = menu, suivants = sous-menus' > $file_part3
	file_part4="/tmp/part4.$$"
	echo '      function getPageContentUrl ($l1, $l2, $l3) {
         $sectionsContentURL = array();
         $sectionsContentURL[0] = array("entree.html", "news.html", "cartographie.html");// 1er item = menu, suivants = sous-menus' > $file_part4
	echo '<?php
   $MAX_MENU_L1 = '$NUMSEM';  //profondeur maximum de niveau 1
   $MAX_MENU_L2 = array (); // profondeur maximum de niveau 2
   $MAX_MENU_L2[0] = 2;' > $output
	while read LINE ; do
		echo -n "."
		numsemaine=$(echo "$LINE" | cut -f 2)
		titre=$(echo "$LINE" | cut -f 4 | sed -e s'/\\\\n/ /g')
		echo '   $MAX_MENU_L2['$numsemaine'] = 0;' >> $output
		echo '         $menuTitle['$numsemaine'] = array("Semaine '$numsemaine'");' >> $file_part1
		echo '         $sectionsTitle['$numsemaine'] = array("Semaine '$numsemaine' &mdash; '$titre'");' >> $file_part2
		echo '         $sectionsURL['$numsemaine'] = array("semaine-'$(format_number $numsemaine)'.php");' >> $file_part3
		echo '         $sectionsContentURL['$numsemaine'] = array("semaine-'$(format_number $numsemaine)'.html");' >> $file_part4
	done
	echo '
   class AllData {
      function initData () {}
' >> $output
	cat $file_part1 >> $output
	echo '         return $menuTitle[$l1][$l2];
   }
' >> $output
	cat $file_part2 >> $output
	echo '         return $sectionsTitle[$l1][$l2];
   }
' >> $output
	cat $file_part3 >> $output
	echo '         return $sectionsURL[$l1][$l2];
   }
' >> $output
	cat $file_part4 >> $output
	echo '         return "content/".$sectionsContentURL[$l1][$l2];
   }
' >> $output
	echo '      function getPageHeaderTitle ($l1, $l2, $l3) {
         return $this->getMenuTitle ($l1, $l2, $l3);
      }

      function getContentFileOfElementForCourseAndSequence ($element, $cours, $sequence) {
         return "data/c".$cours."-s".$sequence."-".$element.".html";
      }
   }
?>' >> $output
rm -f $file_part1 $file_part2 $file_part3 $file_part4)
echo

######################################################################
# demarrage

######################################################################
# Deployer la cartographie

for file in $cartoDir/cartogr*.dot ; do
	gen_cartographie $file
done

######################################################################
# les chapitres (puis à l'intérieur les rubriques et encore à l'interieur
# les sous-rubriques 

echo "Generating chapters (weeks)"
(echo 1 > /tmp/globalseq
for numchap in $LISTE_SEMAINES ; do
	echo -n "   chapter $numchap "
	chap="semaine-"$(format_number $numchap)
	formatted_chap="$(format_number $numchap)"
	num=$(cut -f 3 $dataDir/semaine-$formatted_chap.csv | grep -a -n ^0$ | cut -d ':' -f 1)
	# le titre du chapitre
	grep -a -v ^# $dataDir/semaine-$formatted_chap.csv | grep -a -v FIN | grep -a -v DEB | \
	(while read LINE; do
		echo -n "."
		globalSeqNumber=$(cat /tmp/globalseq)
		uniqueid=$(echo "$LINE" | cut -f 1)
		sequence=$(echo "$LINE" | cut -f 3)
		titre=$(echo "$LINE" | cut -f 4 | sed -e s'/\\n/ /g')
		seqtype=$(echo "$LINE" | cut -f 5)
		ifoptional=$(echo "$LINE" | cut -f 9)
		starting=$(echo "$LINE" | cut -f 12)
		motsclef=$(echo "$LINE" | cut -f 10)
		URLvideo=$(echo "$LINE" | cut -f 11)
		dailymotionid=$(echo "$LINE" | cut -f 13)
		formatted_seq="$(format_number $sequence)"
		# construction des éléments de la séquence (il y a au moins un titre, un résumé et une vidéo)
		if [ -z "$titre" ]; then
			echo
			echo "ERREUR - Titre de la séquence $formatted_seq ($uniqueid) manquant!!!"
			exit 1
		fi
		romancounter=$(perl  -e 'use Roman ; print uc roman('$globalSeqNumber')')
		echo '<span class="num-titre">'$romancounter' -</span> '$titre > $webDataDir/c$formatted_chap-s$formatted_seq-titre.html
		echo '<div class="TdMl2"><a href="index.php?C='$formatted_chap'&amp;S='$formatted_seq'">'$romancounter' - '$titre'</a></div>' >> $webTdmDir/semaine-$formatted_chap.html
		if [ ! -f $dataDir/resumes/$uniqueid-resume.html ] ; then
			echo
			echo "ERREUR - résumé de la séquence $formatted_seq ($uniqueid) manquant!!!"
			exit 1
		fi
		cat $dataDir/resumes/$uniqueid-resume.html >> $webDataDir/c$formatted_chap-s$formatted_seq-resume.html
		if [ "$motsclef" ] ; then
			echo "<p><em>Mots clefs :</em> $motsclef.</p>" >> $webDataDir/c$formatted_chap-s$formatted_seq-resume.html
		fi
		if [ -z "$URLvideo" ]; then
			echo
			echo "ERREUR - URL de la vidéo de la séquence $formatted_seq ($uniqueid) manquant!!!"
			exit 1
		fi
 		echo '<p>Si la s&eacute;quence ne s&#x27;affiche pas dans le cadre ci-dessous, vous
 devez la t&eacute;l&eacute;charger depuis le cartouche.</p>

<video width="640px" height="360" controls="controls">
  <source src="'$URLvideo'" type="video/mp4" />
  Your browser does not support the video tag.
</video>
' > $webDataDir/c$formatted_chap-s$formatted_seq-sequence.html

		# le cartouche par défaut
		case $seqtype in
			"BASE")
				echo '<div class="TdMl1">Important</div>' > $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMimage"><img src="images/seq-basex50.png" alt="logo-seq-base" /></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;;
			"OPTIONNEL")
				if [ -z "$ifoptional" ] ; then
					echo ""
					echo "ATTENTION : la séquence optionnelle $uniqueid n'a pas de prérequis d'indiqué"
					echo -n "   "
				fi
				echo '<div class="TdMl1">Rappels de notions</div>' > $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMimage"><img src="images/seq-optx50.png" alt="logo-seq-optionnel" /></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMl2">Connaissances requises pour sauter cette section</div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMl3">'$ifoptional'</div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;;
			"ILLUSTRATION")
				echo '<div class="TdMl1">Illustration par un exemple</div>' > $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMimage"><img src="images/seq-examplex50.png" alt="logo-seq-illustration" /></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;;
			"DEMONSTRATION")
				echo '<div class="TdMl1">D&eacute;monstration en ligne</div>' > $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMimage"><img src="images/seq-demox50.png" alt="logo-seq-demonstration" /></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;;
			"EXERCICE")
				echo '<div class="TdMl1">Pr&eacute;sentation d&#x27;un exercice</div>' > $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;
				echo '<div class="TdMimage"><img src="images/seq-exox50.png" alt="logo-seq-exercice" /></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html ;;
		esac
		if [ -f $dataDir/slides/$uniqueid-slides.pdf ] ; then
			cp $dataDir/slides/$uniqueid-slides.pdf $webPdfDir/c$formatted_chap-s$formatted_seq-slides.pdf
			echo '<br />'>> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			echo '<div class="TdMURLslides"><b>T&eacute;l&eacute;chargement</b></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			echo '<div class="TdMl3"><a href="'$URLvideo'">Vid&eacute;o du cours</a></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			echo '<div class="TdMl3"><a href="pdf/'c$formatted_chap-s$formatted_seq'-slides.pdf">pdf des transparents</a></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
		else
			echo '<br />'>> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			echo '<div class="TdMURLslides"><b>T&eacute;l&eacute;chargement</b></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			echo '<div class="TdMl3">URL vid&eacute;o du cours (pas de slide)</a></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			echo '<div class="TdMl3">pas de pdf des slides</a></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
		fi
		# les autres informations en plus des liens etc...
		if [ -f $dataDir/others/$uniqueid-autres.html ] ; then
			cp $dataDir/others/$uniqueid-autres.html $webDataDir/c$formatted_chap-s$formatted_seq-autres.html
		fi
		# les extras dans le cartouche le cas échéant
		if [ -f $dataDir/extra/$uniqueid-extras.csv ] ; then
			grep -a -v '^###' $dataDir/extra/$uniqueid-extras.csv | sort -n | (crtRubrique=""
			while read LINE ; do
				rubrique=$(echo $LINE | cut -d ',' -f 3)
				texte=$(echo $LINE | cut -d ',' -f 4)
				liens=$(echo $LINE | cut -d ',' -f 5)
				if [ "$crtRubrique" != "$rubrique" ] ; then
					crtRubrique="$rubrique"
					echo '<br /><div class="TdMURLslides"><b>'$rubrique'</b></div>'>> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
				fi
				echo '<div class="TdMl3"><a href="'$liens'">'$texte'</a></div>' >> $webDataDir/c$formatted_chap-s$formatted_seq-class.html
			done)
		fi
		# des liens associés le cas échéant
		if [ -f "$dataDir/links/$uniqueid-liens.html" ] ; then
			cp $dataDir/links/$uniqueid-liens.html $webDataDir/c$formatted_chap-s$formatted_seq-liens.html
		fi
		echo $(expr $globalSeqNumber + 1) > /tmp/globalseq
	done
	echo)
done)

#tout est terminé, on change la date de modification du site
echo '<?php $LASTCHANGE="'$(date +"%d/%m/%Y")'"; ?>' > $webfunctionDir/moddate.php
