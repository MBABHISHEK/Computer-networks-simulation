set val(chan)       	Channel/WirelessChannel
set val(type)       	GSM
set val(prop)       	Propagation/TwoRayGround
set val(netif)      	Phy/WirelessPhy
set val(mac)        	Mac/802_11
set val(ifq)       	Queue/DropTail/PriQueue
set val(ll)        	LL
set val(ant)        	Antenna/OmniAntenna
set val(x)              1500   
set val(y)              1500   
set val(ifqlen)         1000           
set val(adhocRouting)   AODV
set val(nn)             10
set val(stop)         	5.0           

set f0 [open out02.tr w]
set f1 [open lost02.tr w]
set f2 [open delay02.tr w]

set ns_			[new Simulator]
set topo		[new Topography]

set tracefd		[open out.tr w]
set namtrace    	[open out.nam w]

$ns_ trace-all $tracefd
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)

$topo load_flatgrid $val(x) $val(y)
	
set god_ [create-god $val(nn)]
$ns_ color 0 red
$ns_ node-config -adhocRouting AODV \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
                 -channelType $val(chan) \
	       	-energyModel EnergyModel \
		-initialEnergy 100 \
		 -rxPower 0.3 \
		 -txPower 0.6 \
		 -topoInstance $topo \
                 -agentTrace ON \
                 -routerTrace ON \
                 -macTrace OFF 




for {set i 0} {$i < $val(nn) } {incr i} {
	set node_($i) [$ns_ node]	
			
}


 set X1(0) 1035.201 
 set Y1(0) 444.699
 set X1(1) 244.365
 set Y1(1) 521.418
 set X1(2) -18.1268
 set Y1(2) 300.612
 set X1(3) 723.89
 set Y1(3) 343.533
 set X1(4) 122.34
 set Y1(4) 311.755
 set X1(5) 373.498
 set Y1(5) 472.206
 set X1(6) 548.549 
 set Y1(6) 361.062
 set X1(7) 389.995
 set Y1(7) 381.178
 set X1(8) 494.798
 set Y1(8) 477.771
 set X1(9) 275.01
 set Y1(9) 381.99


for {set i 0} {$i < $val(nn) } {incr i} {
	$node_($i) set X_ $X1($i)
        $node_($i) set Y_ $Y1($i)
        $node_($i) set Z_ 0.0
	

}

puts "---------------------------------------"
set m 0
puts "----------------------------------------"
puts "|    Node      |  One hop neighbour    |"
puts "----------------------------------------"
for {set i 0} {$i < $val(nn) } {incr i} {

set k 0
for {set j 0} {$j < $val(nn) } {incr j} {


set a [ expr $X1($j)-$X1($i)]
set b [ expr $a*$a]
set c [ expr $Y1($j)-$Y1($i)]
set d [ expr $c*$c]
set e [ expr $b+$d]
set f 0.5
set g [expr pow($e,$f)]
#puts "Distance from node($i) --to--node($j)----------->$g"
if {$g <= 200 && $i != $j} {

puts "|    node($i)     |     node($j)       |"

set nei($m) $j    

set k [expr $k+1]  
set m [ expr $m+1]                               
} 

}
puts "----------------------------------------"
}


 puts "Loading connection pattern..."


puts "Loading scenario file..."
for {set i 0} {$i < $val(nn) } {incr i} {

    $ns_ initial_node_pos $node_($i) 45
}

for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at $val(stop).0 "$node_($i) reset";
}

set udp_(0) [new Agent/UDP]
$ns_ attach-agent $node_(2) $udp_(0)
set sink [new Agent/LossMonitor]
$ns_ attach-agent $node_(3) $sink
set cbr1_(0) [new Application/Traffic/CBR]
$cbr1_(0) set packetSize_ 1000
$cbr1_(0) set interval_ 0.1
$cbr1_(0) set maxpkts_ 1000
$cbr1_(0) attach-agent $udp_(0)
$ns_ connect $udp_(0) $sink
$ns_ at 1.00 "$cbr1_(0) start"

set holdtime 0
set holdseq 0

set holdrate1 0

proc record {} {
global sink  f0 f1 f2 holdtime holdseq holdrate1 

set ns [Simulator instance]
set time 0.9 ;#Set Sampling Time to 0.9 Sec

set bw0 [$sink set bytes_]
set bw1 [$sink set nlost_]

set bw2 [$sink set lastPktTime_]
set bw3 [$sink set npkts_]

set now [$ns now]
       
        # Record Bit Rate in Trace Files
        puts $f0 "$now [expr (($bw0+$holdrate1)*8)/(2*$time*1000000)]"

 
        # Record Packet Loss Rate in File
        puts $f1 "$now [expr $bw1/$time]"

if { $bw3 > $holdseq } {
                puts $f2 "$now [expr ($bw2 - $holdtime)/($bw3 - $holdseq)]"
        } else {
                puts $f2 "$now [expr ($bw3 - $holdseq)]"
        }

$sink set bytes_ 0
$sink set nlost_ 0

set holdtime $bw2
set holdseq $bw3
 
set  holdrate1 $bw0
    $ns at [expr $now+$time] "record"   ;# Schedule Record after $time interval sec
}
 
 
# Start Recording at Time 0
$ns_ at 0.0 "record"

source link1.tcl

proc stop {} {
        global ns_ tracefd f0 f1 f2 
 
        # Close Trace Files
        close $f0 
        close $f1
        close $f2
        exec nam out.nam
 # Plot Recorded Statistics

        exec xgraph out02.tr -geometry -x TIME -y thr -t Throughput 800x400 &
        exec xgraph lost02.tr  -geometry -x TIME -y loss -t Packet_loss 800x400 &
        exec xgraph delay02.tr  -geometry -x TIME -y delay -t End-to-End-Delay 800x400 &

$ns_ flush-trace
       
}
 
$ns_ at $val(stop) "stop"
$ns_ at  $val(stop).0002 "puts \"NS EXITING...\" ; $ns_ halt"
puts $tracefd "M 0.0 nn $val(nn) x $val(x) y $val(y) rp "
puts $tracefd "M 0.0 prop $val(prop) ant $val(ant)"

puts "Starting Simulation..."
$ns_ run
