start_server {
    tags {type}
    overrides {
        maxmemory 0
        "list-max-ziplist-size" 16
    }
} {
    test {Explicit regression for a list bug} {
        set mylist {49376042582 {BkG2o\pIC]4YYJa9cJ4GWZalG[4tin;1D2whSkCOW`mX;SFXGyS8sedcff3fQI^tgPCC@^Nu1J6o]meM@Lko]t_jRyo<xSJ1oObDYd`ppZuW6P@fS278YaOx=s6lvdFlMbP0[SbkI^Kr\HBXtuFaA^mDx:yzS4a[skiiPWhT<nNfAf=aQVfclcuwDrfe;iVuKdNvB9kbfq>tK?tH[\EvWqS]b`o2OCtjg:?nUTwdjpcUm]y:pg5q24q7LlCOwQE^}}
        r del l
        r rpush l [lindex $mylist 0]
        r rpush l [lindex $mylist 1]
        assert_equal [r lindex l 0] [lindex $mylist 0]
        assert_equal [r lindex l 1] [lindex $mylist 1]
        r del mylist
    }

    tags {slow} {
        test {ziplist implementation: value encoding and backlink} {
            if {$::accurate} {set iterations 20} else {set iterations 2}
            for {set j 0} {$j < $iterations} {incr j} {
                ssdbr del l
                set l {}
                for {set i 0} {$i < 200} {incr i} {
                    randpath {
                        set data [string repeat x [randomInt 100000]]
                    } {
                        set data [randomInt 65536]
                    } {
                        set data [randomInt 4294967296]
                    } {
                        set data [randomInt 18446744073709551616]
                    } {
                        set data -[randomInt 65536]
                        if {$data eq {-0}} {set data 0}
                    } {
                        set data -[randomInt 4294967296]
                        if {$data eq {-0}} {set data 0}
                    } {
                        set data -[randomInt 18446744073709551616]
                        if {$data eq {-0}} {set data 0}
                    }
                    lappend l $data
                    ssdbr rpush l $data
                }
                assert_equal [llength $l] [ssdbr llen l]
                # Traverse backward
                for {set i 199} {$i >= 0} {incr i -1} {
                    if {[lindex $l $i] ne [ssdbr lindex l $i]} {
                        assert_equal [lindex $l $i] [ssdbr lindex l $i]
                    }
                }
            }
        }

        test {ziplist implementation: encoding stress testing} {
            if {$::accurate} {
                set nums 50
            } else {
                set nums 2
            }
            for {set j 0} {$j < $nums} {incr j} {
                ssdbr del l
                set l {}
                set len [randomInt 400]
                for {set i 0} {$i < $len} {incr i} {
                    set rv [randomValue]
                    randpath {
                        lappend l $rv
                        ssdbr rpush l $rv
                    } {
                        set l [concat [list $rv] $l]
                        ssdbr lpush l $rv
                    }
                }
                assert_equal [llength $l] [ssdbr llen l]
                for {set i 0} {$i < $len} {incr i} {
                    if {[lindex $l $i] ne [ssdbr lindex l $i]} {
                        assert_equal [lindex $l $i] [ssdbr lindex l $i]
                    }
                }
            }
        }
    }
}
