#!/bin/bash

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
	export K_MOOC_START="2014-12-01T00:01:00Z"
fi

######################################################################
# constantes pour le déployement en local d'une copie du site

baseDir=$(pwd)
dataDir=ConstructionData
cartoDir=$dataDir/Cartographie
syllDir=$dataDir/Syllabus-MOOC
stdImgDir=$dataDir/StandardImages

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
	mkdir about chapter course discussion html info policies problem sequential static vertical
	#mkdir about chapter course discussion html info policies problem sequential static vertical video
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

cp $syllDir/syllabus.html "$TARGET_DIR/about/overview.html"
echo $K_TEASER_VIDEO_ID > "$TARGET_DIR/about/video.html"
echo $K_EFFORT > "$TARGET_DIR/about/effort.html"

if [ -f $syllDir/doc-pedagogiques.html ] ; then
	cp $syllDir/doc-pedagogiques.html "$TARGET_DIR/info/handouts.html"
else
	echo "Warning: no pedagogical information (file $syllDir/doc-pedagogiques.html)"
fi

######################################################################
# Si on veut déployer la cartographie

cp $cartoDir/cartographie.pdf "$TARGET_DIR/static"

######################################################################
# la structure du cours (chapitres + informations globales)
echo '<course url_name="'$K_MOOC_ID'" org="'$K_INSTITUTION'" course="'$K_ACCRONYM'"/>' > "$TARGET_DIR/course.xml"

OUTPUT="$TARGET_DIR/course/${K_MOOC_ID}.xml"
echo '<course course_image="pano_image.jpg" display_name="'$K_TITLE'" end="'$K_MOOC_END'" enrollment_end="'$K_ENROLL_END'" enrollment_start="'$K_ENROLL_START'" info_sidebar_name="Documents pédagogiques" start="'$K_MOOC_START'">' > $OUTPUT
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
# les sous-rubriques 

