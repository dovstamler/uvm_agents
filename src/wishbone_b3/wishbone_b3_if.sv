//////////////////////////////////////////////////////////////////////////////
//  Copyright 2014 Dov Stamler (dov.stamler@gmail.com)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//////////////////////////////////////////////////////////////////////////////
//  Modifications:
//      2016-08-11: by Jan Pospisil (fosfor.software@seznam.cz)
//          * added timeunit/timeprecision to WB interface
//////////////////////////////////////////////////////////////////////////////

`ifndef WISHBONE_B3_IF__SV
`define WISHBONE_B3_IF__SV
// interface: wishbone_b3_if
// Interface connecting the agent to a wishbone bus.
//
// Interface Signals: 
//
// clk    - wishbone b3 block input clock. Clocking blocks are dependent on this input. This is an interface port. 
// dat_i  - data in bus, DAT_W wide.
// dat_o  - data out bus, DAT_W wide.
// rst_i  - core reset.
// tgd_i  - tag for data in, TAG_W wide. Contains information associated to dat_i (such as parity).
// tgd_o  - tag for data out, TAG_W wide. Contains information associated to dat_o.
// ack    - acknowledge, signals normal termination of the bus cycle.
// adr    - address bus, ADR_W wide. 
// cyc    - cycle, when asserted, indicates that a valid bus cycle is in progress.
// err    - error, indicates an abnormal cycle termination.
// lock   - lock, when asserted, indicates that the current bus cycle is uninterruptible.
// rty    - retry, cycle should be retried.
// sel    - select array, DAT_W/8 wide. Indicates where a dat_o/dat_i (write/read) byte is valid, each bit represents one data byte.
// stb    - strobe, indicates a valid data transfer cycle.
// tga    - tag for address, TAG_W wide. Contains information associated to the adr signal.
// tgc    - tag for cycle, TAG_W wide. Contains information associated with cycle.
// we     - write enable.
// (start code)
// 
// wishbone_b3_if #(.DAT_W(`WB_DATA_WIDTH), .ADR_W(`WB_ADDRESS_WIDTH), .TAG_W(`WB_TAG_WIDTH) ) wb_sigs( .clk(`TB.clk) );
// assign wb_sigs.rst_i = `TB.resetn;   // reset to core and VIP
// assign wb_sigs.dat_i = `TB.wb_dat_o;
// assign wb_sigs.tgd_i = `TB.tgd_o;
// assign wb_sigs.ack   = `TB.ack;
// assign wb_sigs.err   = `TB.err;
// assign wb_sigs.lock  = `TB.lock;
// assign wb_sigs.rty   = `TB.rty;
//
// assign `TB.wb_dat_i  = wb_sigs.dat_o;
// assign `TB.tgd_i     = wb_sigs.tgd_o;
// assign `TB.adr_i     = wb_sigs.adr;
// assign `TB.tga       = wb_sigs.tga;
// assign `TB.cyc       = wb_sigs.cyc;
// assign `TB.tgc       = wb_sigs.tgc;
// assign `TB.stb       = wb_sigs.stb;
// assign `TB.we        = wb_sigs.we;
// assign `TB.sel       = wb_sigs.sel;
//
// (end code)
interface wishbone_b3_if #(DAT_W  = 64, ADR_W  = 32, TAG_W  = 1) (input bit clk);
    //parameter DAT_W  = 64;       // data port width
    //parameter ADR_W  = 32;       // address port width
    //parameter TAG_W  = 1;        // default tag widths are 1 bit
    
    timeunit      1ns;
    timeprecision 1ps;

    localparam SEL_W = (DAT_W/8); // 1 select bit per data byte, divide by 8 
    
    /// common signals ///
    logic [DAT_W-1:0] dat_i;  // data in bus
    logic [DAT_W-1:0] dat_o;  // data out bus
    logic             rst_i;  // core reset
    logic [TAG_W-1:0] tgd_i;  // tag for data in. Contains information associated to dat_i (such as parity).
    logic [TAG_W-1:0] tgd_o;  // tag for data out. Contains information associated to dat_o
    
    /// signals direction is dependent on agent ///
    logic             ack;  // acknowledge, signals normal termination of the bus cycle
    logic [ADR_W-1:0] adr;  // address bus
    logic             cyc;  // cycle, when asserted, indicates that a valid bus cycle is in progress
    logic             err;  // error, indicates an abnormal cycle termination
    logic             lock; // lock, when asserted, indicates that the current bus cycle is uninterruptible
    logic             rty;  // retry, cycle should be retried
    logic [SEL_W-1:0] sel;  // select array, indicates where a dat_o/dat_i (write/read) byte is valid, each bit represents one data byte
    logic             stb;  // strobe, indicates a valid data transfer cycle
    logic [TAG_W-1:0] tga;  // tag for address, contains information associated to the adr signal
    logic [TAG_W-1:0] tgc;  // tag for cycle, contains information associated with cyc
    logic             we;   // write enable
  
    // master driver
    clocking m_drv_cb @(posedge clk);
      default input #1step output #1;
      
      //common signals
      input  dat_i; 
      output dat_o;
      input  rst_i;
      input  tgd_i;
      output tgd_o;
    
      // direction for master agent
      input  ack;  
      output adr;
      output cyc;
      input  err;
      output lock;
      input  rty;
      output sel;
      output stb;
      output tga;
      output tgc;
      output we;
        
    endclocking: m_drv_cb
    
    // slave driver
    clocking s_drv_cb @(posedge clk);
      default input #1step output #1;
      
      //common signals
      input  dat_i; 
      output dat_o;
      input  rst_i;
      input  tgd_i;
      output tgd_o;
    
      // direction for slave agent
      output ack;
      input  adr;
      input  cyc;
      output err;
      input  lock;
      output rty;
      input  sel;
      input  stb;
      input  tga;
      input  tgc;
      input  we;
        
    endclocking: s_drv_cb
    
    clocking mon_cb @(posedge clk);
      default input #1step output #1;
        
      //common signals
      input  dat_i; 
      input  dat_o;
      input  rst_i;
      input  tgd_i;
      input  tgd_o;
    
      // all monitor signals are inputs
      input  ack;  
      input  adr;
      input  cyc;
      input  err;
      input  lock;
      input  rty;
      input  sel;
      input  stb;
      input  tga;
      input  tgc;
      input  we;
 
    endclocking: mon_cb

endinterface: wishbone_b3_if

`endif //WISHBONE_B3_IF__SV
