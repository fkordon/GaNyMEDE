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
#    the Free Software Foundation, either version 3 of the License, xor
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
	echo "       -debug : permet de forcer les dates du MOOC avant son commencement"
	echo "       -leger : permet de ne pas embarquer de fichiers lourds (pdf des transparents)"
	echo "       -help : cette aide en ligne (avorte l'exécution)"
}

format_number() {
	perl -e  'printf "%0.2d", '$1
}

if [ "$1" = "-help" ] ; then
	display_usage
	exit 0
fi

if [ "$1" = "-debug" ] ; then
	SEE_ALL="YES"
	shift
fi

if [ "$1" = "-leger" ] ; then
	NO_PDF="YES"
	shift
fi

source ./Scripts/check_dependencies.sh

# pour créer des archives sans fichiers parasites(sous MacOS)...
export COPYFILE_DISABLE=true

if [ "$SEE_ALL" ] ; then
	# indiquer une date de publication anterieure au début réel du MOOC pour
	# tout voir sur le MOOC-bac-à-sable
	export K_MOOC_START="2017-01-10T00:00:00+00:00"
fi

######################################################################
# constantes pour le déployement en local d'une copie du site

baseDir=$(pwd)
dataDir=ConstructionData
cartoDir=$dataDir/Cartographie
syllDir=$dataDir/Syllabus-MOOC
stdImgDir=$dataDir/StandardImages
webDir=WebSite

######################################################################
# constantes pour configurer son MOOC

source $syllDir/configure-mooc.sh

# recuperer le nombre de seances du MOOC (onsuppose ce que sont des numeros
# que l'on va 'padder' sur deux caracteres (en insérant un 0) pour que
# l'ordre lexicographique soit aussi l'ordre numerique)

