header_type tcp_t {
	fields {
		sport : 16;
		dport : 16;
		seqNo : 32;
		ackNo : 32;
		dataOffset : 4;
		res : 4;
		flags : 8;
		window : 16;
		checksum : 16;
		urgentPtr : 16;
	}
}

header tcp_t tcp;

parser parse_tcp {
	extract(tcp);
	return ingress;
}

header_type ipv4_t {
	fields {
		version : 4;
		ihl : 4;
		diffserv : 8;
		totalLen : 16;
		identification : 16;
		flags : 3;
		fragOffset : 13;
		ttl : 8;
		protocol : 8;
		hdrChecksum : 16;
		srcIP : 32;
		dstIP : 32;
	}
}

header ipv4_t ipv4;

parser parse_ipv4 {
	extract(ipv4);
	return select(latest.protocol) {
		6 : parse_tcp;
		default: ingress;
	}
}

header_type ethernet_t {
	fields {
		dstMac : 48;
		srcMac : 48;
		ethType : 16;
	}
}

header ethernet_t ethernet;

parser parse_ethernet {
	extract(ethernet);
	return select(latest.ethType) {
		0x0800 : parse_ipv4;
		default: ingress;
	}
}

parser start {
	return select(current(0, 64)) {
		0 : parse_out_header;
		default: parse_ethernet;
	}
}

parser parse_out_header {
	extract(out_header_10008);
	extract(out_header_10032);
	extract(out_header_20032);
	extract(out_header_20008);
	extract(final_header);
	return parse_ethernet;
}

action do_init_app_metadata(){
	modify_field(meta_app_data.drop_10008, 0);
	modify_field(meta_app_data.satisfied_10008, 0);
	modify_field(meta_app_data.drop_10032, 0);
	modify_field(meta_app_data.satisfied_10032, 0);
	modify_field(meta_app_data.drop_20032, 0);
	modify_field(meta_app_data.satisfied_20032, 0);
	modify_field(meta_app_data.drop_20008, 0);
	modify_field(meta_app_data.satisfied_20008, 0);
	modify_field(meta_app_data.clone, 0);
}

table init_app_metadata {
	actions {
		do_init_app_metadata;
	}
	size : 1;
}

header_type meta_app_data_t {
	fields {
		drop_10008: 1;
		satisfied_10008: 1;
		drop_10032: 1;
		satisfied_10032: 1;
		drop_20032: 1;
		satisfied_20032: 1;
		drop_20008: 1;
		satisfied_20008: 1;
		clone: 1;
	}
}

metadata meta_app_data_t meta_app_data;

action _nop(){
	no_op();
}

field_list report_packet_fields {
	meta_app_data;
	meta_mapinit_10008_1;
	meta_mapinit_10032_1;
	meta_mapinit_20032_1;
	meta_mapinit_20008_1;
}

action do_report_packet(){
	clone_ingress_pkt_to_egress(8001, report_packet_fields);
}

table report_packet {
	actions {
		do_report_packet;
	}
	size : 1;
}

header_type final_header_t {
	fields {
		delimiter : 32;
	}
}
header final_header_t final_header;

action do_add_final_header(){
	add_header(final_header);
	modify_field(final_header.delimiter, 0);
}

table add_final_header {
	actions {
		do_add_final_header;
	}
	size : 1;
}

// query 10008
header_type out_header_10008_t {
	fields {
		qid : 16;
		tcp_flags : 8;
		ipv4_protocol : 8;
		ipv4_dstIP : 32;
	}
}
header out_header_10008_t out_header_10008;

action drop_10008(){
	modify_field(meta_app_data.drop_10008, 1);
}

action do_mark_satisfied_10008(){
	modify_field(meta_app_data.satisfied_10008, 1);
	modify_field(meta_app_data.clone, 1);
}

action do_add_out_header_10008(){
	add_header(out_header_10008);
	modify_field(out_header_10008.qid, meta_mapinit_10008_1.qid);
	modify_field(out_header_10008.tcp_flags, meta_mapinit_10008_1.tcp_flags);
	modify_field(out_header_10008.ipv4_protocol, meta_mapinit_10008_1.ipv4_protocol);
	modify_field(out_header_10008.ipv4_dstIP, meta_mapinit_10008_1.ipv4_dstIP);
}

