struct customerB_header_t {
    ethernet_h ethernet;
}

parser CustomerBIngressParser(
        packet_in pkt,
        out customerB_header_t hdr,
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
            ETHERTYPE_IPV4 : accept;
            ETHERTYPE_IPV6 : accept;
            default : reject;
        }
    }
}

control CustomerBIngress(
        inout customerB_header_t hdr,
        inout unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply {

        // Shared port 63 uses VLAN
        if (ig_intr_md.ingress_port == 312) {
            ig_tm_md.ucast_egress_port = 312;
        }
        else {
            ig_dprsr_md.drop_ctl = 0x1;
        }

        // No need for egress processing
        // Therefore, skip egress and use empty egress controls
        ig_tm_md.bypass_egress = 1w1;
    }
}

control CustomerBIngressDeparser(
        packet_out pkt,
        inout customerB_header_t hdr,
        in unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.ethernet);
    }
}
