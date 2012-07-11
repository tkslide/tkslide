package require Tcl 8.2
package provide find 1.0

namespace eval ::find {
	namespace export searchrep
}
#-- find dialog
proc searchrep {t {replace 1}} {
   set w .sr
   if ![winfo exists $w] {
       toplevel $w
       wm title $w "Search"
       grid [label $w.1 -text Find:] [entry $w.f -textvar Find] \
               [button $w.bn -text Next \
               -command [list searchrep'next $t]] -sticky ew
       bind $w.f <Return> [list $w.bn invoke]
       if $replace {
           grid [label $w.2 -text Replace:] [entry $w.r -textvar Replace] \
                   [button $w.br -text Replace \
                   -command [list searchrep'rep1 $t]] -sticky ew
           bind $w.r <Return> [list $w.br invoke]
           grid x x [button $w.ba -text "Replace all" \
                   -command [list searchrep'all $t]] -sticky ew
       }
       grid x [checkbutton $w.i -text "Ignore case" -variable IgnoreCase] \
               [button $w.c -text Cancel -command "destroy $w"] -sticky ew
       grid $w.i -sticky w
       grid columnconfigure $w 1 -weight 1
       $t tag config hilite -background yellow
	   focus $w.f
   } else {raise $w}
}

#-- Find the next instance
proc searchrep'next w {
    foreach {from to} [$w tag ranges hilite] {
        $w tag remove hilite $from $to
    }
    set cmd [list $w search -count n -- $::Find insert+2c]
    if $::IgnoreCase {set cmd [linsert $cmd 2 -nocase]}
    set pos [eval $cmd]
    if {$pos ne ""} {
        $w mark set insert $pos
        $w see insert
        $w tag add hilite $pos $pos+${n}c
    }
}

#-- Replace the current instance, and find the next
proc searchrep'rep1 w {
    if {[$w tag ranges hilite] ne ""} {
        $w delete insert insert+[string length $::Find]c
        $w insert insert $::Replace
        searchrep'next $w
        return 1
    } else {return 0}
}

#-- Replace all 
proc searchrep'all w {
    set go 1
    while {$go} {set go [searchrep'rep1 $w]}
}

