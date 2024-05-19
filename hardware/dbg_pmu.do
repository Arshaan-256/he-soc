# TreeUpdate [SetDefaultTree]
# quietly WaveActivateNextPane
add wave -divider CLK
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_0/i_ariane/ex_stage_i/lsu_i/clk_i

add wave -divider CVA6_0_LSU
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_0/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_index
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_0/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_tag
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_0/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].tag_valid
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_0/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_i[1]
add wave -divider CVA6_1_LSU
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_1/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_index
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_1/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_tag
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_1/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].tag_valid
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_1/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_i[1]
add wave -divider CVA6_2_LSU
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_2/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_index
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_2/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_tag
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_2/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].tag_valid
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_2/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_i[1]
add wave -divider CVA6_3_LSU
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_3/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_index
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_3/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].address_tag
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_3/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_o[1].tag_valid
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_ariane_wrap_3/i_ariane/ex_stage_i/lsu_i/dcache_req_ports_i[1]

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -divider Slave_4
add wave -position insertpoint  \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/ar_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/ar_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/ar_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/aw_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/aw_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/aw_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[4]/w_valid}
add wave -divider Slave_5
add wave -position insertpoint  \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/ar_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/ar_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/ar_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/aw_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/aw_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/aw_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[5]/w_valid}
add wave -divider Slave_6
add wave -position insertpoint  \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/ar_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/ar_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/ar_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/aw_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/aw_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/aw_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[6]/w_valid}
add wave -divider Slave_7
add wave -position insertpoint  \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/ar_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/ar_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/ar_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/aw_id} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/aw_addr} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/aw_valid} \
{sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/slave[7]/w_valid}

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -divider SPU_CORE_0
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_spu_core_0_llc/e_out
add wave -divider SPU_CORE_1
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_spu_core_1_llc/e_out
add wave -divider SPU_CORE_2
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_spu_core_2_llc/e_out
add wave -divider SPU_CORE_3
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_cva6_subsystem/i_spu_core_3_llc/e_out
add wave -divider SPU_LLC_OUT
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_spu_llc_mem/e_out

# TreeUpdate [SetDefaultTree]
# quietly WaveActivateNextPane
# add wave -divider SPU_LLC_MEM
# add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/spu_llc_mem/*

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -divider RW_Requests
add wave -divider Slv_AR_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.ar.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.ar.addr
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.ar.len
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.ar.size
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.ar_valid
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.ar_ready

add wave -divider Mst_AR_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.ar.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.ar.addr
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.ar.len
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.ar.size
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.ar_valid

add wave -divider Slv_AW_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.aw.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.aw.addr
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.aw.len
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.aw.size
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_req_i.aw_valid
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.aw_ready

add wave -divider Mst_AW_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.aw.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.aw.addr
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.aw.len
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.aw.size
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_req_o.aw_valid

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -divider RW_Responses
add wave -divider Slv_AR_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.r.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.r.last
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.r_valid

add wave -divider Mst_AR_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_resp_i.r.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_resp_i.r.last
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_resp_i.r_valid

add wave -divider Slv_AW_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.b.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/slv_resp_o.b_valid

add wave -divider Mst_AW_Channel
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_resp_i.b.id
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/mst_resp_i.b_valid

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -divider PMU
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_pmu_top/event_sel_cfg
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_pmu_top/event_info_cfg
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_pmu_top/counter_d
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_pmu_top/timer_q
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_pmu_top/genblk6[12]/i_counter/*

# add wave -position insertpoint sim:/ariane_tb/dut/i_host_domain/i_axi_llc/*

# TreeUpdate [SetDefaultTree]
# quietly WaveActivateNextPane