table add_out_header_10008 {
	actions {
		do_add_out_header_10008;
	}
	size : 1;
}

table mark_satisfied_10008 {
	actions {
		do_mark_satisfied_10008;
	}
	size : 1;
}

// MapInit of query 10008
header_type meta_mapinit_10008_1_t {
	fields {
		qid: 16;
		tcp_flags: 8;
		ipv4_protocol: 8;
		ipv4_dstIP: 32;
	}
}

metadata meta_mapinit_10008_1_t meta_mapinit_10008_1;

action do_mapinit_10008_1(){
	modify_field(meta_mapinit_10008_1.qid, 10008);
	modify_field(meta_mapinit_10008_1.tcp_flags, tcp.flags);
	modify_field(meta_mapinit_10008_1.ipv4_protocol, ipv4.protocol);
	modify_field(meta_mapinit_10008_1.ipv4_dstIP, ipv4.dstIP);
}

table mapinit_10008_1 {
	actions {
		do_mapinit_10008_1;
	}
	size : 1;
}


// Map 2 of query 10008
action do_map_10008_2(){
	bit_and(meta_mapinit_10008_1.ipv4_dstIP, meta_mapinit_10008_1.ipv4_dstIP, 0xff000000);
}

table map_10008_2 {
	actions {
		do_map_10008_2;
	}
	size : 1;
}


// Filter 3 of query 10008
table filter_10008_3 {
	reads {
		ipv4.protocol: exact;
	}
	actions {
		drop_10008;
		_nop;
	}
	size : 64;
}


// query 10032
header_type out_header_10032_t {
	fields {
		qid : 16;
		tcp_flags : 8;
		ipv4_protocol : 8;
		ipv4_dstIP : 32;
	}
}
header out_header_10032_t out_header_10032;

action drop_10032(){
	modify_field(meta_app_data.drop_10032, 1);
}

action do_mark_satisfied_10032(){
	modify_field(meta_app_data.satisfied_10032, 1);
	modify_field(meta_app_data.clone, 1);
}

action do_add_out_header_10032(){
	add_header(out_header_10032);
	modify_field(out_header_10032.qid, meta_mapinit_10032_1.qid);
	modify_field(out_header_10032.tcp_flags, meta_mapinit_10032_1.tcp_flags);
	modify_field(out_header_10032.ipv4_protocol, meta_mapinit_10032_1.ipv4_protocol);
	modify_field(out_header_10032.ipv4_dstIP, meta_mapinit_10032_1.ipv4_dstIP);
}

table add_out_header_10032 {
	actions {
		do_add_out_header_10032;
	}
	size : 1;
}

table mark_satisfied_10032 {
	actions {
		do_mark_satisfied_10032;
	}
	size : 1;
}

// MapInit of query 10032
header_type meta_mapinit_10032_1_t {
	fields {
		qid: 16;
		tcp_flags: 8;
		ipv4_protocol: 8;
		ipv4_dstIP: 32;
	}
}

metadata meta_mapinit_10032_1_t meta_mapinit_10032_1;

action do_mapinit_10032_1(){
	modify_field(meta_mapinit_10032_1.qid, 10032);
	modify_field(meta_mapinit_10032_1.tcp_flags, tcp.flags);
	modify_field(meta_mapinit_10032_1.ipv4_protocol, ipv4.protocol);
	modify_field(meta_mapinit_10032_1.ipv4_dstIP, ipv4.dstIP);
}

table mapinit_10032_1 {
	actions {
		do_mapinit_10032_1;
	}
	size : 1;
}


// Filter 2 of query 10032
table filter_10032_2 {
	reads {
		ipv4.dstIP: lpm;
	}
	actions {
		drop_10032;
		_nop;
	}
	size : 64;
}


// Map 3 of query 10032
action do_map_10032_3(){
	bit_and(meta_mapinit_10032_1.ipv4_dstIP, meta_mapinit_10032_1.ipv4_dstIP, 0xffffffff);
}

table map_10032_3 {
	actions {
		do_map_10032_3;
	}
	size : 1;
}


