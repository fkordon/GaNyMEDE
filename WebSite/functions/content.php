<?php
	require_once 'functions/functions.php';
	$TheData = new AllData ();
	//$TheData->initData();
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html  xmlns="http://www.w3.org/1999/xhtml">
<head>
<!-- <meta http-equiv="Content-Type" content="text/html;charset=ISO-8859-1" /> -->
<meta http-equiv="Content-Type" content="text/html;charset=UTF-8" />
<!--<base href='http://www.cosyverif.org/' /> -->
<title>PPM, site compagnon (2014/2015) - <?php
	if ($HEADER == '') {
		if ($cours != '' && $sequence != '') {
			echo "semaine ".$cours.", s&eacute;quence ".$sequence;
		} else {
			echo $TheData->getPageHeaderTitle ($level1, $level2, $level3); 
		}
	} else {
		echo $HEADER;
	}
?>
</title>
<link href="css/5I452.css" rel="stylesheet" type="text/css" media="screen,print"/>
<link href="css/menu.css" rel="stylesheet" type="text/css" media="screen,print"/>
</head>
<body>
<?php 
	if ($cours != '' && $sequence != '') {
		echo '<div class="background-others"><img src="images/fond-site-autres.jpg" alt="fond" /></div>';
		echo '<div class="logoSAR"><img src="images/logo-rotate.gif" alt="logo cours" /></div>';
	} else {
		if ($level1 == 0 && $level2 < 1) {
			echo '<div class="background-main"><img src="images/fond-site-main.jpg" alt="fond" /></div>';
			echo '<div class="logoUPMC"><img src="images/logo-UPMC.png" alt="logo UPMC" /></div>';
			echo '<div class="QRcode"><img src="images/qr-codex100.png" alt="QR code" /></div>';
		} else {
			echo '<div class="background-others"><img src="images/fond-site-autres.jpg" alt="fond" /></div>';
			echo '<div class="logoSAR"><img src="images/logo-rotate.gif" alt="logo cours" /></div>';
		}
	}
?>
<div class="mainmenu">
	<!-- Start css3menu.com BODY section -->
	<ul id="css3menu1" class="topmenu">
		<?php
			for ($l1 = 0; $l1 <= $MAX_MENU_L1 ; $l1++) {
				if ($l1 == 0) {
					echo '<li class="topfirst"><a href="'.$TheData->getPageUrl($l1,0,0).'" style="width:63px;height:16px;line-height:16px;">';
					echo $TheData->getMenuTitle($l1,0,0);
					echo '</a>';
				} else {
					echo '<li class="topmenu"><a href="'.$TheData->getPageUrl($l1,0,0).'" style="width:63px;height:16px;line-height:16px;">';
					echo $TheData->getMenuTitle($l1,0,0);
					echo '</a>';
				}
				if ($MAX_MENU_L2[$l1] > 0) {
					echo "\r<ul>";
					for ($l2 = 1; $l2 <= $MAX_MENU_L2[$l1] ; $l2++) {
						if ($l2 == 1) {
							echo '<li class="subfirst"><a href="'.$TheData->getPageUrl($l1,$l2,0).'" style="width:100px;height:16px;line-height:16px;">';
							echo $TheData->getMenuTitle($l1,$l2,0);
							echo '</a></li>';
						} else {
							echo '<li><a href="'.$TheData->getPageUrl($l1,$l2,0).'" style="width:100px;height:16px;line-height:16px;">';
							echo $TheData->getMenuTitle($l1,$l2,0);
							echo '</a></li>';
						}
					}
					echo "</ul>";
				}
				echo '</li>';
			}
		?>
	</ul>
	<!--<p class="_css3m"><a href="http://css3menu.com/">jQuery Multi Level CSS Menu Css3Menu.com</a></p>
	End css3menu.com BODY section -->
</div>
<?php
	if ($level1 == '' && $level2 < 2 && $cours == '') {
		echo '<div class="lasaison"><img src="images/lasaison.png" alt="saison 3"></div>';
		echo '<div class="ganymedelogo">Powered by<br /><a href="https://github.com/fkordon/GaNyMEDE"><img src="images/logo-GaNyMEDE.png"></a></div>';
		echo '<div class="maintitle-main">';
	} else {
		echo '<div class="overtitle-others">';
		echo 'Programmation sur plateforme mobile - site compagnon';
		echo '</div>';
		echo '<div class="maintitle-others">';
	}
	if ($TITLE != '') {
		echo $TITLE;
	} else {
		if ($cours != '' && $sequence != '') {
			include($TheData->getContentFileOfElementForCourseAndSequence("titre",$cours,$sequence));
		} else {
			echo $TheData->getPageTitle ($level1, $level2, $level3);
		}
	}
	echo '</div>';
