set val(chan)       	Channel/WirelessChannel
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
set val(nn)             25
set val(stop)         	10.0 

Mac/802_11 set cdma_code_bw_start_   		0      ;# cdma code for bw request (start)
Mac/802_11 set cdma_code_bw_stop_   		63      ;# cdma code for bw request (stop)
Mac/802_11 set cdma_code_init_start_   		64      ;# cdma code for initial request (start)
Mac/802_11 set cdma_code_init_stop_   		127      ;# cdma code for initial request (stop)
Mac/802_11 set cdma_code_cqich_start_   	128     ;# cdma code for cqich request (start)
Mac/802_11 set cdma_code_cqich_stop_   		195      ;# cdma code for cqich request (stop)
Mac/802_11 set cdma_code_handover_start_	196     ;# cdma code for handover request (start)
Mac/802_11 set cdma_code_handover_stop_ 	255      ;# cdma code for handover request (stop)   

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
$node_($i) set X_  [expr rand() * 1500]
$node_($i) set Y_ [expr rand() * 1000]	
$node_($i) set Z_ 0.000000000000;		
}

for {set i 0} {$i < $val(nn) } {incr i} {
set xx  [expr rand() * 1500]
set yy [expr rand() * 1000]	
$ns_ at 0.1 "$node_($i) setdest $xx 4yy 5"			
}

 puts "Loading connection pattern..."


puts "Loading scenario file..."
for {set i 0} {$i < $val(nn) } {incr i} {

    $ns_ initial_node_pos $node_($i) 55
}

for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at $val(stop).0 "$node_($i) reset";
}
set udp_(0) [new Agent/UDP]
$ns_ attach-agent $node_(4) $udp_(0)
set sink [new Agent/LossMonitor]
$ns_ attach-agent $node_(20) $sink
set cbr1_(0) [new Application/Traffic/CBR]
$cbr1_(0) set packetSize_ 1000
$cbr1_(0) set interval_ 0.1
$cbr1_(0) set maxpkts_ 10000
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

source link.tcl

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