// Filter 4 of query 10032
table filter_10032_4 {
	reads {
		ipv4.protocol: exact;
	}
	actions {
		drop_10032;
		_nop;
	}
	size : 64;
}


// query 20032
header_type out_header_20032_t {
	fields {
		qid : 16;
		ipv4_protocol : 8;
		ipv4_srcIP : 32;
		tcp_flags : 8;
	}
}
header out_header_20032_t out_header_20032;

action drop_20032(){
	modify_field(meta_app_data.drop_20032, 1);
}

action do_mark_satisfied_20032(){
	modify_field(meta_app_data.satisfied_20032, 1);
	modify_field(meta_app_data.clone, 1);
}

action do_add_out_header_20032(){
	add_header(out_header_20032);
	modify_field(out_header_20032.qid, meta_mapinit_20032_1.qid);
	modify_field(out_header_20032.ipv4_protocol, meta_mapinit_20032_1.ipv4_protocol);
	modify_field(out_header_20032.ipv4_srcIP, meta_mapinit_20032_1.ipv4_srcIP);
	modify_field(out_header_20032.tcp_flags, meta_mapinit_20032_1.tcp_flags);
}

table add_out_header_20032 {
	actions {
		do_add_out_header_20032;
	}
	size : 1;
}

table mark_satisfied_20032 {
	actions {
		do_mark_satisfied_20032;
	}
	size : 1;
}

// MapInit of query 20032
header_type meta_mapinit_20032_1_t {
	fields {
		qid: 16;
		ipv4_protocol: 8;
		ipv4_srcIP: 32;
		tcp_flags: 8;
	}
}

metadata meta_mapinit_20032_1_t meta_mapinit_20032_1;

action do_mapinit_20032_1(){
	modify_field(meta_mapinit_20032_1.qid, 20032);
	modify_field(meta_mapinit_20032_1.ipv4_protocol, ipv4.protocol);
	modify_field(meta_mapinit_20032_1.ipv4_srcIP, ipv4.srcIP);
	modify_field(meta_mapinit_20032_1.tcp_flags, tcp.flags);
}

table mapinit_20032_1 {
	actions {
		do_mapinit_20032_1;
	}
	size : 1;
}


// Filter 2 of query 20032
table filter_20032_2 {
	reads {
		ipv4.srcIP: lpm;
	}
	actions {
		drop_20032;
		_nop;
	}
	size : 64;
}


// Map 3 of query 20032
action do_map_20032_3(){
	bit_and(meta_mapinit_20032_1.ipv4_srcIP, meta_mapinit_20032_1.ipv4_srcIP, 0xffffffff);
}

table map_20032_3 {
	actions {
		do_map_20032_3;
	}
	size : 1;
}


// Filter 4 of query 20032
table filter_20032_4 {
	reads {
		ipv4.protocol: exact;
	}
	actions {
		drop_20032;
		_nop;
	}
	size : 64;
}


// query 20008
header_type out_header_20008_t {
	fields {
		qid : 16;
		ipv4_protocol : 8;
		ipv4_srcIP : 32;
		tcp_flags : 8;
	}
}
header out_header_20008_t out_header_20008;

action drop_20008(){
	modify_field(meta_app_data.drop_20008, 1);
}

action do_mark_satisfied_20008(){
	modify_field(meta_app_data.satisfied_20008, 1);
	modify_field(meta_app_data.clone, 1);
}

action do_add_out_header_20008(){
	add_header(out_header_20008);
	modify_field(out_header_20008.qid, meta_mapinit_20008_1.qid);
	modify_field(out_header_20008.ipv4_protocol, meta_mapinit_20008_1.ipv4_protocol);
	modify_field(out_header_20008.ipv4_srcIP, meta_mapinit_20008_1.ipv4_srcIP);
	modify_field(out_header_20008.tcp_flags, meta_mapinit_20008_1.tcp_flags);
}

table add_out_header_20008 {
	actions {
		do_add_out_header_20008;
	}
	size : 1;
}

table mark_satisfied_20008 {
	actions {
		do_mark_satisfied_20008;
	}
	size : 1;
}

