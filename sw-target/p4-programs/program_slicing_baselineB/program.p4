#include <core.p4>
#include <v1model.p4>

#include "headers.p4"

#include "ports.p4"

// Exclusive control block for customer B
// Customer B only forwards packets to different ports
control CustomerB(
    inout headers hdr,
    inout metadata data,
    inout standard_metadata_t standard_metadata) {


    apply {
        standard_metadata.egress_port = FORWARD_B;
    }
}

control ingress(
    inout headers hdr,
    inout metadata data,
    inout standard_metadata_t standard_metadata) {

    CustomerB() customerB;

    apply {

        // Shared port 63 uses VLAN
        if (standard_metadata.ingress_port == SHARED_PORT && hdr.vlan_tag.isValid()) {
            // Apply control block for customerB
            customerB.apply(hdr, data, standard_metadata);
        }
        // Untagged ports
        else if (standard_metadata.ingress_port == PORT_B) {
            // Apply control block for customerB
            customerB.apply(hdr, data, standard_metadata);
        }
        // For all other ports, drop packets
        else {
            mark_to_drop(standard_metadata);
        }


        // Prepare packet for egress
        if (standard_metadata.egress_port == SHARED_PORT) {
            if (! hdr.vlan_tag.isValid()) {
                hdr.vlan_tag.setValid();
                hdr.vlan_tag.vid = VLAN_CUSTOMER_B;
                hdr.vlan_tag.ether_type = hdr.ethernet.ether_type;
                hdr.ethernet.ether_type = ETHERTYPE_VLAN;
            }
        }
        else {
            if (hdr.vlan_tag.isValid()) {
                hdr.ethernet.ether_type = hdr.vlan_tag.ether_type;
                hdr.vlan_tag.setInvalid();
            }
        }

        // No need for egress processing
        // Therefore, skip egress and use empty egress controls

    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
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

#include "parsers.p4"

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
