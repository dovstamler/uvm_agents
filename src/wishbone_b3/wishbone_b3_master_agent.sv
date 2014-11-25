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

`ifndef WISHBONE_B3_MASTER_AGENT__SV
`define WISHBONE_B3_MASTER_AGENT__SV

// Class: wishbone_b3_master_agent
// Contains standard UVM agent objects including a configuration object, 
// sequencer, driver and monitor. 
class wishbone_b3_master_agent #(ADR_W = 32, DAT_W = 64, TAG_W = 1) extends uvm_agent;
  
  typedef wishbone_b3_monitor       #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) td_wishbone_b3_monitor;
  typedef wishbone_b3_master_driver #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) td_wishbone_b3_master_driver;
  typedef wishbone_b3_sequence_item #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) td_wishbone_b3_sequence_item;
  typedef uvm_sequencer             #(td_wishbone_b3_sequence_item)                td_wishbone_b3_master_sequencer;
  
  // agent variables
  virtual wishbone_b3_if #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W))  sigs;
  wishbone_b3_master_cfg                                                 cfg;
  td_wishbone_b3_monitor                                                 mon;
  td_wishbone_b3_master_driver                                           drv;
  td_wishbone_b3_master_sequencer                                        seqr;
  

`uvm_component_param_utils_begin(wishbone_b3_master_agent #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)))
      `uvm_field_object(cfg,  UVM_ALL_ON)
      `uvm_field_object(mon,  UVM_ALL_ON)
      `uvm_field_object(drv,  UVM_ALL_ON)
      `uvm_field_object(seqr, UVM_ALL_ON)
`uvm_component_utils_end

  
  uvm_analysis_port #(td_wishbone_b3_sequence_item) analysis_port;
  
  extern         function      new(string name = "wishbone_b3_master_agent", uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  
endclass: wishbone_b3_master_agent

//------------------------------------------------------------------------//
// function: new
// constructor
function wishbone_b3_master_agent::new(string name = "wishbone_b3_master_agent", uvm_component parent);
  super.new(name, parent);
  
endfunction: new

//------------------------------------------------------------------------//
// task: build_phase
// build phase is called by UVM flow.
function void wishbone_b3_master_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // verify configuration object was set, randomize configuration here and print what was randomized
  if ( cfg  == null ) begin
    cfg = wishbone_b3_master_cfg::type_id::create("cfg", this);
    if ( !cfg.randomize() ) `uvm_warning(get_type_name(), $sformatf("Couldn't randomize configuration!") )
    cfg.print();
  end
    
  if ( sigs == null ) `uvm_fatal(get_type_name(), $sformatf("%s interface not set!", this.get_full_name() ) )
    
  // put cfg object in config_db so sequences can use it
  uvm_config_db #(wishbone_b3_master_cfg)::set(null, {get_full_name(), ".seqr"}, "cfg", cfg);
  

  mon       = td_wishbone_b3_monitor::type_id::create("mon", this);
  mon.sigs  = sigs; // pass interface into the monitor

  if (cfg.is_active)
    begin
      seqr     = td_wishbone_b3_master_sequencer::type_id::create("seqr", this);
      drv      = td_wishbone_b3_master_driver::type_id::create("drv", this);
      drv.sigs = sigs; // pass interface into the driver
    end  

endfunction: build_phase

//------------------------------------------------------------------//
// task: connect_phase
// connect phase is called by UVM flow. Connects monitor to agents analysis 
// port so monitored transactions can be connected to a scoreboard. 
function void wishbone_b3_master_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  this.analysis_port = mon.analysis_port; // bring the monitor analysis port up to the user
  if (cfg.is_active) drv.seq_item_port.connect(seqr.seq_item_export); // connect sequencer to driver

endfunction: connect_phase

`endif //WISHBONE_B3_MASTER_AGENT__SV
