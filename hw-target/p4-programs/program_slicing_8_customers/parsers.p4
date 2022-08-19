parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
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
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
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

control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.l4proto);
    }
}

parser EmptyEgressParser(
        packet_in pkt,
        out header_t hdr,
        out unused_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in unused_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {

    apply {}
}
