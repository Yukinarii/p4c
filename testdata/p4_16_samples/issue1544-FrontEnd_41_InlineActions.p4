#include <core.p4>
#include <v1model.p4>

bit<16> sometimes_dec(in bit<16> x) {
    bool hasReturned = false;
    bit<16> retval;
    if (x > 16w5) {
        hasReturned = true;
        retval = x + 16w65535;
    }
    else {
        hasReturned = true;
        retval = x;
    }
    return retval;
}
struct metadata {
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct headers {
    ethernet_t ethernet;
}

action my_drop() {
    mark_to_drop();
}
parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<16> tmp;
    @name("set_port") action set_port_0(bit<9> output_port) {
        standard_metadata.egress_spec = output_port;
    }
    @name("mac_da") table mac_da_0 {
        key = {
            hdr.ethernet.dstAddr: exact @name("hdr.ethernet.dstAddr") ;
        }
        actions = {
            set_port_0();
            my_drop();
        }
        default_action = my_drop();
    }
    apply {
        mac_da_0.apply();
        tmp = sometimes_dec(hdr.ethernet.srcAddr[15:0]);
        hdr.ethernet.srcAddr[15:0] = tmp;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