echo "Generating chapters"
(cd $dataDir
vertical_dir="$TARGET_DIR/vertical"
html_dir="$TARGET_DIR/html"
#video_dir="$TARGET_DIR/video"
problem_dir="$TARGET_DIR/problem"
discussion_dir="$TARGET_DIR/discussion"
for chapter in semaine-*.csv ; do
	numchap=$(expr $(echo "$chapter" | cut -d '-' -f 2 | cut -d '.' -f 1) + 0) # to remove leadings 0 when necessary
	chap=$(basename $chapter .csv)
	echo -n "   chapter $numchap "
	formatted_chap="$(format_number $numchap)"
	num=$(cut -f 3 $chapter | grep -a -n ^0$ | cut -d ':' -f 1)
	# le titre du chapitre
	chaptitle=$(format_number $numchap)' : '$(sed -n ${num}p $chapter| cut -f 4 | sed -e s'/\\\\n/ /g' | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);')
	starting=$(sed -n ${num}p $chapter | cut -f 12)
	if [ "$SEE_ALL" -o "$starting" = "" ] ; then
		# indiquer une date de publication anterieure au début réel du MOOC pour
		# tout voir sur le MOOC-bac-à-sable
		starting=$K_MOOC_START
	fi
	echo '<chapter display_name="'$chaptitle'" start="'$starting'">' >> "$TARGET_DIR/chapter/$chap.xml"
	grep -a -v ^# $chapter| grep -a -v FIN | grep -a -v DEB | \
	(while read LINE; do
		echo -n "."
		seqid=$(echo "$LINE" | cut -f 1)
		sequence=$(echo "$LINE" | cut -f 3)
		starting=$(echo "$LINE" | cut -f 12)
		if [ "$SEE_ALL" ] ; then
			# indiquer une date de publication anterieure au début réel du MOOC
			# pour tout voir sur le MOOC-bac-à-sable
			starting=$K_MOOC_START
		fi
		motsclef=$(echo "$LINE" | cut -f 10)
		dailymotionid=$(echo "$LINE" | cut -f 13)
		formatted_seq="$(format_number $sequence)"
		# declaration de la rubrique dans le chapitre
		echo '   <sequential url_name="semaine-'$formatted_chap'-rubrique-'$formatted_seq'-'$seqid'"/>' >> "$TARGET_DIR/chapter/$chap.xml"
		# construction de la rubrique
		output="$TARGET_DIR/sequential/semaine-$formatted_chap-rubrique-$formatted_seq-$seqid.xml"
		echo '<sequential display_name="'$(echo "$LINE" | cut -f 4 | sed -e s'/\\n/ /g' | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);')'" start="'$starting'">' >> "$output"
		# il y a au moins un résumé et une vidéo
		echo '   <vertical url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-resume"/>' >> "$output"
		echo '   <vertical url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-video"/>' >> "$output"
		if [ -f "$seqid-liens.html" -o -f "$seqid-extras.csv" ] ; then
			# des liens associés + extras le cas échéant
			echo '   <vertical url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-liens"/>' >> "$output"
			echo '<html display_name="Autres éléments" filename="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-liens-data"/>' >> "$html_dir/id-$formatted_chap-$formatted_seq-$seqid-liens-data.xml"
			(output="$vertical_dir/id-$formatted_chap-$formatted_seq-$seqid-liens.xml"
			echo '<vertical display_name="Liens utiles">' >> "$output"
			echo '   <html url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-liens-data"/>' >> "$output"
			echo '</vertical>' >> "$output")
			if [ -f "$seqid-liens.html" ] ; then
				(output="$html_dir/id-$formatted_chap-$formatted_seq-$seqid-liens-data.html"
				echo '<h2>Liens utiles</h2>' >> "$output"
				cat $seqid-liens.html >> "$output")
			fi
			if [ -f "$seqid-extras.csv" ] ; then
				(output="$html_dir/id-$formatted_chap-$formatted_seq-$seqid-liens-data.html"
				echo '<h2>Éléments complémentaires</h2>' >> "$output"
				grep -a -v '^###' $seqid-extras.csv | (CRT_RUBRIQUE=""
				while read LINE ; do
					RUBRIQUE=$(echo $LINE | cut -d ',' -f 3)
					TEXTE=$(echo $LINE | cut -d ',' -f 4)
					LIENS=$(echo $LINE | cut -d ',' -f 5)
					if [ "$CRT_RUBRIQUE" != "$RUBRIQUE" ] ; then
						if [ "$CRT_RUBRIQUE" ] ; then
							echo '</ul>' >> "$output"
						fi
						CRT_RUBRIQUE="$RUBRIQUE"
						echo '<p>'"$RUBRIQUE"' :</p>'>> "$output"
						echo '<ul>'>> "$output"
					fi
					echo '   <li><a href="'"$LIENS"'">'"$TEXTE"'</a></li>' >> "$output"
				done
				echo '</ul>' >> "$output"))
			fi
		fi
		if [ -f $seqid-QCM.csv ] ; then
			echo '   <vertical url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-probleme"/>' >> "$output"
		fi
		echo '</sequential>' >> "$output"
		# generer les descripteurs d'une sous-rubrique
		# le résumé (obligatoire)
		output="$vertical_dir/id-$formatted_chap-$formatted_seq-$seqid-resume.xml"
		echo '<vertical display_name="Résumé de la séquence '$sequence' (cours '$numchap')">' >> "$output"
		echo '   <html url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-resume-data"/>' >> "$output"
		echo '</vertical>' >> "$output"
		# générer les fichiers du résumé
		echo '<html display_name="Résumé de la séquence '$sequence' (cours '$numchap')" filename="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-resume-data"/>' >> "$html_dir/id-$formatted_chap-$formatted_seq-$seqid-resume-data.xml"
		output="$html_dir/id-$formatted_chap-$formatted_seq-$seqid-resume-data.html"
		echo '<h2>Résumé de la séquence</h2>' > "$output"
		cat $seqid-resume.html >> "$output"
		if [ "$motsclef" ] ; then
			echo '<h2>Mots clefs</h2>' >> "$output"
			echo "<p>$motsclef.</p>" >> "$output"
		fi
		if [ -f "$seqid-slides.pdf" ] ; then
			echo '<h2>Transparents (pdf)</h2>' >> "$output"
			if [ "$NO_PDF" ] ; then
				echo '<p>Mode "léger" activé => les éléments "lourds" du MOOC ne sont pas déployées (supprimez le paramètre "-leger" dans la ligne de commande de deploy_mooc.sh).</p>' >> "$output"
			else
				cp $seqid-slides.pdf "$TARGET_DIR/static/transparents-$formatted_chap-$formatted_seq-$seqid.pdf"
				echo '<p>Le <a href="/static/transparents-'$formatted_chap'-'$formatted_seq'-'$seqid'.pdf">pdf des transparents présentés est disponible ici</a>.</p>' >> "$output"
			fi
		fi
		# la vidéo (obligatoire)
		output="$vertical_dir/id-$formatted_chap-$formatted_seq-$seqid-video.xml"
		echo '<vertical display_name="Vidéo de la séquence">' >> "$output"
		echo '   <dmcloud url_name="'$dailymotionid'" display_name="Vidéo de la séquence" allow_download_video="True" id_video="'$dailymotionid'"/>' >> "$output"
		#		echo '   <video url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-video-data"/>' >> "$output"
		echo '</vertical>' >> "$output"
		# générer les fichiers de la vidéo
#		output="$video_dir/id-$formatted_chap-$formatted_seq-$seqid-video-data.xml"
#		echo '<video display_name="Vidéo de la séquence" html5_sources="[&quot;'$dailymotionid'&quot;]" youtube_id_1_0="">' >> "$output"
#		echo '   <source src="'$dailymotionid'"/>' >> "$output"
#		echo '</video>' >> "$output"
		# le QCM (optionnel)
		# générer les fichiers du QCM si besoin est
		if [ -f $seqid-QCM.csv ] ; then
			output="$vertical_dir/id-$formatted_chap-$formatted_seq-$seqid-probleme.xml"
			echo '<vertical display_name="Questionnaire de la séquence '$sequence' (cours '$numchap')">' >> "$output"
			echo '   <problem url_name="id-'$formatted_chap'-'$formatted_seq'-'$seqid'-probleme-data"/>' >> "$output"
			echo '</vertical>' >> "$output"
			output="$problem_dir/id-$formatted_chap-$formatted_seq-$seqid-probleme-data.xml"
			echo '<problem display_name="Questionnaire de la séquence '$sequence' (cours '$numchap')" markdown="null">' >> "$output"
			grep -a -v ^# $seqid-QCM.csv | sort -n | while read QCMLINE ; do
				numq=$(echo "$QCMLINE" | cut -f 4)
				textq=$(echo "$QCMLINE" | cut -f 5)
				typeq=$(echo "$QCMLINE" | cut -f 6)
				for i in 1 2 3 4 5 6 7 8 9 10 ; do
					repoq[$i]=$(echo "$QCMLINE" | cut -f $(expr $i + 6))
				done
				explq=$(echo "$QCMLINE" | cut -f 14)
				echo '   <p>'$textq'</p>' >> "$output"
				if [ "$typeq" = "1R" ] ; then
					# 1 choix parmi R réponses
					echo '      <multiplechoiceresponse>' >> "$output"
					echo '         <choicegroup type="MultipleChoice">' >> "$output"
				else
					# N choix parmi R réponses
					echo '      <choiceresponse>' >> "$output"
					echo '         <checkboxgroup type="MultipleChoice">' >> "$output"
				fi
				for i in 1 2 3 4 5 6 7 8 9 10 ; do
					if [ "${repoq[$i]}" ] ; then
						if [ "_" != "$(echo ${repoq[$i]} | cut -b1)" ] ; then
							# ce n'est pas une réponse (pas de _ au début)
							echo '            <choice correct="false">'"${repoq[$i]}"'</choice>' >> "$output"
						else
							# c'est une réponse
							echo '            <choice correct="true">'"$(echo ${repoq[$i]} | cut -d '_' -f 2)"'</choice>' >> "$output"
						fi
					fi
				done
				if [ "$typeq" = "1R" ] ; then
					# 1 choix parmi R réponses
					echo '         </choicegroup>' >> "$output"
					echo '      </multiplechoiceresponse>' >> "$output"
				else
					# N choix parmi R réponses
					echo '         </checkboxgroup>' >> "$output"
					echo '      </choiceresponse>' >> "$output"
				fi
				echo '   <solution>' >> "$output"
				echo '      <div class="detailed-solution">' >> "$output"
				echo '         <p>'$explq'</p>' >> "$output"
				echo '      </div>' >> "$output"
				echo '   </solution>' >> "$output"
			done
			echo '</problem>' >> "$output"
		fi
	done)
	# on va egalement disposer d'une rubrique "bilan" avec juste un QCM permettant de cocher ce qui a été fait
	echo '   <sequential url_name="semaine-'$formatted_chap'-bilan"/>' >> "$TARGET_DIR/chapter/$chap.xml"
	output="$TARGET_DIR/sequential/semaine-$formatted_chap-bilan.xml"
	echo '<sequential display_name="Bilan de la semaine '$numchap'">' >> "$output"
	echo '   <problem url_name="semaine-'$formatted_chap'-bilan-data"/>' >> "$output"
	echo '</sequential>' >> "$output"
	output="$problem_dir/semaine-"$formatted_chap"-bilan-data.xml"
	echo '<problem display_name="Bilan de la semaine '$numchap'" markdown="null">' >> "$output"
	echo '   <p>Cochez les actions que vous avez réalisées cette semaine afin de faire un bilan et vous assurer de n'"'"'avoir rien oublié.</p>' >> "$output"
	echo '      <choiceresponse>' >> "$output"
	echo '         <checkboxgroup type="MultipleChoice">' >> "$output"
	grep -a -v ^# $chapter| grep -a -v FIN | grep -a -v DEB | \
		(while read LINE ; do
			sequence=$(echo "$LINE" | cut -f 3)
			formatted_seq="$(format_number $sequence)"
			typeseq=$(echo "$LINE" | cut -f 5)
			if [ "$typeseq" = "EXERCICE" ] ; then
				echo '            <choice correct="true">J'"'"'ai réalisé l'"'"'exercice '$(echo "$LINE" | cut -f 4)'</choice>' >> "$output"
			else
				echo '            <choice correct="true">J'"'"'ai regardé la vidéo «'$(echo "$LINE" | cut -f 4 | sed -e s'/\\n/ /g')'»</choice>' >> "$output"
				if [ -f "$seqid-QCM.csv" ] ; then
					echo '            <choice correct="true">J'"'"'ai répondu au questionnaire associé à la vidéo «'$(echo "$LINE" | cut -f 4 | sed -e s'/\\n/ /g')'»</choice>' >> "$output"
				fi
			fi
		done)
	echo '         </checkboxgroup>' >> "$output"
	echo '      </choiceresponse>' >> "$output"
	echo '   <solution>' >> "$output"
	echo '      <div class="detailed-solution">' >> "$output"
	echo '         <p>J'"'"'ai donc effectué toutes les étapes de cette semaine.</p>' >> "$output"
	echo '      </div>' >> "$output"
	echo '   </solution>' >> "$output"
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