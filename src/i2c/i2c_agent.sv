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
 
`ifndef I2C_AGENT__SV
`define I2C_AGENT__SV

typedef uvm_sequencer #(i2c_sequence_item) i2c_sequencer;

// Class: i2c_agent
class i2c_agent extends uvm_agent;

  // agent variables
  virtual i2c_if    sigs; 
  i2c_cfg           cfg;
  i2c_monitor       mon;
  i2c_slave_driver  slave_drv;
  i2c_sequencer     seqr;
  
  `uvm_component_utils_begin(i2c_agent)
     `uvm_field_object(cfg,       UVM_ALL_ON)
     `uvm_field_object(mon,       UVM_ALL_ON)
     `uvm_field_object(slave_drv, UVM_ALL_ON)
     `uvm_field_object(seqr,      UVM_ALL_ON)
  `uvm_component_utils_end

  typedef uvm_sequencer #(i2c_sequence_item)  i2c_sequencer;
  uvm_analysis_port #(i2c_sequence_item)      analysis_port;
  
  extern         function      new(string name = "i2c_agent", uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  
endclass: i2c_agent

//------------------------------------------------------------------------//
// function: new
// constructor
function i2c_agent::new(string name = "i2c_agent", uvm_component parent);
  super.new(name, parent);
  
endfunction: new

//------------------------------------------------------------------------//
// task: build_phase
// UVM build phase
function void i2c_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // verify configuration object was set, randomize configuration here and print what was randomized
  if ( cfg  == null ) begin
    cfg = i2c_cfg::type_id::create("cfg", this);
    if ( !cfg.randomize() ) `uvm_warning("AGENT", $sformatf("Couldn't randomize configuration!") )
    cfg.print();
  end
  
    
  if ( sigs == null ) `uvm_fatal("AGENT", $sformatf("%s interface not set!", this.get_full_name() ) )
    
  // put cfg object in config_db so sequences can use it
  uvm_config_db #(i2c_cfg)::set(null, {get_full_name(), ".seqr"}, "cfg", cfg);
  

  mon       = i2c_monitor::type_id::create("mon", this);
  mon.sigs  = sigs; // pass interface into the monitor
  mon.cfg   = cfg;

  if (cfg.is_active) begin
    seqr           = i2c_sequencer::type_id::create("seqr", this);
    
    if (cfg.is_master_or_slave_e == I2C_SLAVE) begin
      slave_drv      = i2c_slave_driver::type_id::create("slave_drv", this);
      slave_drv.sigs = sigs; // pass interface into the driver
      slave_drv.cfg  = cfg;
    end
    else `uvm_fatal("AGENT", $sformatf("cfg.is_master_or_slave_e = %s but feature not implemented yet", cfg.is_master_or_slave_e.name() ) )
  end  

endfunction: build_phase

//------------------------------------------------------------------//
// task: connect_phase
// UVM connect phase
function void i2c_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  this.analysis_port = mon.analysis_port; // bring the monitor analysis port up to the user
  if (cfg.is_active) begin
    if (cfg.is_master_or_slave_e == I2C_SLAVE) slave_drv.seq_item_port.connect(seqr.seq_item_export); // connect sequencer to driver
    else                                       `uvm_fatal("AGENT", $sformatf("cfg.is_master_or_slave_e = %s but feature not implemented yet", cfg.is_master_or_slave_e.name() ) )
  end

endfunction: connect_phase

`endif //I2C_AGENT__SV
