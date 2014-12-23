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