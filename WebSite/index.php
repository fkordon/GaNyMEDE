<?php
// Cas special ou on a la map
$id = isset($_GET["MAP"])?$mappage=$_GET["MAP"]:$mappage=0;
// References dans les structures décrivant une page
$id = isset($_GET["N1"])?$level1=$_GET["N1"]:$level1=0;
$id = isset($_GET["N2"])?$level2=$_GET["N2"]:$level2=0;
// Acces à une séquence dans un cours donné
$id = isset($_GET["S"])?$sequence=$_GET["S"]:$sequence=0;
$id = isset($_GET["C"])?$cours=$_GET["C"]:$cours=0;

//$level1=$_PRE['N1'];
//$level2=$_POST['N2'];;
$level3=-1;
//echo $level1."-".$level2.'-'.$level3;

//pour une page hors hiérarchie...
$id = isset($_GET["TITLE"])?$TITLE=$_GET["TITLE"]:$TITLE='';
$id = isset($_GET["CONTENT"])?$CONTENT=$_GET["CONTENT"]:$CONTENT='';
$id = isset($_GET["HEADER"])?$HEADER=$_GET["HEADER"]:$HEADER='';
//echo $CONTENT;

// Variables speciales (si /+ '', implique que $PAGE et $SUBPAGE soient égales à -1)
$DEEPPAGETITLE='';
$DEEPPAGEFLOAT='';
// Affichage du contenu de la page...
include ("functions/content.php");
?>
