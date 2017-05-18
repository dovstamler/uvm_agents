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
//      2016-06-08: by Jan Pospisil (fosfor.software@seznam.cz)
//          * removed constructs which seems not to be supported in UVM 1.2
//////////////////////////////////////////////////////////////////////////////

`ifndef WISHBONE_B3_MONITOR__SV
`define WISHBONE_B3_MONITOR__SV

// class: wishbone_b3_monitor
// Monitors signals on a wishbone interface and outputs via an analysis
// port a <wishbone_b3_sequence_item> when a valid transaction has completed.
class wishbone_b3_monitor #(ADR_W = 32, DAT_W = 64, TAG_W = 1) extends uvm_monitor;
  `uvm_component_param_utils(wishbone_b3_monitor #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)))
  
  typedef wishbone_b3_sequence_item #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) td_wishbone_b3_sequence_item;

  virtual wishbone_b3_if            #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W)) sigs;
  uvm_analysis_port                 #(td_wishbone_b3_sequence_item)                analysis_port;
  wishbone_b3_common_methods        #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W)) common_mthds;
  
  extern         function      new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task          run_phase(uvm_phase phase);

  endclass: wishbone_b3_monitor
  
//------------------------------------------------------------------------//
// function: new
// constructor
function wishbone_b3_monitor::new(string name, uvm_component parent);
  super.new(name, parent);

endfunction: new

//------------------------------------------------------------------------//
// function: build_phase
// build phase is called by UVM flow.
function void wishbone_b3_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  this.analysis_port = new("analysis_port", this);
  common_mthds      = wishbone_b3_common_methods #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W))::type_id::create("common_mthds", this);
  common_mthds.sigs = sigs;
  
endfunction: build_phase

//------------------------------------------------------------------------//
// task: run_phase
// run phase is called by UVM flow. Monitor is active during this phase. 
task wishbone_b3_monitor::run_phase(uvm_phase phase);
  td_wishbone_b3_sequence_item s_item;
  super.run_phase(phase);

  forever begin
  
    // transaction begins when cyc_o (cycle) is asserted and the stb_o (phase) is asserted.
    wait(sigs.mon_cb.cyc === 1'b1 && sigs.mon_cb.stb === 1'b1);
    s_item = td_wishbone_b3_sequence_item::type_id::create("s_item", this);
  
    s_item.address      = sigs.mon_cb.adr;
    s_item.direction_e  = e_wishbone_b3_direction'(sigs.mon_cb.we);
    s_item.select       = sigs.mon_cb.sel;
  
    common_mthds.wait_for_response( .response(s_item.response_e) );
    if (sigs.mon_cb.we == 1'b1) s_item.data = sigs.mon_cb.dat_o;
    else                        s_item.data = sigs.mon_cb.dat_i;
    
    `uvm_info(get_type_name(),  $sformatf("%s", s_item.sprint() ), UVM_FULL )
    analysis_port.write(s_item);
    
    // The ACK is asserted for 1 clock cycle, even if the transactions are back to back then the wait 
    // statement at the beginning of the forever loop will trigger immediately.
    @(sigs.mon_cb);  
  end
  
endtask: run_phase  

`endif //WISHBONE_B3_MONITOR__SV
