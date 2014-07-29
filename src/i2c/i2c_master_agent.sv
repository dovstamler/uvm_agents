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
 
`ifndef I2C_MASTER_AGENT__SV
`define I2C_MASTER_AGENT__SV

typedef uvm_sequencer #(i2c_sequence_item) i2c_master_sequencer;

// Class: i2c_master_agent
// Contains standard UVM agent objects including a configuration object, 
// sequencer, driver and monitor. 
class i2c_master_agent extends uvm_agent;

  // agent variables
  virtual i2c_if        sigs; 
  i2c_master_cfg        cfg;
  i2c_monitor           mon;
  i2c_master_driver     drv;
  i2c_master_sequencer  seqr;
  
  `uvm_component_utils_begin(i2c_master_agent)
     `uvm_field_object(cfg,  UVM_ALL_ON)
     `uvm_field_object(mon,  UVM_ALL_ON)
     `uvm_field_object(drv,  UVM_ALL_ON)
     `uvm_field_object(seqr, UVM_ALL_ON)
  `uvm_component_utils_end

  typedef uvm_sequencer #(i2c_sequence_item)  i2c_master_sequencer;
  uvm_analysis_port #(i2c_sequence_item)      analysis_port;
  
  extern         function      new(string name = "i2c_master_agent", uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  
endclass: i2c_master_agent

//------------------------------------------------------------------------//
// function: new
// constructor
function i2c_master_agent::new(string name = "i2c_master_agent", uvm_component parent);
  super.new(name, parent);
  
endfunction: new

//------------------------------------------------------------------------//
// task: build_phase
// build phase is called by UVM flow. 
function void i2c_master_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // verify configuration object was set, randomize configuration here and print what was randomized
  if ( cfg  == null ) begin
    cfg = i2c_master_cfg::type_id::create("cfg", this);
    if ( !cfg.randomize() ) `uvm_warning(get_type_name(), $sformatf("Couldn't randomize configuration!") )
    cfg.print();
  end
  
    
  if ( sigs == null ) `uvm_fatal(get_type_name(), $sformatf("%s interface not set!", this.get_full_name() ) )
    
  // put cfg object in config_db so sequences can use it
  uvm_config_db #(i2c_master_cfg)::set(null, {get_full_name(), ".seqr"}, "cfg", cfg);
  

  mon       = i2c_monitor::type_id::create("mon", this);
  mon.sigs  = sigs; // pass interface into the monitor
  mon.cfg   = cfg;

  if (cfg.is_active) begin
    seqr     = i2c_master_sequencer::type_id::create("seqr", this);
    drv      = i2c_master_driver::type_id::create("drv", this);
    drv.sigs = sigs; // pass interface into the driver
    drv.cfg  = cfg;
  end  

endfunction: build_phase

//------------------------------------------------------------------//
// task: connect_phase
// connect phase is called by UVM flow. Connects monitor to agents analysis 
// port so monitored transactions can be connected to a scoreboard. 
function void i2c_master_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  this.analysis_port = mon.analysis_port; // bring the monitor analysis port up to the user
  if (cfg.is_active) drv.seq_item_port.connect(seqr.seq_item_export);// connect sequencer to driver

endfunction: connect_phase

`endif //I2C_MASTER_AGENT__SV
