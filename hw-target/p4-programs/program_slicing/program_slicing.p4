#include <core.p4>
#include <tna.p4>

#include "headers.p4"
#include "parsers.p4"

// Exclusive control block for customer A
// Customer A applies an ACL
control CustomerA (
        inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action drop_pkt() {
        // Drop packet
        ig_dprsr_md.drop_ctl = 0x1;
    }

    action forward_pkt_default() {
        ig_tm_md.ucast_egress_port = 312;
    }

    action forward_pkt_custom(PortId_t l1_port) {
        ig_tm_md.ucast_egress_port = l1_port;
    }

    action modify_and_forward_pkt(PortId_t l1_port, l4_port_t l4_port) {
        ig_tm_md.ucast_egress_port = l1_port;
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
            hdr.ipv4.dst_addr: lpm;
            hdr.ipv4.protocol: exact;
            hdr.l4proto.dst_port: exact;
        }
        size = 15000;
        const default_action = drop_pkt;
    }

    apply {
        l4_acl.apply();
    }
}

// Exclusive control block for customer B
// Customer B only forwards packets to different ports
control CustomerB (
        inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply {
        ig_tm_md.ucast_egress_port = 312;
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    CustomerA() customerA;
    CustomerB() customerB;

    apply {

        // Shared port 63 uses VLAN
        if (ig_intr_md.ingress_port == 316 && hdr.vlan_tag.isValid()) {
            // Check for VLAN ID of customer or drop packet
            if (hdr.vlan_tag.vid == VLAN_CUSTOMER_A) {
                // Apply control block for customerA
                customerA.apply(hdr, ig_intr_md, ig_dprsr_md, ig_tm_md);
            }
            else if (hdr.vlan_tag.vid == VLAN_CUSTOMER_B) {
                // Apply control block for customerB
                customerB.apply(hdr, ig_intr_md, ig_dprsr_md, ig_tm_md);
            }
            else {
                ig_dprsr_md.drop_ctl = 0x1;
            }
        }
        // Exclusive ports of customer A
        else if (ig_intr_md.ingress_port == 312) {
            // Apply control block for customerA
            hdr.vlan_tag.vid = VLAN_CUSTOMER_A;
            customerA.apply(hdr, ig_intr_md, ig_dprsr_md, ig_tm_md);
        }
        // Exclusive ports of customer B
        // else if (ig_intr_md.ingress_port == 312) {
        //     // Apply control block for customerB
        //     hdr.vlan_tag.vid = VLAN_CUSTOMER_B;
        //     customerB.apply(hdr, ig_intr_md, ig_dprsr_md, ig_tm_md);
        // }
        // For all other ports, drop packets
        else {
            ig_dprsr_md.drop_ctl = 0x1;
        }


        // Prepare packet for egress
        if (ig_tm_md.ucast_egress_port == 316) {
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