?>
<?php
	if ($CONTENT != '') {
		echo '<div class="content">';
		include ('content/'.$CONTENT);
		echo '<p>&nbsp;</p>';
		include ("functions/date.php");
	} else {
		if ($cours != '' && $sequence != '') {
			echo '<div class="content">';
			echo '<div class="enveloppeTdM"><div class="TdM">'."\n";
			include("data/c".$cours.'-s'.$sequence.'-class.html');
			echo '</div></div>'."\n";
			if (file_exists($TheData->getContentFileOfElementForCourseAndSequence("resume",$cours,$sequence))) {
				$file = fopen ($TheData->getContentFileOfElementForCourseAndSequence("resume",$cours,$sequence), 'r');
				echo '<h1>R&eacute;sum&eacute; de la s&eacute;quence</h1>';
				while (!feof($file)) {
					$line = fgets($file);
					echo $line;
				}
				fclose($file);
			}
			if (file_exists($TheData->getContentFileOfElementForCourseAndSequence("sequence",$cours,$sequence))) {
				$file = fopen ($TheData->getContentFileOfElementForCourseAndSequence("sequence",$cours,$sequence), 'r');
				echo '<h1>Acc&eacute;der &agrave; la s&eacute;quence</h1>';
				while (!feof($file)) {
					$line = fgets($file);
					echo $line;
				}
				fclose($file);
			}
			if (file_exists($TheData->getContentFileOfElementForCourseAndSequence("liens",$cours,$sequence))) {
				$file = fopen ($TheData->getContentFileOfElementForCourseAndSequence("liens",$cours,$sequence), 'r');
				echo '<h1>Liens utiles</h1>';
				while (!feof($file)) {
					$line = fgets($file);
					echo $line;
				}
				fclose($file);
			}
			if (file_exists($TheData->getContentFileOfElementForCourseAndSequence("autres",$cours,$sequence))) {
				$file = fopen ($TheData->getContentFileOfElementForCourseAndSequence("autres",$cours,$sequence), 'r');
				while (!feof($file)) {
					$line = fgets($file);
					echo $line;
				}
				fclose($file);
			}
			
			echo '<p>&nbsp;</p>';
			echo '<div class="footer-others">';
			include ("functions/date.php");
			echo '</div><p>&nbsp;</p></div>';
		} else {
			if ($level1 > 0 || $level2 > 0) {
				echo '<div class="content">'."\n";
				if ($DEEPPAGEFLOAT != '') {
					echo '<div class="enveloppeTdM"><div class="TdM">'."\n";
					include("TdM/".$DEEPPAGEFLOAT);
					echo '</div></div>'."\n";
				}
				include ($TheData->getPageContentUrl ($level1, $level2, $level3));
				echo '<p>&nbsp;</p>';
				echo '<div class="footer-others">';
				include ("functions/date.php");
				echo '</div><p>&nbsp;</p></div>';
			} else {
				echo '<div class="fond-resume"></div>';
				echo '<div class="resume">';
				include ($TheData->getPageContentUrl ($level1, $level2, $level3));
				echo '</div>';
				echo '<div class="footer-main">';
				include ("functions/date.php");
				echo '</div>';
			}
		}
	}
?>
<!-- <p>
  <img src="http://www.w3.org/Icons/valid-xhtml10" alt="Valid XHTML 1.0 Strict" height="20" />
</p>
<p><img style="border:0;height:20px"
    src="http://jigsaw.w3.org/css-validator/images/vcss"
    alt="CSS Valide !" />
</p> -->

<!-- Piwik -->
<script type="text/javascript">
	var pkBaseURL = (("https:" == document.location.protocol) ? "https://stats.cadsi.fr/" : "http://stats.cadsi.fr/");
	document.write(unescape("%3Cscript src='" + pkBaseURL + "piwik.js' type='text/javascript'%3E%3C/script%3E"));
</script><script type="text/javascript">
	try {
		var piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", 9);
		piwikTracker.trackPageView();
		piwikTracker.enableLinkTracking();
		} catch( err ) {
		}
</script>
<noscript>
	<p><img src="http://stats.cadsi.fr/piwik.php?idsite=9" style="border:0" alt="" /></p>
</noscript>
<!-- End Piwik Tracking Code -->
</body>
</html>