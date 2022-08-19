#include <core.p4>
#include <v1model.p4>

#include "headers.p4"

#include "ports.p4"

// Exclusive control block for customer A
// Customer A applies an ACL
control CustomerA(
    inout headers hdr,
    inout metadata data,
    inout standard_metadata_t standard_metadata) {

    action drop_pkt() {
        mark_to_drop(standard_metadata);
    }

    action forward_pkt_default() {
        standard_metadata.egress_port = FORWARD_A;
    }

    action forward_pkt_custom(bit<9> port) {
        standard_metadata.egress_port = port;
    }

    action modify_and_forward_pkt(bit<9> l1_port, l4_port_t l4_port) {
        standard_metadata.egress_port = l1_port;
        hdr.l4proto.dst_port = l4_port;
    }

    table l4_acl {
        actions = {
            drop_pkt;
            forward_pkt_default;
            forward_pkt_custom;
            modify_and_forward_pkt;
        }
        key = {
            hdr.ipv4.dst_addr: exact;
            hdr.ipv4.protocol: exact;
            hdr.l4proto.dst_port: exact;
        }
        size = 15000; //ignored by t4p4s
        const default_action = drop_pkt;
	const entries = {
		#include "table_entries.p4"
	}
    }

    apply {
        l4_acl.apply();
    }
}

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

    CustomerA() customerA;
    CustomerB() customerB;
    apply {
        // Shared port 63 uses VLAN
        if (standard_metadata.ingress_port == SHARED_PORT && hdr.vlan_tag.isValid()) {
            // Check for VLAN ID of customer or drop packet
            if (hdr.vlan_tag.vid == VLAN_CUSTOMER_A) {
                // Apply control block for customerA
                customerA.apply(hdr, data, standard_metadata);
            }
            else if (hdr.vlan_tag.vid == VLAN_CUSTOMER_B) {
                // Apply control block for customerB
                customerB.apply(hdr, data, standard_metadata);
            }
            else {
                mark_to_drop(standard_metadata);
            }
        }
        // Exclusive ports of customer A
        else if (standard_metadata.ingress_port == PORT_A) {
            // Apply control block for customerA
            hdr.vlan_tag.vid = VLAN_CUSTOMER_A;
            customerA.apply(hdr, data, standard_metadata);
        }
        // Exclusive ports of customer B
         else if (standard_metadata.ingress_port == PORT_B) {
        //     // Apply control block for customerB
             hdr.vlan_tag.vid = VLAN_CUSTOMER_B;
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