LISTE_SEMAINES=$(grep -a -v ^# $cartoDir/elements-cours.csv | cut -f 2 | sort -u | sort -n)
### sort -u | sort -n parce que sort -un ou sort -u -n fait sauter les 0 s'il y en a

######################################################################
# preparation du fichier de metadonnees dans le repertoire des chapitres

echo "Dispatching global metadata"
echo -n "   "
for semaine in $LISTE_SEMAINES  ; do
	echo -n "."
	rm -f $dataDir/semaine-$(format_number $semaine).csv
	liste_elem=$(cut -f 2 $cartoDir/elements-cours.csv | grep -a -n ^${semaine}$ | cut -d ':' -f 1)
	for elem in $liste_elem ; do
		sed -n ${elem}p $cartoDir/elements-cours.csv >> $dataDir/semaine-$(format_number $semaine).csv
	done
done
echo
echo "preparing quizz data (QCM)"
echo -n "   "
if [ -f "$cartoDir/qcm.csv" ] ; then
	SEQ_QCM=$(grep -v \# $cartoDir/qcm.csv | cut -f 1 | sort -u)
	for seq in $SEQ_QCM ; do
		grep ^$seq $cartoDir/qcm.csv > $dataDir/$seq-qcm.csv
		echo -n "."
	done
else
	echo -n "WARNING: no quizz found... is that normal?"
fi
echo

######################################################################
# demarrage

INDIR="$K_MOOC_ID"

if [ "$(uname -s)" = "Darwin" ] ; then
	export TARGET_DIR="$HOME/Desktop/$INDIR"
else
	export TARGET_DIR=${XDG_DESKTOP_DIR:-$HOME/Desktop}/$INDIR
fi

if [ -d "$TARGET_DIR" ] ; then
	rm -rf "$TARGET_DIR"
fi

mkdir "$TARGET_DIR"


######################################################################
# creation de la structure de base de l'archive
(
	cd "$TARGET_DIR"
	mkdir about assets chapter course html info policies problem sequential static vertical video
)

######################################################################
# insertion des elements "statiques"
if [ "$(ls $syllDir/*.png 2> /dev/null)" ] ; then
	cp $syllDir/*.png "$TARGET_DIR/static"
fi
if [ "$(ls $syllDir/*.jpg 2> /dev/null)" ] ; then
	cp $syllDir/*.jpg "$TARGET_DIR/static"
fi
cp $stdImgDir/*.jpg  "$TARGET_DIR/static"
cp $webDir/images/seq-*50.png "$TARGET_DIR/static"
cp $stdImgDir/GaNyMEDE.css "$TARGET_DIR/static"

if [ -f $syllDir/syllabus.html ] ; then
	cp $syllDir/syllabus.html "$TARGET_DIR/about/overview.html"
else
	echo "ERROR: missing file $syllDir/syllabus.html"
fi
if [ -f $syllDir/shortDescription.html ] ; then
	cp $syllDir/shortDescription.html "$TARGET_DIR/about/short_description.html"
else
	echo "ERROR: missing file $syllDir/shortDescription.html"
fi
echo $K_TEASER_VIDEO_ID > "$TARGET_DIR/about/video.html"
echo $K_EFFORT > "$TARGET_DIR/about/effort.html"
echo > "$TARGET_DIR/about/description.html"
echo > "$TARGET_DIR/about/duration.html"
echo > "$TARGET_DIR/about/entrance_exam_enabled.html"
echo > "$TARGET_DIR/about/entrance_exam_id.html"
echo 50 > "$TARGET_DIR/about/entrance_exam_minimum_score_pct.html"
echo > "$TARGET_DIR/about/subtitle.html"
echo > "$TARGET_DIR/about/title.html"

echo -n '<assets/>' > "$TARGET_DIR/assets/assets.xml"

if [ -f $syllDir/doc-pedagogiques.html ] ; then
	cp $syllDir/doc-pedagogiques.html "$TARGET_DIR/info/handouts.html"
else
	echo
	echo "   WARNING: no pedagogical information (file $syllDir/doc-pedagogiques.html)"
	echo
fi
echo > "$TARGET_DIR/info/updates.html"

# Fichier d'acualités par défaut
#echo '[]' > "$TARGET_DIR/info/updates.items.json"
echo '[{"content" : "ceci est une actualit&ecute;","date" : "September 27, 2016", "id": 1, "status": "visible"}]' > "$TARGET_DIR/info/updates.items.json"

######################################################################
# Si on veut déployer la cartographie

cp $cartoDir/cartographie.pdf "$TARGET_DIR/static"

######################################################################
# la structure du cours (chapitres + informations globales)
echo '<course url_name="'$K_MOOC_ID'" org="'$K_INSTITUTION'" course="'$K_ACCRONYM'"/>' > "$TARGET_DIR/course.xml"

OUTPUT="$TARGET_DIR/course/${K_MOOC_ID}.xml"
echo '<course cert_html_view_enabled="true" display_name="'$K_TITLE'" language="en" start="&quot;'$K_ENROLL_START'&quot;">' > $OUTPUT
(cd $dataDir
for chapter in semaine-*.csv ; do
	#chap=$(echo "$LINE" | cut -f 4 | tr "'\" |&,;#\\?" "_")
	chap=$(basename $chapter .csv)
	echo '   <chapter url_name="'$chap'"/>'
done
echo '   <wiki slug="'$K_INSTITUTION'.'$K_ACCRONYM'.'$K_MOOC_ID'"/>') >> $OUTPUT
echo '</course>' >> $OUTPUT

######################################################################
# les chapitres (puis à l'intérieur les rubriques et encore à l'interieur
# les sous-rubriques)

echo "Generating chapters"
(cd $dataDir
vertical_dir="$TARGET_DIR/vertical"
html_dir="$TARGET_DIR/html"
video_dir="$TARGET_DIR/video"
problem_dir="$TARGET_DIR/problem"
discussion_dir="$TARGET_DIR/discussion"
for chapter in semaine-*.csv ; do
	numchap=$(expr $(echo "$chapter" | cut -d '-' -f 2 | cut -d '.' -f 1) + 0) # to remove leadings 0 when necessary
	chap=$(basename $chapter .csv)
	echo -n "   chapter $numchap "
	formatted_chap="$(format_number $numchap)"
	num=$(cut -f 3 $chapter | grep -a -n ^0$ | cut -d ':' -f 1)
	# le titre du chapitre
	chaptitle=$(format_number $numchap)' : '$(sed -n ${num}p $chapter| cut -f 4 | sed -e 's/\\\\n/ /g' | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' | sed -e 's/&/et/g')
	starting=$(sed -n ${num}p $chapter | cut -f 12)
	if [ "$SEE_ALL" -o "$starting" = "" ] ; then
		# indiquer une date de publication anterieure au début réel du MOOC pour
		# tout voir sur le MOOC-bac-à-sable
		starting=$K_MOOC_START
	fi
	echo '<chapter display_name="'$chaptitle'" start="&quot;'$starting'&quot;">' >> "$TARGET_DIR/chapter/$chap.xml"
	grep -a -v ^# $chapter| grep -a -v FIN | grep -a -v DEB | \
	(while read LINE; do
		echo -n "."
		seqid=$(echo "$LINE" | cut -f 1)
		sequence=$(echo "$LINE" | cut -f 3)
		starting=$(echo "$LINE" | cut -f 12)
		seqtype=$(echo "$LINE" | cut -f 5)
		if [ "$SEE_ALL" ] ; then
			# indiquer une date de publication anterieure au début réel du MOOC
			# pour tout voir sur le MOOC-bac-à-sable
			starting=$K_MOOC_START
		fi
		motsclef=$(echo "$LINE" | cut -f 10)
		videoid=$(echo "$LINE" | cut -f 13)
		formatted_seq="$(format_number $sequence)"
		# declaration de la rubrique dans le chapitre
		echo '   <sequential url_name="semaine-'$formatted_chap'-rubrique-'$formatted_seq'-'$seqid'"/>' >> "$TARGET_DIR/chapter/$chap.xml"
		# construction de la rubrique
		output="$TARGET_DIR/sequential/semaine-$formatted_chap-rubrique-$formatted_seq-$seqid.xml"
		echo '<sequential display_name="'$(echo "$LINE" | cut -f 4 | sed -e 's/\\n/ /g' | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' | sed -e 's/&/et/g')'" start="&quot;'$starting'&quot;">' >> "$output"
		# insérer la page associée à la séquence (il y a tout ce qu'il faut)
		echo '   <vertical url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-lapage"/>' >> "$output"
		echo '</sequential>' >> "$output"
		# Generer la page associee a la sequence (existe toujours)	
		output="$vertical_dir/id-$formatted_chap-$formatted_seq-$seqid-lapage.xml"
		echo '<vertical display_name="Page de la séquence '$sequence' (cours '$numchap')">' > "$output"
		echo '   <html url_name="'id-$formatted_chap-$formatted_seq-$seqid-'resume"/>' >> "$output"
		echo '   <video url_name="'id-$formatted_chap-$formatted_seq-$seqid-'video"/>' >> "$output"
		echo '   <html url_name="'id-$formatted_chap-$formatted_seq-$seqid-'suite"/>' >> "$output"
		echo '</vertical>' >> "$output"
		# Generer le descriptif du fichier HTML du résumé et du "reste"
		echo '<html filename="'id-$formatted_chap-$formatted_seq-$seqid-resume'" display_name="Raw HTML" editor="raw"/>' > $html_dir/id-$formatted_chap-$formatted_seq-$seqid-resume.xml
		output="$html_dir/id-$formatted_chap-$formatted_seq-$seqid-resume.html"
		case $seqtype in
			"BASE") style="basecolor" 
				visuelSeq="base";;
			"OPTIONNEL") style="opticolor"
				visuelSeq="opt";;
			"DEMONSTRATION") style="democolor"
				visuelSeq="demo";;
			"ILLUSTRATION") style="illucolor"
				visuelSeq="example";;
			"EXERCICE") style="exercolor"
				visuelSeq="exo";;
		esac
		echo '<link rel="stylesheet" type="text/css" href="/static/GaNyMEDE.css" />' > "$output"
		if [ "$seqtype" = "OPTIONNEL" ] ; then
			if [ "$(echo "$LINE" | cut -f 9)" ] ; then
				echo '<p>Vous pouvez sauter cette séquence si vous avez les prérequis suivants: '$(echo "$LINE" | cut -f 9)'.</p>' >> "$output"
			else
				echo
				echo "Warning, there is a missing prerequisise definition in $seqid (course $formatted_chap, sequence $formatted_seq)"
				echo -n "   "
			fi
		fi
		echo '<h2><img src="/static/seq-'$visuelSeq'x50.png"><span class="'$style'"> Résumé de la séquence</span></h2>' >> "$output"
		cat resumes/$seqid-resume.html >> "$output"
		if [ "$motsclef" ] ; then
			echo '<h2><span class="'$style'">Mots clefs</span></h2>' >> "$output"
			echo "<p>$motsclef.</p>" >> "$output"
		fi
		# Le fichier FHTM sous la vidéo (avec l'accès aux slides et, le cas échéant, les liens etc.)
		output="$html_dir/id-$formatted_chap-$formatted_seq-$seqid-suite.html"
		echo '<h2><span class="'$style'">Récupérer le pdf des transparents présentés</span></h2>' > $output
		if [ -f "slides/$seqid-slides.pdf" ] ; then
			cp slides/$seqid-slides.pdf "$TARGET_DIR/static/transparents-$formatted_chap-$formatted_seq-$seqid.pdf"
			echo '<p>Le <a href="/static/transparents-'$formatted_chap'-'$formatted_seq'-'$seqid'.pdf">pdf des transparents présentés est disponible ici</a>.</p>' >> "$output"			
		else
			echo "WARNING - missing pdf for slides $seqid (c$formatted_chap/s$formatted_seq)"
		fi
		if [ -f "links/$seqid-liens.html" ] ; then
			echo '<h2><span class="'$style'">Ressources utiles</span></h2>' >> "$output"
			cat "links/$seqid-liens.html" >> "$output"
		fi
		echo '<html filename="'id-$formatted_chap-$formatted_seq-$seqid-suite'" display_name="Raw HTML" editor="raw"/>' > $html_dir/id-$formatted_chap-$formatted_seq-$seqid-suite.xml
		# Generer le descriptif de la vidéo
		echo '<video youtube="1.00:'$videoid'" url_name="'id-$formatted_chap-$formatted_seq-$seqid-video'" display_name="Video" download_video="false" html5_sources="[]" sub="" youtube_id_1_0="'$videoid'"/>' > $video_dir/id-$formatted_chap-$formatted_seq-$seqid-video.xml
	done)
	# on va egalement disposer d'une rubrique "bilan" avec juste un QCM permettant de cocher ce qui a été fait
	echo '   <sequential url_name="semaine-'$formatted_chap'-bilan"/>' >> "$TARGET_DIR/chapter/$chap.xml"
	output="$TARGET_DIR/sequential/semaine-$formatted_chap-bilan.xml"
	echo '<sequential display_name="Bilan de la semaine '$numchap'">' >> "$output"
	echo '   <vertical url_name="semaine-'$formatted_chap'-bilan"/>' >> "$output"
	echo '</sequential>' >> "$output"
	output="$TARGET_DIR/vertical/semaine-$formatted_chap-bilan.xml"
	echo '<vertical display_name="Liste des choses à faire">' >> "$output"
	echo '   <problem  url_name="semaine-'$formatted_chap'-bilan"/>' >> "$output"
	echo '</vertical>' >> "$output"
	output="$problem_dir/semaine-"$formatted_chap"-bilan.xml"
	echo '<problem display_name="Checkboxes" markdown="null">' > "$output"
	echo '<choiceresponse>' >> "$output"
	echo '   <p>Il est emps de faire un bilan de votre semaine</p>' >> "$output"
	echo '   <label>Cochez les actions que vous avez effectuées cette semaine afin de faire un bilan et vous assurer de n'"'"'avoir rien oublié.</label>' >> "$output"
	echo '   <checkboxgroup>' >> "$output"
	grep -a -v ^# $chapter| grep -a -v FIN | grep -a -v DEB | \
		(while read LINE ; do
			sequence=$(echo "$LINE" | cut -f 3)
			formatted_seq="$(format_number $sequence)"
			typeseq=$(echo "$LINE" | cut -f 5)
			entityName=$(echo "$LINE" | cut -f 4 | sed -e 's/\\n/ /g' | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' | sed -e 's/&/et/g')
			if [ "$typeseq" = "EXERCICE" ] ; then
				echo '         <choice correct="true">J'"'"'ai réalisé l'"'"'exercice : '$entityName'</choice>' >> "$output"
			else
				echo '         <choice correct="true">J'"'"'ai regardé la séquence : '$entityName'</choice>' >> "$output"
				if [ -f "$seqid-qcm.csv" ] ; then
					echo '            <choice correct="true">J'"'"'ai répondu au questionnaire associé à la vidéo : 'entityName'</choice>' >> "$output"
				fi
			fi
		done)
	echo '   </checkboxgroup>' >> "$output"
	echo '   <solution>' >> "$output"
	echo '      <div class="detailed-solution">' >> "$output"
	echo "         L'idéal est de réaliser l'ensemble des activités proposées." >> "$output"
	echo '      </div>' >> "$output"
	echo '   </solution>' >> "$output"
	echo '</choiceresponse>' >> "$output"
	echo '</problem>' >> "$output"
	echo '</chapter>' >> "$TARGET_DIR/chapter/$chap.xml"
	echo
done)

######################################################################
# construction de l'archive
(cd "$HOME/Desktop"
if [ -f "$INDIR.tar.gz" ] ; then
	rm -f $INDIR.tar.gz
fi
echo "Compressing the archive"
tar czf $INDIR.tar.gz $INDIR)