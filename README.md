GaNyMEDE
========

GeNeric Moocs &amp; coursEs Development Environment


Description
-----------

This project is a small environment that allows one to develop a course and generate automatically a compagnon web site
from metadata. Such courses can then be deployed on some home page.

This environment also allows deployment of the courses into the France Université Numérique platform (openedx?).

Directory content
-----------------

ConstructionData: it contains the metadata for your course. At this stage, it contains a small
example

Scripts: it contains the scripts used to build
	- the map of the course
	- the companion web site
	- the archive to be deployed on France Université Numérique
	- and more later? ;-)

Website: the minimum files for the web site (others are generated). Basically, you should only change the content of
content/entree.html that describes the course you want to deploy. The rest is generated automaically from the
metadata you provide in the ConstructionData directory

MPORTANT: please use only the make command from this directory to generate either the companion web site or the
archive for your MOOC/distance learning infrastructure. type "make" toget a minimal help.

Usage
-----

type "make" to discover the options of the Makefile.

Warnings
--------

All of this is at a quite early stage, even if development started one year ago... a lot of modification was done
and there is a need for setting up a more proper version.

Sorry, most of it is still in french (procrastination and lack of time ;-). I have added some "readme.txt" files in
english to help people navigate and understand the meaning of the main files in the ConstructionData directory.

PS: all of this was tested under a Mac running MacOS 10.9

PPS: at this stage, perl package Roman is required (http://search.cpan.org/~chorny/Roman-1.22/lib/Roman.pm), as well
as dot, from Graphviz (http://www.graphviz.org)