#! /usr/bin/wish
# TkS*LIDE - Snobol4 micro-IDE in Tcl/Tk
# Author: Rafal M. Sulejman <rms@poczta.onet.pl>
# All rights granted. All feedback welcome.

set ::VERSION "0.37"

proc populate_filetree {{name .}} {
    puts $name
		set iid [ string map -nocase { "." "_BASE_" "/" "_SEP_" } $name ]
		.ftree insert {} end -id "$iid" -text  "$name"
		foreach sdfile [ glob -nocomplain -directory $name -type f *] {
			.ftree insert "$iid" end -text "$sdfile"
		}

    foreach subdir [glob -nocomplain -directory $name -type d *] {
        populate_filetree $subdir
    }
}

proc newFile {w} {
#{{{
	if {[tk_messageBox -type yesno -default no \
		-title {Save file} \
		-icon warning \
		-message "Do you want to save the program?" ] == "yes" } {
		saveFileAs $w 1
	}
	$w delete 1.0 end
	set ::currentFile "unnamed.sno"
	wm title . "TkS*LIDE $::VERSION - $::currentFile"
#}}}
}

proc openFile {w {setTitle 0}} {
#{{{
	while {1} {
		set fileName [file nativename [tk_getOpenFile -filetypes $::filetypes ]]
		if {[string length $fileName] == 0} {
			break
		} elseif {[file exists $fileName] && \
			  [file readable $fileName]} {
			openNamedFile $w $fileName $setTitle
			break
		} else {
			tk_messageBox -icon error -title "Read error" \
			-message "File '$fileName' could not be read."
		}
	}
#}}}
}

proc openNamedFile {w fileName {setTitle 0}} {
#{{{
	set fd [open $fileName r]
	$w delete 1.0 end
	$w insert 1.0 [read $fd]
	close $fd
	if {$setTitle} {
		set ::currentFile $fileName
		ctext::highlight $w 1.0 "end -1c"
		wm title . "TkS*LIDE $::VERSION - $fileName"
	}
#}}}
}

proc saveFile {w fname} {
#{{{
	while {1} {
		set fileName $fname
		if {[string length $fileName] == 0} {
			break
		} elseif {[string match *unnamed.sno* $fileName]} {
			saveFileAs $w 1
			break
		} elseif {[catch {
			set fd [open $fileName w]
			puts -nonewline $fd [$w get 1.0 "end -1c"]
			close $fd
			set ::currentFile $fileName
			wm title . "TkS*LIDE $::VERSION - $::currentFile"
			} err] } {
			set answer [tk_messageBox -type retrycancel \
				-icon error -title "Write error" \
				-message "File '$fileName' could not be written.\n$err"]
			if{[string match "cancel" $answer]} {
				break
			}
			set $fileName ""
		} else {
			break
		}
	}
#}}}
}

proc saveFileAs {w {setTitle 0}} {
#{{{
	while {1} {
		set fileName [tk_getSaveFile -filetypes $::filetypes \
			-initialfile [file tail $::currentFile] ] 
		if {[string length $fileName] == 0} {
			break
		} elseif {[catch {
			set fd [open $fileName w]
			puts -nonewline $fd [$w get 1.0 "end -1c"]
			close $fd
			} err] } {
			set answer [tk_messageBox -type retrycancel \
				-icon error -title "Write error" \
				-message "File '$fileName' could not be written.\n$err"]
			if{[string match "cancel" $answer]} {
				break
			}
			set $fileName ""
		} else {
			if {$setTitle} {
				set ::currentFile $fileName
				wm title . "TkS*LIDE $::VERSION - $fileName"
			}
			break
		}
	}
#}}}
}

proc saveTranscript {w} {
#{{{
	set ft {
		{"Text files" {.txt} }
		{"All files" *}
	}

	while {1} {
		set fileName [tk_getSaveFile -filetypes $ft \
			-initialfile {transcript.txt} ] 
		if {[string length $fileName] == 0} {
			break
		} elseif {[catch {
			set fd [open $fileName w]
			set progname [file tail $::currentFile]
			puts $fd "TkS*LIDE $::VERSION"
			puts $fd "###########################"
			puts $fd "### Begin of transcript ###"
			puts $fd "###########################"
			puts $fd "\n### Commandline options ###"
			puts $fd "$::snobol4option"
			puts $fd "\n### Commandline parameters ###"
			puts $fd "$::snobol4param"
			puts $fd "\n### Program $progname ###"
			set src [$w get 1.0 "end -1c"]
			foreach line [split $src "\n"] {
				if {[regexp {\t} $line]} {
					set rec [split $line "\t"] 
					puts $fd \
						[format "%-9s %-40s %-20s" \
							[lindex $rec 0] \
							[lindex $rec 1] \
							[lindex $rec 2] ]
				} else {
					puts $fd $line
				}
			}
			puts $fd "\n### Input data ###"
			puts $fd [.input get 1.0 "end -1c"]
			puts $fd "\n### Output data ###"
			puts $fd [.output get 1.0 "end -1c"]
			puts $fd "\n### Error messages ###"
			puts $fd [.err get 1.0 "end -1c"]
			puts $fd "\n###########################"
			puts $fd "###  End of transcript  ###"
			puts $fd "###########################"
			close $fd
			} err] } {
			set answer [tk_messageBox -type retrycancel \
				-icon error -title "Write error" \
				-message "Transcript file '$fileName' could not be written.\n$err"]
			if{[string match "cancel" $answer]} {
				break
			}
			set $fileName ""
		} else {
			break
		}
	}
#}}}
}

