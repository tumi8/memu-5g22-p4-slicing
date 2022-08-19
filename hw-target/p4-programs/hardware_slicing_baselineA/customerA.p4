struct customerA_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    l4proto_h l4proto;
}

parser CustomerAIngressParser(
        packet_in pkt,
        out customerA_header_t hdr,
        out unused_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            L4_PROTOCOL_TCP : parse_l4proto;
            L4_PROTOCOL_UDP : parse_l4proto;
            default : reject;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select (hdr.ipv6.next_hdr) {
            L4_PROTOCOL_TCP : parse_l4proto;
            L4_PROTOCOL_UDP : parse_l4proto;
            default : reject;
        }
    }

    state parse_l4proto {
        pkt.extract(hdr.l4proto);
        transition accept;
    }
}

control CustomerAIngress(
        inout customerA_header_t hdr,
        inout unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action drop_pkt() {
        // Drop packet
        ig_dprsr_md.drop_ctl = 0x1;
    }

    action forward_pkt_default() {
        ig_tm_md.ucast_egress_port = 132;
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

        // Shared port 63 uses VLAN
        if (ig_intr_md.ingress_port == 132 && hdr.ipv4.isValid()) {
            l4_acl.apply();
        }
        else {
            ig_dprsr_md.drop_ctl = 0x1;
        }

        // No need for egress processing
        // Therefore, skip egress and use empty egress controls
        ig_tm_md.bypass_egress = 1w1;
    }
}

control CustomerAIngressDeparser(
        packet_out pkt,
        inout customerA_header_t hdr,
        in unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.l4proto);
    }
}
