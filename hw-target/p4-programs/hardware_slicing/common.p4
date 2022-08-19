parser EmptyIngressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out unused_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        transition accept;
    }
}

control EmptyIngress(
        inout empty_header_t hdr,
        inout unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply {}
}

control EmptyIngressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in unused_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {}
}

parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out unused_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout unused_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    apply {}
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in unused_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {

    apply {}
}
