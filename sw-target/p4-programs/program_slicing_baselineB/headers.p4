typedef bit<12> vlan_id_t;
typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;

const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;

const vlan_id_t VLAN_CUSTOMER_B = 12w200;

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

struct headers {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
}

struct metadata {}
