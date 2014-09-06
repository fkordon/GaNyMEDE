<?php 
include ("functions/moddate.php");
if ($level1 == '' && $cours == '') {
	echo 'Modifi&eacute; le '.$LASTCHANGE.' - affich&eacute; le  ';
} else {
	echo 'Derni&egrave;re modification du site le '.$LASTCHANGE.' - affichage de la page le  ';
}
$date = date("d/m/Y");
echo "$date </br /> <br />";
echo 'Ces ressources sont plac&eacute;es sous licence <a href="http://creativecommons.org/licenses/by-nc-sa/3.0/fr/">Creative Commons CC BY-SA-NC</a>';
echo '</div>';
?>
