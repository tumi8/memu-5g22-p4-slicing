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
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_vlan {
        packet.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            L4_PROTOCOL_TCP : parse_l4proto;
            L4_PROTOCOL_UDP : parse_l4proto;
            default : reject;
        }
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select (hdr.ipv6.next_hdr) {
            L4_PROTOCOL_TCP : parse_l4proto;
            L4_PROTOCOL_UDP : parse_l4proto;
            default : reject;
        }
    }

    state parse_l4proto {
        packet.extract(hdr.l4proto);
        transition accept;
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
	if (hdr.ipv4.isValid()) {
	        packet.emit(hdr.ipv4);
	}
	if (hdr.ipv6.isValid()) {
        	packet.emit(hdr.ipv6);
	}
        packet.emit(hdr.l4proto);
    }
}
