parser ParserImpl(
        packet_in packet,
        out headers hdr,
        inout metadata meta,
        inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : accept;
            ETHERTYPE_IPV6 : accept;
            default : reject;
        }
    }

    state parse_vlan {
        packet.extract(hdr.vlan_tag);
        transition select (hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4 : accept;
            ETHERTYPE_IPV6 : accept;
            default : reject;
        }
    }
}

control DeparserImpl(
        packet_out packet,
        in headers hdr) {

    apply {
        packet.emit(hdr.ethernet);
        if (hdr.vlan_tag.isValid()) {
		packet.emit(hdr.vlan_tag);
	}
    }
}
