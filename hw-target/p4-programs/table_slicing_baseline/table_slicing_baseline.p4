#include <core.p4>
#include <tna.p4>

#include "headers.p4"
#include "parsers.p4"

control SwitchIngress(
        inout header_t hdr,
        inout unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action drop_pkt() {
        // Drop packet
        ig_dprsr_md.drop_ctl = 0x1;
    }

    action forward_pkt(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action change_ipv4_src_addr(PortId_t port, ipv4_addr_t new_ip) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ipv4.src_addr = new_ip;
    }

    action change_ipv4_dst_addr(PortId_t port, ipv4_addr_t new_ip) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ipv4.dst_addr = new_ip;
    }

    action change_ipv6_src_addr(PortId_t port, ipv6_addr_t new_ip) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ipv6.dst_addr = new_ip;
    }

    action change_ipv6_dst_addr(PortId_t port, ipv6_addr_t new_ip) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ipv6.dst_addr = new_ip;
    }

    action change_l4_src_port(PortId_t port, l4_port_t new_port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.l4proto.src_port = new_port;
    }

    action change_l4_dst_port(PortId_t port, l4_port_t new_port) {
        ig_tm_md.ucast_egress_port = port;
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
        size = 40000;
        const default_action = drop_pkt;
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
        size = 40000;
        const default_action = drop_pkt;
    }

    apply {

        // Shared port 63 uses VLAN
        if (ig_intr_md.ingress_port == 316 && hdr.vlan_tag.isValid()) {
            // Check for VLAN ID of customer or drop packet
            if (hdr.ipv4.isValid()) {
                customerA_ipv4.apply();
            }
            else if (hdr.ipv6.isValid()) {
                customerA_ipv6.apply();
            }
            else {
                ig_dprsr_md.drop_ctl = 0x1;
            }
        }
        // Untagged ports
        else if (ig_intr_md.ingress_port == 312) {
            // Either apply IPv4 or IPv6 table or drop packet
            if (hdr.ipv4.isValid()) {
                customerA_ipv4.apply();
            }
            else if (hdr.ipv6.isValid()) {
                customerA_ipv6.apply();
            }
            else {
                ig_dprsr_md.drop_ctl = 0x1;
            }
        }
        // For all other ports, drop packets
        else {
            ig_dprsr_md.drop_ctl = 0x1;
        }

        // Prepare packet for egress
        if (ig_tm_md.ucast_egress_port == 316) {
            if (! hdr.vlan_tag.isValid()) {
                hdr.vlan_tag.setValid();
                hdr.vlan_tag.vid = VLAN_CUSTOMER_A;
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
        ig_tm_md.bypass_egress = 1w1;
    }
}

control EmptyEgress(
        inout header_t hdr,
        inout unused_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    apply {}
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;
