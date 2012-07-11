#! /bin/bash
DDIR=/tmp/dos/tkslide ; [ -d $DDIR ] || mkdir -p $DDIR
UDIR=/tmp/unix/tkslide ; [ -d $UDIR ] || mkdir -p $UDIR
DRT=$DDIR/runtime ; [ -d $DRT ] || mkdir -p $DRT
URT=$UDIR/runtime ; [ -d $URT ] || mkdir -p $URT


while read SRC ; do cp -r $SRC $UDIR; cp -r $SRC $DDIR ; done <<_1_
BUGS
CHANGES
doc
example
INSTALL
lib
prefix.sno
README
res
tksliderc
tkslide.tcl
TODO
_1_

while read SRC ; do cp -r $SRC $URT; done <<_2_
runtime/snoTerm
runtime/tclkit-linux-x86
runtime/tclkit-linux-x86_64
_2_

while read SRC ; do cp -r $SRC $UDIR; done <<_3_
slide
_3_

while read SRC ; do cp -r $SRC $DRT; done <<_4_
runtime/snoTerm.bat
runtime/tclkit.exe
_4_

while read SRC ; do cp -r $SRC $DDIR; done <<_5_
slide.bat
snobol4-1.2
_5_

cd $DDIR/.. ; zip -qr /tmp/tkslide.zip tkslide 
cd $UDIR/.. ; tar czf /tmp/tkslide.tar.gz tkslide 
rm -rf /tmp/{dos,unix}