proc runProgram {} {
#{{{
	set snobol4interp $::snobol4prog
	set program [file join [ ::fileutil::tempfile "tkslide"]]
	if {[string compare "$::language" "spitbol"]} {
		set snobol4interp $::snobol4prog
	} else {
		set snobol4interp  $::spitbolprog
	}
	set fd [open $program w]
	set pgm [.text get 1.0 "end -1c"]
	if { $::useUTFlibrary } {
		set pfd [open [file join $::rootdir "prefix.sno"]]
		puts $fd [read $pfd]
		close $pfd
	}
	puts -nonewline $fd  "$pgm"
	close $fd

	.output delete 1.0 end
	.err delete 1.0 end
	set ifd [open $::ifile w]
	puts -nonewline $ifd [.input get 1.0 "end -1c"]
	close $ifd
	update
	if { [catch {eval exec -keepnewline \
			[list $snobol4interp] $::snobol4option [list $program] \
			$::snobol4param \
			< [list $::ifile] \
			> [list $::ofile] \
			2> [list $::efile]} \
	       	results ]} {
		.err insert 1.0 "$results\n"
	} 
	# always show the error file - good idea, Howard!
	if {[file exists $::efile]&&[file readable $::efile]} {
		set efd [open $::efile r]
		set errtext [read $efd]
		regsub -all $program $errtext $::currentFile errtext
		.err insert "end -1c" $errtext
		close $efd
	}
	set ofd [open $::ofile r]
	.output insert 1.0 [read $ofd]
	close $ofd
#}}}
}

proc externalEdit {w} {
#{{{
	set program [file join [ ::fileutil::tempfile "tkslide" ]]
	saveFile $w $program
	# editor has to block the TkS*LIDE program till end of edit
	exec $::editorName $::editorParam $program
	set fd [open $program r]
	$w delete 1.0 end
	$w insert 1.0 [read $fd]
	close $fd
#}}}
}

proc endProgram {} {
#{{{
	if {[tk_messageBox -type yesno -default no \
		-title {Quitting TkS*LIDE} \
		-icon warning \
		-message "Do you want to quit?" ] == "yes" } {
		exit 0
	}
#}}}
}

