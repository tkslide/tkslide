set ::tabs {2c 12c 55c left}
set ::snobol4prog {/usr/local/bin/snobol4}
set ::snobol4option {-br}

set ::rootdir [file dirname [info script]]
set auto_path [linsert $auto_path 0 [file join $::rootdir "lib"]]
package require Tcl 8
package require Tk 8
package require fileutil
package require ctext
package require find


set options {
	{r	"Snobol4's -r switch"}
	{f.arg	"unnamed.sno" "Load file on startup"}
}
set usage ": snotty \[-r]:"
array set params [::cmdline::getoptions argv $options $usage]

set ::wid 1
set ::syntax 1

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

proc file_dup {fname} {
	set txt [[focus] get 1.0 "end -1c" ]
	set topname ".top$::wid"
	toplevel $topname
	pack [createwin $topname.editor]
	$topname.editor insert insert $txt
	set ::wid [expr "$::wid + 1"]
}

proc file_new {fname} {
	set topname ".top$::wid"
	toplevel $topname
	pack [createwin $topname.editor]
	set ::wid [expr "$::wid + 1"]
}

proc file_run {id} {
	puts "run $id"
	set currwin [focus]
	set program [file join [ ::fileutil::tempfile "tkslide."]]
	set ifile [file join [ ::fileutil::tempfile "tkslide.in."]]
	set ofile [file join [ ::fileutil::tempfile "tkslide.out."]]
	set efile [file join [ ::fileutil::tempfile "tkslide.err."]]
	set fd [open $program w]
	set pgm [$currwin get 1.0 "end -1c"]
	puts -nonewline $fd  "$pgm"
	close $fd
	if { [catch {eval exec -keepnewline \
			[list $::snobol4prog] \
			[list $::snobol4option] \
			[list $program] \
			< [list $ifile] \
			> [list $ofile] \
			2> [list $efile] \
		} results ] } { 
				$currwin insert "end" "$results\n" 
	  } 
		set ofd [open $ofile r]
		$currwin insert "end" "\n"
		$currwin insert "end" [read $ofd]
		close $ofd
}

proc file_close {id} {
	puts "close $::wid"
	destroy [winfo parent [focus]]
	destroy [focus]
	
	set ::wid [expr "$::wid - 1"]
	if { $::wid == 0 } {
		destroy .
	}
}

proc createwin {winid} {
	set winid [ctext $winid -tabs $::tabs]
	bind $winid <Control-d> {file_dup  ""}
	bind $winid <Control-n> {file_new  ""}
	bind $winid <Control-o> {file_open "" }
	bind $winid <Control-q> {file_close ""}
	bind $winid <Control-r> {file_run  "" }
	bind $winid <Control-s> {file_save "" }
	setHilight $winid
	wm title [winfo parent $winid] "SnoTTY"
	wm protocol [winfo parent $winid] WM_DELETE_WINDOW {
		file_close ""
	}

	return $winid
}

wm withdraw .
toplevel .top0
pack [createwin .top0.editor]
