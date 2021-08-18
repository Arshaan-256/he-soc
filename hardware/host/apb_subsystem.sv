// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 19.03.2017
// Description: Test-harness for Ariane
//              Instantiates an AXI-Bus and memories

module apb_subsystem
  import apb_soc_pkg::*;
#( 
    parameter int unsigned AXI_USER_WIDTH = 1,
    parameter int unsigned AXI_ADDR_WIDTH = 64,
    parameter int unsigned AXI_DATA_WIDTH = 64,
    parameter int unsigned L2_ADDR_WIDTH  = 32, // L2 address space
    parameter int unsigned N_SPI          = 11,
    parameter int unsigned N_UART         = 7,
    parameter int unsigned N_SDIO         = 2,
    parameter int unsigned N_CAM          = 2,
    parameter int unsigned CAM_DATA_WIDTH = 8,
    parameter int unsigned N_I2C          = 6,
    parameter int unsigned N_HYPER        = 1,
    parameter int unsigned NUM_GPIO       = 64 
) (
    input logic                                 clk_i,
    input logic                                 rst_ni,
    input logic                                 rtc_i,
    input logic                                 rst_dm_i,
    output logic                                rstn_soc_sync_o,
    output logic                                rstn_global_sync_o,
    output logic                                clk_soc_o,
    AXI_BUS.Slave                               axi_apb_slave,
    REG_BUS.out                                 hyaxicfg_reg_master,
    XBAR_TCDM_BUS.Master                        udma_tcdm_channels[1:0],

    output logic [32*4-1:0]                     events_o,

    // SPIM
    output logic [N_SPI-1:0]                    spi_clk,
    output logic [N_SPI-1:0] [3:0]              spi_csn,
    output logic [N_SPI-1:0] [3:0]              spi_oen,
    output logic [N_SPI-1:0] [3:0]              spi_sdo,
    input logic [N_SPI-1:0] [3:0]               spi_sdi,
    
    // I2C
    input logic [N_I2C-1:0]                     i2c_scl_i,
    output logic [N_I2C-1:0]                    i2c_scl_o,
    output logic [N_I2C-1:0]                    i2c_scl_oe,
    input logic [N_I2C-1:0]                     i2c_sda_i,
    output logic [N_I2C-1:0]                    i2c_sda_o,
    output logic [N_I2C-1:0]                    i2c_sda_oe,
    
    // CAM
    input logic [N_CAM-1:0]                     cam_clk_i,
    input logic [N_CAM-1:0][CAM_DATA_WIDTH-1:0] cam_data_i,
    input logic [N_CAM-1:0]                     cam_hsync_i,
    input logic [N_CAM-1:0]                     cam_vsync_i,
    
    // UART
    input logic [N_UART-1:0]                    uart_rx_i,
    output logic [N_UART-1:0]                   uart_tx_o,
    
    // SDIO
    output logic [N_SDIO-1:0]                   sdio_clk_o,
    output logic [N_SDIO-1:0]                   sdio_cmd_o,
    input logic [N_SDIO-1:0]                    sdio_cmd_i,
    output logic [N_SDIO-1:0]                   sdio_cmd_oen_o,
    output logic [N_SDIO-1:0][3:0]              sdio_data_o,
    input logic [N_SDIO-1:0][3:0]               sdio_data_i,
    output logic [N_SDIO-1:0][3:0]              sdio_data_oen_o,

    // HYPERBUS
    output logic [1:0]                          hyper_cs_no,
    output logic                                hyper_ck_o,
    output logic                                hyper_ck_no,
    output logic [1:0]                          hyper_rwds_o,
    input logic                                 hyper_rwds_i,
    output logic [1:0]                          hyper_rwds_oe_o,
    input logic [15:0]                          hyper_dq_i,
    output logic [15:0]                         hyper_dq_o,
    output logic [1:0]                          hyper_dq_oe_o,
    output logic                                hyper_reset_no,

    // GPIOs
    input logic [NUM_GPIO-1:0]                  gpio_in,
    output logic [NUM_GPIO-1:0]                 gpio_out,
    output logic [NUM_GPIO-1:0]                 gpio_dir,

    // ADV TIMERS
    output logic [3:0]                          pwm0_o,
    output logic [3:0]                          pwm1_o
);

   logic                                s_clk_per;
   logic                                s_rstn_soc_sync;
   assign rstn_soc_sync_o = s_rstn_soc_sync;
   
   APB_BUS  #(
               .APB_ADDR_WIDTH(32),
               .APB_DATA_WIDTH(32)
   ) apb_peripheral_master_bus();

   APB_BUS  #(
               .APB_ADDR_WIDTH(32),
               .APB_DATA_WIDTH(32)
   ) apb_udma_master_bus();

   APB_BUS  #(
               .APB_ADDR_WIDTH(32),
               .APB_DATA_WIDTH(32)
   ) apb_gpio_master_bus();
  
   APB_BUS  #(
               .APB_ADDR_WIDTH(32),
               .APB_DATA_WIDTH(32)
   ) apb_fll_master_bus();

   APB_BUS  #(
               .APB_ADDR_WIDTH(32),
               .APB_DATA_WIDTH(32)
   ) apb_hyaxicfg_master_bus();

   APB_BUS  #(
               .APB_ADDR_WIDTH(32),
               .APB_DATA_WIDTH(32)
   ) apb_advtimer_master_bus();
   
   FLL_BUS  #(
               .FLL_ADDR_WIDTH( 2),
               .FLL_DATA_WIDTH(32)
   ) soc_fll_bus();
   
   FLL_BUS  #(
               .FLL_ADDR_WIDTH( 2),
               .FLL_DATA_WIDTH(32)
   ) per_fll_bus();
   
   FLL_BUS  #(
               .FLL_ADDR_WIDTH( 2),
               .FLL_DATA_WIDTH(32)
   ) cluster_fll_bus();
  
   axi2apb_wrap #(
         .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH           ),
         .AXI_DATA_WIDTH ( AXI_DATA_WIDTH           ),
         .AXI_ID_WIDTH   ( ariane_soc::IdWidthSlave ),
         .AXI_USER_WIDTH ( AXI_USER_WIDTH           ),
         .APB_ADDR_WIDTH ( 32                       ),
         .APB_DATA_WIDTH ( 32                       )
         )(
           .clk_i      ( clk_soc_o                  ),
           .rst_ni     ( s_rstn_soc_sync            ),
           .test_en_i  ( 1'b0                       ),
           
           .axi_slave  ( axi_apb_slave              ),
           .apb_master ( apb_peripheral_master_bus  )
         );

   periph_bus_wrap #(
                     )(
    .clk_i(clk_soc_o),
    .rst_ni(s_rstn_soc_sync),
    .apb_slave(apb_peripheral_master_bus),
    .udma_master(apb_udma_master_bus),
    .gpio_master(apb_gpio_master_bus),
    .fll_master(apb_fll_master_bus),
    .hyaxicfg_master(apb_hyaxicfg_master_bus),
    .advtimer_master(apb_advtimer_master_bus)
    );
   

   logic [31:0]                        apb_udma_address;     
   assign apb_udma_address = apb_udma_master_bus.paddr  - apb_soc_pkg::UDMABase + 32'h1A10_0000 ;
                            
   udma_subsystem
     #(
        .L2_ADDR_WIDTH  ( L2_ADDR_WIDTH ), 
        .APB_ADDR_WIDTH ( 32            )  
     ) 
     (

         .events_o        ( events_o                      ),
         
         .event_valid_i   ( '0                            ),
         .event_data_i    ( '0                            ),
         .event_ready_o   (                               ),

         .dft_test_mode_i ( 1'b0                          ),
         .dft_cg_enable_i ( 1'b0                          ),

         .sys_clk_i       ( clk_soc_o                     ),
         .sys_resetn_i    ( s_rstn_soc_sync               ),
                                                          
         .periph_clk_i    ( s_clk_per                     ), 

         .L2_ro_wen_o     ( udma_tcdm_channels[0].wen     ),
         .L2_ro_req_o     ( udma_tcdm_channels[0].req     ),
         .L2_ro_gnt_i     ( udma_tcdm_channels[0].gnt     ),
         .L2_ro_addr_o    ( udma_tcdm_channels[0].add     ),
         .L2_ro_be_o      ( udma_tcdm_channels[0].be      ),
         .L2_ro_wdata_o   ( udma_tcdm_channels[0].wdata   ),
         .L2_ro_rvalid_i  ( udma_tcdm_channels[0].r_valid ),
         .L2_ro_rdata_i   ( udma_tcdm_channels[0].r_rdata ),

         .L2_wo_wen_o     ( udma_tcdm_channels[1].wen      ),
         .L2_wo_req_o     ( udma_tcdm_channels[1].req      ),
         .L2_wo_gnt_i     ( udma_tcdm_channels[1].gnt      ),
         .L2_wo_addr_o    ( udma_tcdm_channels[1].add      ),
         .L2_wo_wdata_o   ( udma_tcdm_channels[1].wdata    ),
         .L2_wo_be_o      ( udma_tcdm_channels[1].be       ),
         .L2_wo_rvalid_i  ( udma_tcdm_channels[1].r_valid  ),
         .L2_wo_rdata_i   ( udma_tcdm_channels[1].r_rdata  ),

         .udma_apb_paddr  ( apb_udma_address               ),
         .udma_apb_pwdata ( apb_udma_master_bus.pwdata      ),
         .udma_apb_pwrite ( apb_udma_master_bus.pwrite      ),
         .udma_apb_psel   ( apb_udma_master_bus.psel        ),
         .udma_apb_penable( apb_udma_master_bus.penable     ),
         .udma_apb_prdata ( apb_udma_master_bus.prdata      ),
         .udma_apb_pready ( apb_udma_master_bus.pready      ),
         .udma_apb_pslverr( apb_udma_master_bus.pslverr     ),
        
         .spi_clk         ( spi_clk_o                      ),
         .spi_csn         ( spi_csn_o                      ),
         .spi_oen         ( spi_oen_o                      ),
         .spi_sdo         ( spi_sdo_o                      ),
         .spi_sdi         ( spi_sdi_i                      ),
                                                      
         .sdio_clk_o      ( sdclk_o                        ),
         .sdio_cmd_o      ( sdcmd_o                        ),
         .sdio_cmd_i      ( sdcmd_i                        ),
         .sdio_cmd_oen_o  ( sdcmd_oen_o                    ),
         .sdio_data_o     ( sddata_o                       ),
         .sdio_data_i     ( sddata_i                       ),
         .sdio_data_oen_o ( sddata_oen_o                   ),
                                                      
         .cam_clk_i       ( cam_clk_i                      ),
         .cam_data_i      ( cam_data_i                     ),
         .cam_hsync_i     ( cam_hsync_i                    ),
         .cam_vsync_i     ( cam_vsync_i                    ),
                                                      
         .uart_rx_i       ( uart_rx                        ),
         .uart_tx_o       ( uart_tx                        ),
                                                      
         .i2c_scl_i       ( i2c_scl_i                      ),
         .i2c_scl_o       ( i2c_scl_o                      ),
         .i2c_scl_oe      ( i2c_scl_oe_o                   ),
         .i2c_sda_i       ( i2c_sda_i                      ),
         .i2c_sda_o       ( i2c_sda_o                      ),
         .i2c_sda_oe      ( i2c_sda_oe_o                   ),
                                                      
         .hyper_cs_no     ( hyper_cs_no                    ),
         .hyper_ck_o      ( hyper_ck_o                     ),
         .hyper_ck_no     ( hyper_ck_no                    ),
         .hyper_rwds_o    ( hyper_rwds_o                   ),
         .hyper_rwds_i    ( hyper_rwds_i                   ),
         .hyper_rwds_oe_o ( hyper_rwds_oe_o                ),
         .hyper_dq_i      ( hyper_dq_i                     ),
         .hyper_dq_o      ( hyper_dq_o                     ),
         .hyper_dq_oe_o   ( hyper_dq_oe_o                  ),
         .hyper_reset_no  ( hyper_reset_no                 )

      );
   
    logic [31:0] s_gpio_sync; 
    apb_gpio #(
        .APB_ADDR_WIDTH (32),
        .PAD_NUM        (NUM_GPIO),
        .NBIT_PADCFG    (4) // we actually use padrick for pads' configuration
    ) i_apb_gpio (
        .HCLK            ( clk_soc_o                   ), 
        .HRESETn         ( s_rstn_soc_sync             ),
                                                       
        .dft_cg_enable_i ( 1'b0                        ),

        .PADDR           ( apb_gpio_master_bus.paddr   ),
        .PWDATA          ( apb_gpio_master_bus.pwdata  ),
        .PWRITE          ( apb_gpio_master_bus.pwrite  ),
        .PSEL            ( apb_gpio_master_bus.psel    ),
        .PENABLE         ( apb_gpio_master_bus.penable ),
        .PRDATA          ( apb_gpio_master_bus.prdata  ),
        .PREADY          ( apb_gpio_master_bus.pready  ),
        .PSLVERR         ( apb_gpio_master_bus.pslverr ),

        .gpio_in_sync    ( s_gpio_sync                 ),

        .gpio_in         ( gpio_in            ),
        .gpio_out        ( gpio_out           ),
        .gpio_dir        ( gpio_dir           ),
        .gpio_padcfg     (                    ),
        .interrupt       (                    )
    );

    apb_fll_if_wrap #(
        .APB_ADDR_WIDTH (32)
    ) i_apb_fll (
       .clk_i              ( clk_soc_o          ),
       .rst_ni             ( s_rstn_soc_sync    ),
       .apb_fll_slave      ( apb_fll_master_bus ),
       .soc_fll_master     ( soc_fll_bus        ),
       .per_fll_master     ( per_fll_bus        ),
       .cluster_fll_master ( cluster_fll_bus    )
    );

    alsaqr_clk_rst_gen i_alsaqr_clk_rst_gen   
      (
        .ref_clk_i          ( rtc_i              ),
        .rstn_glob_i        ( rst_ni             ),
        .rst_dm_i           ( rst_dm_i           ),
        .test_mode_i        ( 1'b0               ),
        .sel_fll_clk_i      ( 1'b0               ), 
        .shift_enable_i     ( 1'b0               ),               
        .soc_fll_slave      ( soc_fll_bus        ),
        .per_fll_slave      ( per_fll_bus        ),
        .cluster_fll_slave  ( cluster_fll_bus    ),
        .rstn_soc_sync_o    ( s_rstn_soc_sync    ),
        .rstn_global_sync_o ( rstn_global_sync_o ), 
        .rstn_cluster_sync_o(                    ),
        .clk_soc_o          ( clk_soc_o          ),
        .clk_per_o          ( s_clk_per          ),
        .clk_cluster_o      (                    )                 
       );

   
    apb_to_reg i_apb_to_hyaxicfg
      (
       .clk_i     ( clk_soc_o       ),
       .rst_ni    ( s_rstn_soc_sync ),
 
       .penable_i ( apb_hyaxicfg_master_bus.penable ),
       .pwrite_i  ( apb_hyaxicfg_master_bus.pwrite  ),
       .paddr_i   ( apb_hyaxicfg_master_bus.paddr   ),
       .psel_i    ( apb_hyaxicfg_master_bus.psel    ),
       .pwdata_i  ( apb_hyaxicfg_master_bus.pwdata  ),
       .prdata_o  ( apb_hyaxicfg_master_bus.prdata  ),
       .pready_o  ( apb_hyaxicfg_master_bus.pready  ),
       .pslverr_o ( apb_hyaxicfg_master_bus.pslverr ),

       .reg_o     ( hyaxicfg_reg_master             )
      );      

    apb_adv_timer #(
        .APB_ADDR_WIDTH ( 32             ),
        .EXTSIG_NUM     ( 32             )
    ) i_apb_adv_timer0 (
        .HCLK            ( s_clk_per               ),
        .HRESETn         ( s_rstn_soc_sync         ),

        .dft_cg_enable_i ( 1'b0                    ),

        .PADDR           ( apb_advtimer_master_bus.paddr   ),
        .PWDATA          ( apb_advtimer_master_bus.pwdata  ),
        .PWRITE          ( apb_advtimer_master_bus.pwrite  ),
        .PSEL            ( apb_advtimer_master_bus.psel    ),
        .PENABLE         ( apb_advtimer_master_bus.penable ),
        .PRDATA          ( apb_advtimer_master_bus.prdata  ),
        .PREADY          ( apb_advtimer_master_bus.pready  ),
        .PSLVERR         ( apb_advtimer_master_bus.pslverr ),

        .low_speed_clk_i ( rtc_i                   ),
        .ext_sig_i       ( s_gpio_sync             ),

        .events_o        (                         ),

        .ch_0_o          ( pwm0_o                  ),
        .ch_1_o          ( pwm1_o                  ),
        .ch_2_o          (                         ),
        .ch_3_o          (                         )
    );

   
endmodule