proc urlOpen {url} {
#{{{
	if { ! [string match {^http://} $url] }	{
		if { $::tcl_platform(platform) == "windows" } {
			regsub -all "/" $url "\\\\" url
		}
	} 
	eval exec [list $::browser] [list $url] &
#}}}
}

proc preferences {} {
#{{{
	toplevel .x
	wm title .x "Preferences"
	frame .x.prefs
	grid .x.prefs -sticky news -columnspan 6
	grid columnconfigure .x.prefs 0 -weight 1 -uniform a
	grid columnconfigure .x.prefs 1 -weight 4 -uniform a
	grid columnconfigure .x.prefs 2 -weight 1 -uniform a
	grid [label .x.prefs.label_editorname -text "External editor"] [entry .x.prefs.editorname -textvariable ::editorName] [button .x.prefs.chooseEditor -text {Browse} -command {set ::editorName [file nativename [tk_getOpenFile]]} ] -sticky we
	grid [label .x.prefs.label_editorparam -text "Editor parameters"] [entry .x.prefs.editorparam -textvariable ::editorParam] -sticky we
	grid [label .x.prefs.label_encoding -text "Encoding"] [entry .x.prefs.encoding -textvariable ::encoding] -sticky we
	grid [label .x.prefs.label_browser -text "Browser"] [entry .x.prefs.browser -textvariable ::browser] [button .x.prefs.chooseBrowser -text {Browse} -command {set ::browser [file nativename [tk_getOpenFile]]} ] -sticky we
	grid [label .x.prefs.label_snobol4prog -text "Snobol4 path"] [entry .x.prefs.snobol4prog -textvariable ::snobol4prog] [button .x.prefs.chooseS4 -text {Browse} -command {set ::snobol4prog [file nativename [tk_getOpenFile]]} ] -sticky we
	grid [label .x.prefs.label_spitbolprog -text "Spitbol path"] [entry .x.prefs.spitbolprog -textvariable ::spitbolprog] [button .x.prefs.chooseSp -text {Browse} -command {set ::spitbolprog [file nativename [tk_getOpenFile]]} ] -sticky we
	if {0} {
		grid [label .x.prefs.label_snobol4option -text "Snobol4 options"] [entry .x.prefs.snobol4option -textvariable ::snobol4option] -sticky we
		grid [label .x.prefs.label_snobol4param -text ""] [entry .x.prefs.snobol4param -textvariable ::snobol4param] -sticky we
	}
	grid [label .x.prefs.label_customTabs -text "Use custom tabs"] [checkbutton .x.prefs.customTabs -variable ::customTabs] -sticky w
	grid [label .x.prefs.label_useUTFlib -text "Use UTF library"] [checkbutton .x.prefs.useUTFlib -variable ::useUTFlibrary -text {(Programs will use UTF replacements of Snobol4 functions)}] -sticky w
	grid [label .x.prefs.label_inputfile -text "Input file name"] [entry .x.prefs.inputfile -textvariable ::inputfile] -sticky we
	grid [label .x.prefs.label_outputfile -text "Output file name"] [entry .x.prefs.outputfile -textvariable ::outputfile] -sticky we
	grid [label .x.prefs.label_errfile -text "Error file name"] [entry .x.prefs.errfile -textvariable ::errfile] -sticky we
	grid [label .x.prefs.label_myfont -text "Font"] \
		[entry .x.prefs.myfont -textvariable ::myFont] \
		[button .x.prefs.save -text "Save" -command {
			set fd [open $::userRc "w"]
			puts $fd "set ::customTabs      {$::customTabs}"
			puts $fd "set ::editorName      {$::editorName}"
			puts $fd "set ::editorParam     {$::editorParam}"
			puts $fd "set ::snobol4prog     {$::snobol4prog}"
			puts $fd "set ::spitbolprog     {$::spitbolprog}"
			puts $fd "set ::snobol4option   {$::snobol4option}"
			puts $fd "set ::snobol4param    {$::snobol4param}"
			puts $fd "set ::inputfile       {$::inputfile}"
			puts $fd "set ::outputfile      {$::outputfile}"
			puts $fd "set ::errfile         {$::errfile}"
			puts $fd "set ::myFont          {$::myFont}"
			puts $fd "set ::encoding        {$::encoding}"
			puts $fd "set ::browser         {$::browser}"
			puts $fd "set ::geom            {$::geom}"
			puts $fd "set ::syntax          {$::syntax}"
			puts $fd "set ::useUTFlibrary   {$::useUTFlibrary}"
			close $fd
			destroy .x
		}] -sticky we

	set ::geom [winfo geometry .]
	grid [label .x.prefs.label_geom -text "Initial geometry"] \
		[entry .x.prefs.geom -textvariable ::geom] \
		[button .x.prefs.cancel -text "Cancel" -command {destroy .x}] -sticky we
	if {0} {
		tk_messageBox -default ok \
		-icon info \
		-message "to be implemented $::browser" \
		-title "Preferences" \
		-type ok
	}
	# focus on preferences windows
	focus .x
#}}}
}

proc aboutWindow {} {
#{{{
	set geom [winfo geometry .]
	set tclver [info patchlevel]
	set tkver $::tk_patchLevel
	set tclos [join [list $::tcl_platform(os) $::tcl_platform(osVersion)] { }]
	tk_messageBox -default "ok" \
		-icon info \
		-message \
"TkS*LIDE - a micro-IDE for Snobol4 
Version: $::VERSION 
Author: Rafal M. Sulejman <rms@poczta.onet.pl> 
All rights granted.
All feedback welcome. 

TCL: $tclver 
Tk: $tkver 
OS: $tclos
Snobol4: CSNOBOL4 1.2
		" \
		-title "About" \
		-type ok 
#}}}
}

proc creditsWindow {} {
#{{{
	#XXX Improve
	tk_messageBox -type ok -default ok -title {TkS*LIDE Help} \
		-icon info \
		-message [ join { "Ideas, testing and contributions:" \
			"\tBruce M. Axtens" \
			"\tHoward Bussey" \
			"\tDave Feustel" \
			"\tLarry Gregg" \
			"\tGuido Milanese" \
			"\tPhillip Thomas" \
			"\tDrScheme Team" \
			"\tDrJava Team" \
			"\tRichard Suchenwirth" \
			"CSnobol4 interpreter:"\
			"\tPhil Budne"\
			"Online help:"\
			"\tMark Emmer" \
			"\tJohn English"
			} "\n" ] 
#}}}
}

proc help {keyword} {
#{{{
	array set definition {
		output "output variable"
		input  "input variable"
		terminal "terminal variable"
	}

	set def [lindex [array get definition $keyword] 1]
	tk_messageBox -icon info -title "$keyword" -message "$def"
#}}}
}

proc checkOnlineUpdates {} {
#{{{
	#XXX improve (needs some work on server side...)
	urlOpen "https://github.com/tkslide/tkslide"
#}}}
}

proc popupTextMenu {text x y screenX screenY} {
#{{{
# taken from ML editor (and modified a bit)
	set t $text
	# place the insert cursor at the mouse pointer
	$t mark set insert @$x,$y
	set pos [$t index insert]

	# get the first being clicked-on
	set str [string trim [$t get "insert wordstart" "insert wordend"]]

	# create the pop-up menu for "find word"
	set pw .popup
	catch {destroy $pw}
	menu $pw -tearoff false

	# if the mouse was clicked over a word then show context help for the word
	if { $str != "" } {
		$pw add command -label "\"$str\" help" -command "help $str"
		$pw add separator
	}
	#undo/redo
	if { $::hasUndo } {
		$pw add command -label "Undo" -command  "$t edit undo" -underline 0 -accelerator Ctrl+Z
		$pw add command -label "Redo" -command  "$t edit redo" -underline 0 
		$pw add separator
	}
	# display the usual cut/copy/paste options
	$pw add command -label "Cut" -command "tk_textCut $t" -underline 0 -accelerator Ctrl+X
	$pw add command -label "Copy" -command "tk_textCopy $t" -underline 0 -accelerator Ctrl+C
	$pw add command -label "Paste" -command "tk_textPaste $t" -underline 0 -accelerator Ctrl+V
	$pw add separator
	$pw add command -label "Run" -command "runProgram" -underline 0 -accelerator Ctrl+R
	tk_popup $pw $screenX $screenY
#}}}
}

proc balloon {w help} {
#{{{
# taken from wiki.tcl.tk
   bind $w <Any-Enter> "after 1000 [list balloon:show %W [list $help]]"
   bind $w <Any-Leave> "destroy %W.balloon"
#}}}
}

proc balloon:show {w arg} {
#{{{
  if {[eval winfo containing  [winfo pointerxy .]]!=$w} {return}
  set top $w.balloon
  catch {destroy $top}
  toplevel $top -bd 1 -bg black
  wm overrideredirect $top 1
  if {$::tcl_platform(platform) == "macintosh"} {
   unsupported1 style $top floating sideTitlebar
  }
  pack [message $top.txt -aspect 10000 -bg lightyellow \
            -text $arg]
  set wmx [winfo rootx $w]
  set wmy [expr [winfo rooty $w]+[winfo height $w]]
  wm geometry $top \
    [winfo reqwidth $top.txt]x[winfo reqheight $top.txt]+$wmx+$wmy
  raise $top
#}}}
}

proc quickstartHelp {w} {
#{{{
	$w insert insert "Ctrl-R\trun program\n"
	$w insert insert "Ctrl-O\topen program\n"
	$w insert insert "Ctrl-S\tsave program\n"
	$w insert insert "Ctrl-Q\texit TkS*LIDE\n"
	$w insert insert "S-F4\texternal editor\n"
	$w insert insert "Alt-T\tfocus program text\n"
	$w insert insert "Alt-I\tfocus input\n"
	$w insert insert "Alt-O\tfocus output\n"
	$w insert insert "Alt-M\tfocus messages\n"
	$w insert insert "Alt-4\tfocus S4 options\n"
	$w insert insert "Alt-P\tfocus cmdln parameters\n"
	$w insert insert "Ctrl-F\tsearch and replace\n"
#}}}
}

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

#{{{ OS dependencies
set ::rootdir [file dirname [info script]]

if { $::tcl_platform(platform) == "windows" } { 
	wm state . zoomed
	set ::browser {C:\\programme\\mozilla\ firefox\\firefox}
	set ::userRc [file join $env(USERPROFILE)  "tksliderc"]
	set ::snobol4prog 		"snobol4"
	set ::spitbolprog 		"spitbol"
	set ::snobol4option 		"-b"
	set ::snobol4param 		""
	set ::inputfile 		"snobol4.in"
	set ::outputfile 		"snobol4.out"
	set ::errfile	 		"snobol4.err"
	set ::myFont			"Courier 10"
	set ::geom				"800x600"
} else {
	set ::userRc [file join $env(HOME) ".tksliderc"]
	set ::browser "konqueror"
	set ::snobol4prog 		"snobol4"
	set ::snobol4option 		"-b"
	set ::snobol4param 		""
	set ::inputfile 		"snobol4.in"
	set ::outputfile 		"snobol4.out"
	set ::errfile	 		"snobol4.err"
	set ::myFont			"Courier 10"
	set ::geom				"800x600"
} 
#}}}

#{{{ vars
set ::resdir [file join $::rootdir "res"]
set ::systemRc [file join $::rootdir "tksliderc"]
set ::currentFile "unnamed.sno"
#set ::btnStyle {groove}
set ::btnStyle {flat}
set ::searchText ""
set ::searchDirection 0
set ::syntax 1
set ::useUTFlibrary 1
set ::customTabs 1
set ::encoding "utf-8"
# external editor (must be run in foreground)
set ::editorName "gvim"
set ::editorParam "-f"
#}}}

# Tcl/Tk version differences
if { $tcl_version < 8.4 } {
	set ::hasUniform 0
	set ::hasUndo 0
} else {
	set ::hasUniform 1
	set ::hasUndo 1
}

set filetypes {
	{"Snobol4 programs" {.sno} }
	{"Spitbol programs" {.spt} }
	{"Include files"    {.inc} }
	{"All files"        *      }
}

append icnOpen [file join $::resdir "fileopen-48.gif"]
append icnSave [file join $::resdir "filesave-48.gif"]
append icnSvAs  [file join $::resdir "filesaveas-48.gif"]
append icnTran  [file join $::resdir "filesave2-48.gif"]
append icnRunP  [file join $::resdir "filerun-48.gif"]
append icnCut   [file join $::resdir "editcut-48.gif"]
append icnCopy  [file join $::resdir "editcopy-48.gif"]
append icnPaste [file join $::resdir "editpaste-48.gif"]


set options {
	{r	"Snobol4's -r switch"}
	{f.arg	"unnamed.sno" "Load file on startup"}
}
set usage ": tkslide.tcl \[-r]:"

# append current dir to the library searchpath
set auto_path [linsert $auto_path 0 [file join $::rootdir "lib"]]
package require Tcl 8
package require Tk 8
package require fileutil
package require ctext
package require find

if {[file exists $::userRc] && [file readable $::userRc]} {
	source $::userRc
} else {
	source $::systemRc
}
set ::snips [file join $rootdir "snippets.txt"]
set ::ifile [file join [::fileutil::tempdir] $::inputfile]
set ::efile [file join [::fileutil::tempdir] $::errfile]
set ::ofile [file join [::fileutil::tempdir] $::outputfile]

array set params [::cmdline::getoptions argv $options $usage]
set ::has_r $params(r)
set ::fileArg $params(f)

if { $::customTabs } {
	set tabs {2c 12c left}
} else {
	set tabs {}
}

encoding system $::encoding

#{{{ Toolbar
frame .toolbar
	button .toolbar.open -image [image create photo -file $icnOpen] -text "Open" -width 34 -command {openFile .text 1} -relief $::btnStyle
	balloon .toolbar.open "Open file..."
	button .toolbar.save -image [image create photo -file $icnSave] -text "Save" -width 34 -command {saveFile .text $::currentFile} -relief $::btnStyle 
	balloon .toolbar.save "Save file"
	button .toolbar.saveas -image [image create photo -file $icnSvAs] -text "Save as" -width 34 -command {saveFileAs .text 1} -relief $::btnStyle 
	balloon .toolbar.saveas "Save file as..."
	button .toolbar.transcript -image [image create photo -file $icnTran] -text "Transcript" -width 34 -command {saveTranscript .text} -relief $::btnStyle 
	balloon .toolbar.transcript "Save transcript file as..."
	button .toolbar.cut -image [image create photo -file $icnCut] -text "Cut" -width 34 -command {.text cut} -relief $::btnStyle
	balloon .toolbar.cut "Cut"
	button .toolbar.copy -image [image create photo -file $icnCopy] -text "Copy" -width 34 -command {.text copy} -relief $::btnStyle
	balloon .toolbar.copy "Copy"
	button .toolbar.paste -image [image create photo -file $icnPaste] -text "Paste" -width 34 -command {.text paste} -relief $::btnStyle
	balloon .toolbar.paste "Paste"
	pack .toolbar.open .toolbar.save .toolbar.saveas .toolbar.transcript \
		.toolbar.cut .toolbar.copy .toolbar.paste \
		-in .toolbar -anchor w -side left -padx 1 -pady 1
#}}}

#{{{Parameter bar
frame .rtparam 
	radiobutton .langSnobol4 -text {Snobol4} -variable ::language -value {snobol4}
	radiobutton .langSpitbol -text {Spitbol} -variable ::language -value {spitbol}
	label .s4optlab -text "Snobol4 options:" -underline 3
	entry .s4option -bg white -font $::myFont -textvariable ::snobol4option
	label .s4parlab -text "Parameters:" -underline 0
	entry .s4param -bg white -font $::myFont -textvariable ::snobol4param
	#button .s4run -bitmap @$icnRunP -text "Run" -underline 0 -width 34 -command {runProgram} -relief $::btnStyle
	button .s4run -image [image create photo -file $icnRunP ] -text "Run" -underline 0 -width 34 -command {runProgram} -relief $::btnStyle
	balloon .s4run "Run program"
	pack .langSnobol4 .langSpitbol -in .rtparam -anchor w -side left -fill both -pady 1 -padx 1
	.langSnobol4 select
	pack .s4optlab -in .rtparam -anchor w  -side left   -fill both -pady 1 -padx 1
	pack .s4option -in .rtparam -anchor w  -side left   -fill both -pady 1 -padx 1
	balloon .s4option "Enter Snobol4 options here"
	pack .s4run    -in .rtparam -anchor w  -side right             -pady 1 -padx 1
	pack .s4parlab -in .rtparam -anchor w  -side left   -fill both -pady 1 -padx 1
	pack .s4param  -in .rtparam -anchor w               -fill both -pady 1 -padx 1 -expand yes
	balloon .s4param "Enter program parameters here"
	pack .s4run -in .toolbar -anchor e -side right -padx 1 -pady 1
#}}}

#XXX to be fixed?
if { $::hasUndo } {
	ctext .text -linemap 1 -bg white -fg black -insertbackground black \
		-yscrollcommand {.vscroll set} -xscrollcommand {.hscroll set} \
		-font $::myFont \
		-tabs $tabs \
		-undo 1 -maxundo 0
} else {
	ctext .text -linemap 1 -bg white -fg black -insertbackground black \
		-yscrollcommand {.vscroll set} -xscrollcommand {.hscroll set} \
		-font $::myFont \
		-tabs $tabs \
		-undo 1 -maxundo 0
}

# load file if specified on commandline
if { [string length $::fileArg] > 0 && \
	 $::fileArg != "unnamed.sno" } {
	openNamedFile .text $::fileArg 1
} 

if { $::has_r } {
	set ::snobol4option "-rb"
	text .input  -bg gray -fg black -wrap word \
		-takefocus 1 \
		-font $::myFont \
		-state disabled
} else {
	text .input  -bg white -fg black -wrap word \
		-takefocus 1 \
		-font $::myFont \
		-yscrollcommand {.invscroll set} 
}

text .snippet -bg white -fg black -font $::myFont \
		-undo 1 -maxundo 0 \
		-yscrollcommand {.snipvscroll set} 

ttk::treeview .ftree
populate_filetree

if { [file exists $::ifile] && [file readable $::ifile] } {
	openNamedFile .input $::ifile 0
}

if { [file exists $::snips] && [file readable $::snips] } {
	openNamedFile .snippet $::snips 0
}
text .output -bg white -fg darkgreen \
	-wrap word  -takefocus 1 \
	-font $::myFont \
	-yscrollcommand {.outvscroll set} 

text .err -bg white -fg red \
	-wrap word  -takefocus 1 \
	-font $::myFont \
	-yscrollcommand {.errvscroll set} 

scrollbar .invscroll -orient vertical -command ".input yview"
scrollbar .outvscroll -orient vertical -command ".output yview"
scrollbar .errvscroll -orient vertical -command ".err yview"
scrollbar .hscroll -orient horizontal -command ".text xview"
scrollbar .vscroll -orient vertical -command ".text yview"
#scrollbar .snipvscroll -orient vertical -command ".snippet yview"
scrollbar .snipvscroll -orient vertical -command ".ftree yview"

frame .status
label .status.text -text "Program text:" -underline 8
label .status.file -textvariable ::currentFile
set custTabs $::customTabs
checkbutton .status.customTabs -text "Tabs" -variable custTabs -command {
	if { $custTabs == "1" } { 
		set tabs {2c 12c left} 
	} else { 
		set tabs {} 
	} 
	.text configure -tabs $tabs
}
checkbutton .status.useUTFlibrary -text "UTF hack" -variable ::useUTFlibrary 

pack .status.text -side left
pack .status.file -side left -fill x
pack .status.useUTFlibrary -side right
pack .status.customTabs -side right

label .intxt  -text "Input" -underline 0
label .outtxt -text "Output" -underline 0
label .errtxt -text "Messages" -underline 0

grid .toolbar -sticky ew -columnspan 5
grid .rtparam -sticky ew -columnspan 5
#grid .snippet -row 2 -sticky nsew -column 0 
grid .ftree -row 2 -sticky nsew -column 0
grid .snipvscroll -row 2 -sticky nsew -column 1
grid .text -row 2 -sticky nsew -columnspan 3 -column 2
grid .vscroll -row 2 -sticky nsew -column 5
grid .hscroll -row 3 -sticky ew -columnspan 5  -column 1
grid .status -row 4 -sticky ew -columnspan 5 -column 1
grid .input .invscroll .output .outvscroll .err .errvscroll -sticky nwes
grid .intxt .outtxt .errtxt -sticky ew -columnspan 2

grid rowconfigure . 0 
grid rowconfigure . 1 
if { $::hasUniform } {
	grid rowconfigure . 2 -weight 2 -uniform a
	grid rowconfigure . 5 -weight 1 -uniform a
} else {
	grid rowconfigure . 2 -weight 2 
	grid rowconfigure . 5 -weight 1 
}
grid rowconfigure . 3 -weight 0 
grid rowconfigure . 4 -weight 0
grid rowconfigure . 6 -weight 0
grid columnconfigure . {0 2 4} -weight 1

#{{{ Main menu
menu .menu
	# File menu
	menu .menu.file -tearoff 0
		.menu add cascade -menu .menu.file -label "File" -underline 0
		.menu.file add command -label "New" -underline 0 -command {newFile .text}
		.menu.file add command -label "Open" -underline 0 -command {openFile .text 1}
		.menu.file add command -label "Open input" -underline 5 -command {openFile .input 0}
		.menu.file add command -label "Save" -underline 0 -command {saveFile .text $::currentFile}
		.menu.file add command -label "Save as" -underline 5 -command {saveFileAs .text 1}
		.menu.file add separator
		.menu.file add command -label "Save transcript" -underline 5 -command {saveTranscript .text}
		.menu.file add separator
		.menu.file add command -label "Exit" -underline 1 -command {endProgram}

	# Edit menu
	menu .menu.edit -tearoff 0
		.menu add cascade -menu .menu.edit -label "Edit" -underline 0
		if { $::hasUndo } {
			.menu.edit add command -label "Undo" -underline 0 -command {.text edit undo}
			.menu.edit add command -label "Redo" -underline 0 -command {.text edit redo}
			.menu.edit add separator
		}
		.menu.edit add command -label "Cut" -command {.text cut}
		.menu.edit add command -label "Copy" -command {.text copy}
		.menu.edit add command -label "Paste" -command {.text paste}
		.menu.edit add command -label {Search&Replace} -command {searchrep .text}
		.menu.edit add separator
		.menu.edit add command -label "External editor" -underline 0 -command {externalEdit .text}
		.menu.edit add separator
		.menu.edit add command -label "Preferences" -underline 0 -command {preferences}

	# Snobol4 menu
	menu .menu.snobol -tearoff 0
		.menu add cascade -menu .menu.snobol -label "Snobol4" -underline 0
		.menu.snobol add command -label "Run" -underline 0 -command {runProgram}
		.menu.snobol add separator
		.menu.snobol add command -label "Clear output" -underline 6 -command { .output delete 1.0 end }
		.menu.snobol add command -label "Clear input" -underline 6 -command { .input delete 1.0 end }
		.menu.snobol add command -label "Clear errors" -underline 6 -command { .err delete 1.0 end }

	# Syntax menu
	menu .menu.syntax -tearoff 1
		.menu add cascade -menu .menu.syntax -label "Syntax" -underline 4
		.menu.syntax add command -label "function" -underline 0 \
			-command { .text insert insert "\n\tdefine('fname(param)localvars')\t:(fname_end)\nfname\t\t:f(freturn)\n\t\t:(return)\nfname_end\n" }
		.menu.syntax add command -label "data" -underline 0 \
			-command { .text insert insert "\n\tdata('typename(fields)')\n" }
		.menu.syntax add command -label "code" -underline 0 \
			-command { .text insert insert "\n* string must start with label or whitespace\n\tvar = code(string)\t:s<var>f(compile_error)\ncompile_error\n" }
		.menu.syntax add command -label "input(...)" -underline 0 \
			-command { .text insert insert "\n\tinput('variable', unit, length, 'file')\n" }
		.menu.syntax add command -label "output(...)" -underline 0 \
			-command { .text insert insert "\n\toutput('variable', unit, length, 'file')\n" }

	# Help menu
	menu .menu.help -tearoff 0
		.menu add cascade -menu .menu.help -label "Help" -underline 0
		.menu.help add command -label "TkS*LIDE Help" -underline 9 \
			-command {urlOpen [format "%s/doc/slide/contents.htm" $::rootdir]}
		.menu.help add command -label "Snobol4 Manual" -underline 8 \
			-command {urlOpen [format "%s/doc/manual/contents.htm" $::rootdir]}
		.menu.help add command -label "Snobol4 Tutorial" -underline 8 \
			-command {urlOpen [format "%s/doc/tutorial/contents.htm" $::rootdir]}
		.menu.help add separator
		.menu.help add command -label "Check for updates" -underline 0 \
			-command {checkOnlineUpdates}
		.menu.help add separator
		.menu.help add command -label {Phil Budne's SNOBOL4 Resources page} -underline 0 \
			-command {urlOpen {http://www.regressive.org/snobol4}}
		.menu.help add command -label "RosettaCode.org SNOBOL4 code" -underline 0 \
			-command {urlOpen {http://rosettacode.org/wiki/Category:SNOBOL4}}
		.menu.help add command -label {SNOBOL4 Yahoo!Group} -underline 0 \
			-command {urlOpen {http://tech.groups.yahoo.com/group/snobol}}
		.menu.help add command -label {Fred Weigel's SNOLIB function library} -underline 0 \
			-command {urlOpen {https://github.com/ratboy666/snolib}}
		.menu.help add command -label {Snobol4 at tio.run online interpreter collection} -underline 0 \
			-command {urlOpen {https://tio.run/#snobol4}}
		.menu.help add separator
		.menu.help add command -label "Credits" -underline 0 \
			-command {creditsWindow}
		.menu.help add command -label "About" -underline 0 \
			-command {aboutWindow}
#}}}

# popup menu
set programMenu [menu .popupMenu -tearoff 0]
	$programMenu add command -label "Cut" -command {.text cut}
	$programMenu add command -label "Copy" -command {.text copy}
	$programMenu add command -label "Paste" -command {.text paste}
	$programMenu add command -label "Clear" -command {.text delete 1.0 end}
	$programMenu add separator
	$programMenu add command -label "Run" -command {runProgram}

set inputMenu [menu .inputPopupMenu -tearoff 0]
	$inputMenu add command -label "Read input file" \
		-command {openFile .input 0}
	$inputMenu add command -label "Clear" \
		-command {.input delete 1.0 end}

set inputMenu [menu .outputPopupMenu -tearoff 0]
	$inputMenu add command -label "Save output as..." \
		-command {saveFileAs .output 0}
	$inputMenu add command -label "Clear" \
		-command {.output delete 1.0 end}

set inputMenu [menu .errPopupMenu -tearoff 0]
	$inputMenu add command -label "Clear" \
		-command {.err delete 1.0 end}

set inputMenu [menu .snippetPopupMenu -tearoff 0]
	$inputMenu add command -label "Paste snippet" \
		-command {.text insert insert [.snippet get [.snippet index insert-1l+1c] [.snippet index insert+1l-1c]]; .text insert end "\n"}
	$inputMenu add command -label "Paste selection" \
		-command {.text insert insert "\n"; .text paste [tk_textCopy .snippet]; .text insert insert "\n"}

#{{{ Bindings
bind . <F2> {saveFileAs .text 1}
bind . <Control-s> {
	if {[string equal $::currentFile "unnamed.sno"]} {
		saveFileAs .text 1
	} else {
		saveFile .text $::currentFile
	}
}
bind . <Control-x><Control-s> {saveFile .text $::currentFile}
bind . <Control-o> {openFile .text 1}
bind . <Control-x><Control-f> {openFile .text 1}
bind . <Shift-F5> {runProgram}
bind . <Control-r> {runProgram}
bind . <Alt_L><r> {runProgram}
bind . <Shift-F4> {externalEdit .text}
bind . <Control-q> {endProgram}
bind . <Control-x><Control-c> {endProgram}
bind . <Alt_L><b> {focus .s4option}
bind . <Alt_L><p> {focus .s4param}
bind . <Alt_L><i> {focus .input}
bind . <Alt_L><o> {focus .output}
bind . <Alt_L><m> {focus .err}
bind . <Alt_L><t> {focus .text.t}
if { $tcl_version < 8.5 } {
	bind .text <Control-v> {.text paste}
}
bind . <ButtonPress-1><ButtonPress-2> {.text cut}
bind .text <F3> {searchrep .text}
bind .text <Control-f> {searchrep .text}
bind .text <ButtonPress-3> "popupTextMenu .text %x %y %X %Y"
bind .output <F3> {searchrep .output}
bind .output <Control-f> {searchrep .output}
bind .output <ButtonPress-3> {tk_popup .outputPopupMenu %X %Y}
bind .input <F3> {searchrep .input}
bind .input <Control-f> {searchrep .input}
bind .input <ButtonPress-3> {tk_popup .inputPopupMenu %X %Y}
bind .err <F3> {searchrep .err}
bind .err <Control-f> {searchrep .err}
bind .err <ButtonPress-3> {tk_popup .errPopupMenu %X %Y}
bind .snippet <ButtonPress-3> {tk_popup .snippetPopupMenu %X %Y}
bind .snippet <ButtonPress-1><ButtonPress-3> {
	.text insert insert [.snippet get [.snippet index insert-1l+1c] [.snippet index insert+1l-1c]]
	.text insert end "\n"
}

bind .ftree <ButtonPress-1><ButtonPress-1> {
	set ftsel [.ftree selection ]
	set fttext [ .ftree item $ftsel -text ]
	puts $fttext
	if {[string length $fttext] > 0} {
		if {[ file type "$fttext" ] == "file" } {
			openNamedFile .text "$fttext" 1
		} else {
			puts "Directory: $fttext"
		}
	}
}

bind . <F5> { 
	toplevel .console
	entry .console.e -textvar cmd
	bind .console.e <Key-Return> {go %W}
	text .console.t -wrap word
	.console.t tag configure stdout -foreground blue
	.console.t tag configure stdin  -foreground black
	.console.t tag configure stderr -foreground red
	proc go {w} {
		global cmd
		.console.t insert end "% $cmd\n" stdin
		if {[catch {uplevel #0 eval $cmd} res] == 1} {
			.console.t insert end "$res\n" stderr
		} else {
			.console.t insert end "$res\n" stdout
		}
		set cmd ""
	}
	eval pack [winfo children .console] -fill both -expand 1
	focus .console.e
}
#}}}

wm title . "TkS*LIDE $::VERSION - $::currentFile"
wm protocol . WM_DELETE_WINDOW endProgram
wm geometry . $::geom
. configure -relief groove -borderwidth 1
. configure -menu .menu
quickstartHelp .err
setHilight .text
focus .text.t

# vim: set ff=unix ts=4 sw=4 :
