This directory contents eements that describe sequences. Each sequence is referenced by a UNIQUE IDENTIFIER that allow
to tag files. You have the following type of files:

- resumes/resume-<number on two digits>.html : the abstract of a given "chapter" (typically a week but not necessarily),

- resumes/<ident>-resume.html: it describes an abstract of the sequence's content. this file is MANDATORY.

- links/<ident>-liens.html: it may proposes some links to useful resources for the sequence. this file is optional.

- others/<ident>-autres.html: it may propose some extra information for the sequence. this file is optional

- slides/<ident>-slides.pdf: it contains the slides presented during the sequence or some written text associated to it. If
  this file is not present, some links will not be appropriately generated.

- extra/<ident>-extras.csv : it contains in a CSV format, some extra document (typically, archives and stuff) that could be
  useful in the context of the sequence.

Be careful because, to operate the Makefile in the main directory, you might want to set-up constants in the file
Syllabus-MOOC/configure-mooc.sh (name of the course and all the stuff for the MOOC too).


