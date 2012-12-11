set ::wid 1
set ::syntax 1
set ::rootdir [file dirname [info script]]
set auto_path [linsert $auto_path 0 [file join $::rootdir "lib"]]
package require Tcl 8
package require Tk 8
package require fileutil
package require ctext
package require find


proc setHilight {w} {
#{{{
	if { $::syntax }   {
		# syntax highlighting
		ctext::addHighlightClass $w s4inout red {input output terminal}
		ctext::addHighlightClassForRegexp $w s4directives blue {^-.*$}
		ctext::addHighlightClassWithOnlyCharStart $w s4sysvars orange "&"
		ctext::addHighlightClassForRegexp $w s4label1 darkgreen {^[a-zA-Z][^ \t]*}
		# label after ";"
		ctext::addHighlightClassForRegexp $w s4label2 darkgreen {;[a-zA-Z][^ \t]*}
		ctext::addHighlightClassForRegexp $w s4continuation brown {^\+}
		ctext::addHighlightClassForRegexp $w s4func red {\S+\(}
		ctext::addHighlightClassForSpecialChars $w brackets darkgreen {[]\(\)}
		ctext::addHighlightClassForRegexp $w s4goto darkgreen {:([FfSs]*[<\(].*?[>\)])+}
		# disable syntax within string
		ctext::addHighlightClassForRegexp $w s4string brown {([\"']).*?\1}
		# comments override everything
		ctext::addHighlightClassForRegexp $w s4comment1 blue {^\*[^\n\r]*$}
		# comment after ";"
		ctext::addHighlightClassForRegexp $w s4comment2 blue {;\*[^\n\r]*$}
	} else {
		ctext::clearHighlightClasses $w 
	}
#}}}
}
proc file_save {id} {
	puts "save $id"
}

proc file_open {id} {
	puts "open $id"
}

proc file_new {fname} {
	set topname ".top$::wid"
	toplevel $topname
	pack [createwin $topname.editor]
	set ::wid [expr "$::wid + 1"]
}

proc file_run {id} {
	puts "run $id"
}

proc file_close {id} {
	puts "close $::wid"
	destroy [winfo parent [winfo parent [focus]]]
	set ::wid [expr "$::wid - 1"]
	if { $::wid == 0 } {
		destroy .
	}
}

proc createwin {winid} {
	set winid [ctext $winid]
	bind $winid <Control-s> {file_save "" }
	bind $winid <Control-o> {file_open "" }
	bind $winid <Control-n> {file_new  ""}
	bind $winid <Control-r> {file_run  "" }
	bind $winid <Control-q> {file_close ""}
	setHilight $winid
	wm title [winfo parent $winid] "SnoTTY"

	return $winid
}

wm withdraw .
toplevel .top0
pack [createwin .top0.edit]