// MapInit of query 20008
header_type meta_mapinit_20008_1_t {
	fields {
		qid: 16;
		ipv4_protocol: 8;
		ipv4_srcIP: 32;
		tcp_flags: 8;
	}
}

metadata meta_mapinit_20008_1_t meta_mapinit_20008_1;

action do_mapinit_20008_1(){
	modify_field(meta_mapinit_20008_1.qid, 20008);
	modify_field(meta_mapinit_20008_1.ipv4_protocol, ipv4.protocol);
	modify_field(meta_mapinit_20008_1.ipv4_srcIP, ipv4.srcIP);
	modify_field(meta_mapinit_20008_1.tcp_flags, tcp.flags);
}

table mapinit_20008_1 {
	actions {
		do_mapinit_20008_1;
	}
	size : 1;
}


// Filter 2 of query 20008
table filter_20008_2 {
	reads {
		ipv4.srcIP: lpm;
	}
	actions {
		drop_20008;
		_nop;
	}
	size : 64;
}


// Map 3 of query 20008
action do_map_20008_3(){
	bit_and(meta_mapinit_20008_1.ipv4_srcIP, meta_mapinit_20008_1.ipv4_srcIP, 0xff000000);
}

table map_20008_3 {
	actions {
		do_map_20008_3;
	}
	size : 1;
}


// Filter 4 of query 20008
table filter_20008_4 {
	reads {
		ipv4.protocol: exact;
	}
	actions {
		drop_20008;
		_nop;
	}
	size : 64;
}


control ingress {
	apply(init_app_metadata);
		// query 10008
		if (meta_app_data.drop_10008 != 1) {
			apply(mapinit_10008_1);
			if (meta_app_data.drop_10008 != 1) {
				apply(map_10008_2);
				if (meta_app_data.drop_10008 != 1) {
					apply(filter_10008_3);
					if (meta_app_data.drop_10008 != 1) {
						apply(mark_satisfied_10008);
					}
				}
			}
		}
		// query 10032
		if (meta_app_data.drop_10032 != 1) {
			apply(mapinit_10032_1);
			if (meta_app_data.drop_10032 != 1) {
				apply(filter_10032_2);
				if (meta_app_data.drop_10032 != 1) {
					apply(map_10032_3);
					if (meta_app_data.drop_10032 != 1) {
						apply(filter_10032_4);
						if (meta_app_data.drop_10032 != 1) {
							apply(mark_satisfied_10032);
						}
					}
				}
			}
		}
		// query 20032
		if (meta_app_data.drop_20032 != 1) {
			apply(mapinit_20032_1);
			if (meta_app_data.drop_20032 != 1) {
				apply(filter_20032_2);
				if (meta_app_data.drop_20032 != 1) {
					apply(map_20032_3);
					if (meta_app_data.drop_20032 != 1) {
						apply(filter_20032_4);
						if (meta_app_data.drop_20032 != 1) {
							apply(mark_satisfied_20032);
						}
					}
				}
			}
		}
		// query 20008
		if (meta_app_data.drop_20008 != 1) {
			apply(mapinit_20008_1);
			if (meta_app_data.drop_20008 != 1) {
				apply(filter_20008_2);
				if (meta_app_data.drop_20008 != 1) {
					apply(map_20008_3);
					if (meta_app_data.drop_20008 != 1) {
						apply(filter_20008_4);
						if (meta_app_data.drop_20008 != 1) {
							apply(mark_satisfied_20008);
						}
					}
				}
			}
		}

	if (meta_app_data.clone == 1) {
		apply(report_packet);
	}
}

control egress {
	if (standard_metadata.instance_type == 0) {
		// original packet, apply forwarding
	}

	else if (standard_metadata.instance_type == 1) {
		if (meta_app_data.satisfied_10008 == 1) {
			apply(add_out_header_10008);
		}
		if (meta_app_data.satisfied_10032 == 1) {
			apply(add_out_header_10032);
		}
		if (meta_app_data.satisfied_20032 == 1) {
			apply(add_out_header_20032);
		}
		if (meta_app_data.satisfied_20008 == 1) {
			apply(add_out_header_20008);
		}
		apply(add_final_header);
	}
}

