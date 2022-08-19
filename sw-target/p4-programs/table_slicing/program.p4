#include <core.p4>
#include <v1model.p4>

#include "headers.p4"
#include "ports.p4"

control ingress(
    inout headers hdr,
    inout metadata data,
    inout standard_metadata_t standard_metadata) {


    action drop_pkt() {
        // Drop packet
        mark_to_drop(standard_metadata);
    }

    action forward_pkt(bit<9> port) {
        standard_metadata.egress_port = port;
    }

    action change_ipv4_src_addr(bit<9> port, ipv4_addr_t new_ip) {
        standard_metadata.egress_port = port;
        hdr.ipv4.src_addr = new_ip;
    }

    action change_ipv4_dst_addr(bit<9> port, ipv4_addr_t new_ip) {
        standard_metadata.egress_port = port;
        hdr.ipv4.dst_addr = new_ip;
    }

    action change_ipv6_src_addr(bit<9> port, ipv6_addr_t new_ip) {
        standard_metadata.egress_port = port;
        hdr.ipv6.dst_addr = new_ip;
    }

    action change_ipv6_dst_addr(bit<9> port, ipv6_addr_t new_ip) {
        standard_metadata.egress_port = port;
        hdr.ipv6.dst_addr = new_ip;
    }

    action change_l4_src_port(bit<9> port, l4_port_t new_port) {
        standard_metadata.egress_port = port;
        hdr.l4proto.src_port = new_port;
    }

    action change_l4_dst_port(bit<9> port, l4_port_t new_port) {
        standard_metadata.egress_port = port;
        hdr.l4proto.dst_port = new_port;
    }

    // Customer A tables for IPv4 and IPv6
    table customerA_ipv4 {
        actions = {
            drop_pkt;
            forward_pkt;
            change_ipv4_src_addr;
            change_ipv4_dst_addr;
            change_l4_src_port;
            change_l4_dst_port;

        }
        key = {
            hdr.ipv4.src_addr: exact;
            hdr.ipv4.dst_addr: exact;
            hdr.ipv4.protocol: exact;
            hdr.l4proto.src_port: exact;
            hdr.l4proto.dst_port: exact;
        }
        size = 7500;
        const default_action = drop_pkt;
        const entries = {
            #include "table_entries.p4"
        }
    }
    table customerA_ipv6 {
        actions = {
            drop_pkt;
            forward_pkt;
            change_ipv6_src_addr;
            change_ipv6_dst_addr;
            change_l4_src_port;
            change_l4_dst_port;
        }
        key = {
            hdr.ipv6.src_addr: exact;
            hdr.ipv6.dst_addr: exact;
            hdr.ipv6.next_hdr: exact;
            hdr.l4proto.src_port: exact;
            hdr.l4proto.dst_port: exact;
        }
        size = 7500; //table unused
        const default_action = drop_pkt;
    }

    // Customer B tables for IPv4 and IPv6
    table customerB_ipv4 {
        actions = {
            drop_pkt;
            forward_pkt;
            change_ipv4_src_addr;
            change_ipv4_dst_addr;
            change_l4_src_port;
            change_l4_dst_port;
        }
        key = {
            hdr.ipv4.src_addr: exact;
            hdr.ipv4.dst_addr: exact;
            hdr.ipv4.protocol: exact;
            hdr.l4proto.src_port: exact;
            hdr.l4proto.dst_port: exact;
        }
        size = 7500;
        const default_action = drop_pkt;
        const entries = {
            #include "table_entries.p4"
        }
    }
    table customerB_ipv6 {
        actions = {
            drop_pkt;
            forward_pkt;
            change_ipv6_src_addr;
            change_ipv6_dst_addr;
            change_l4_src_port;
            change_l4_dst_port;
        }
        key = {
            hdr.ipv6.src_addr: exact;
            hdr.ipv6.dst_addr: exact;
            hdr.ipv6.next_hdr: exact;
            hdr.l4proto.src_port: exact;
            hdr.l4proto.dst_port: exact;
        }
        size = 7500; //table unused
        const default_action = drop_pkt;
    }

    apply {

        // Shared port 63 uses VLAN
        if (standard_metadata.ingress_port == SHARED_PORT && hdr.vlan_tag.isValid()) {
            // Check for VLAN ID of customer or drop packet
            if (hdr.vlan_tag.vid == VLAN_CUSTOMER_A) {
                // Either apply IPv4 or IPv6 table or drop packet
                if (hdr.ipv4.isValid()) {
                    customerA_ipv4.apply();
                }
                else if (hdr.ipv6.isValid()) {
                    customerA_ipv6.apply();
                }
                else {
                    mark_to_drop(standard_metadata);
                }
            }
            else if (hdr.vlan_tag.vid == VLAN_CUSTOMER_B) {
                // Either apply IPv4 or IPv6 table or drop packet
                if (hdr.ipv4.isValid()) {
                    customerB_ipv4.apply();
                }
                else if (hdr.ipv6.isValid()) {
                    customerB_ipv6.apply();
                }
                else {mark_to_drop(standard_metadata);}
            }
            else {
                mark_to_drop(standard_metadata);
            }
        }
        // Exclusive ports of customer A
        else if (standard_metadata.ingress_port == PORT_A) {
            hdr.vlan_tag.vid = VLAN_CUSTOMER_A;
            // Either apply IPv4 or IPv6 table or drop packet
            if (hdr.ipv4.isValid()) {
                customerA_ipv4.apply();
            }
            else if (hdr.ipv6.isValid()) {
                customerA_ipv6.apply();
            }
            else {
                mark_to_drop(standard_metadata);
            }
        }
        // Exclusive ports of customer B
         else if (standard_metadata.ingress_port == PORT_B) {
             hdr.vlan_tag.vid = VLAN_CUSTOMER_B;
             // Either apply IPv4 or IPv6 table or drop packet
             if (hdr.ipv4.isValid()) {
                 customerB_ipv4.apply();
             }
             else if (hdr.ipv6.isValid()) {
                 customerB_ipv6.apply();
             }
             else {
                 mark_to_drop(standard_metadata);
             }
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
