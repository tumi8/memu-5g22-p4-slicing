typedef bit<12> vlan_id_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<16> l4_port_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const bit<8> L4_PROTOCOL_TCP = 8w0x06;
const bit<8> L4_PROTOCOL_UDP = 8w0x11;

const vlan_id_t VLAN_CUSTOMER_A = 12w100;
const vlan_id_t VLAN_CUSTOMER_B = 12w200;
const vlan_id_t VLAN_CUSTOMER_C = 12w300;
const vlan_id_t VLAN_CUSTOMER_D = 12w400;
const vlan_id_t VLAN_CUSTOMER_E = 12w500;
const vlan_id_t VLAN_CUSTOMER_F = 12w600;
const vlan_id_t VLAN_CUSTOMER_G = 12w700;
const vlan_id_t VLAN_CUSTOMER_H = 12w800;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    ether_type_t ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header l4proto_h {
    l4_port_t src_port;
    l4_port_t dst_port;
}

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    l4proto_h l4proto;
}

struct unused_metadata_t {}
