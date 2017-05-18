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
//          * fixed reset logic (WB_B3 Rule 2.30)
//          * do not issue a transaction when reset is active
//      2016-06-13: by Jan Pospisil (fosfor.software@seznam.cz)
//          * fixed beginning of transaction for closely successive operations
//////////////////////////////////////////////////////////////////////////////
   
`ifndef WISHBONE_B3_DRIVER__SV
`define WISHBONE_B3_DRIVER__SV

// Class: wishbone_b3_master_driver
// Master driver begins driving a wishbone transaction when an <wishbone_b3_sequence_item> is received from the 
// agents sequencer. 
class wishbone_b3_master_driver  #(ADR_W = 32, DAT_W = 64, TAG_W = 1) extends uvm_driver #(wishbone_b3_sequence_item #(ADR_W, DAT_W, TAG_W));
  `uvm_component_param_utils(wishbone_b3_master_driver #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)))
  
  typedef wishbone_b3_sequence_item #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) td_wishbone_b3_sequence_item;
  virtual wishbone_b3_if            #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W)) sigs;
  wishbone_b3_common_methods        #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W)) common_mthds;
  
  extern         function      new(string name, uvm_component parent);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task          run_phase(uvm_phase phase);
  extern virtual task          write_transaction(td_wishbone_b3_sequence_item s_item);
  extern virtual task          read_transaction(td_wishbone_b3_sequence_item s_item);
  extern virtual task          drive_x_to_outputs_during_reset();

  endclass: wishbone_b3_master_driver
  
//------------------------------------------------------------------------//
function wishbone_b3_master_driver::new(string name, uvm_component parent);
  super.new(name, parent);

endfunction: new

//------------------------------------------------------------------------//
function void wishbone_b3_master_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  common_mthds      = wishbone_b3_common_methods #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W))::type_id::create("common_mthds", this);
  common_mthds.sigs = sigs;
  
endfunction: build_phase

//------------------------------------------------------------------------//
// task: run_phase
// run phase is called by UVM flow. Driver is active during this phase.
task wishbone_b3_master_driver::run_phase(uvm_phase phase);
  super.run_phase(phase);
  
  fork
    forever begin
      seq_item_port.get_next_item(req); 
      
      @(sigs.m_drv_cb); // synchronize driver operations to the current clock
        
      case (req.direction_e) 
        WB_B3_DIR_READ:  read_transaction ( .s_item(req) );
        WB_B3_DIR_WRITE: write_transaction( .s_item(req) );
        default: `uvm_fatal(get_type_name(),  $sformatf("Sequence item request unknown!") )
      endcase
      
      `uvm_info(get_type_name(),  $sformatf("%s", req.sprint() ), UVM_HIGH )
      seq_item_port.item_done(); // report to the sequencer that the item request has completed
      
    end

    forever drive_x_to_outputs_during_reset();
  join
  
endtask: run_phase

//------------------------------------------------------------------------//
task wishbone_b3_master_driver::write_transaction(td_wishbone_b3_sequence_item s_item);
  // wait for inactive reset
  wait(sigs.rst_i === 1'b0);
  
  // wait for free bus
  wait(~sigs.m_drv_cb.ack & ~sigs.m_drv_cb.err & ~sigs.m_drv_cb.rty);
  
  // stating a cycle
  sigs.m_drv_cb.cyc <= 1'b1; 
  sigs.m_drv_cb.tgc <= '0; // cycle tag currently not supported
  
  sigs.m_drv_cb.adr <= s_item.address;
  sigs.m_drv_cb.tga <= '0; // address tag currently not supported
  
  sigs.m_drv_cb.dat_o <= s_item.data;
  sigs.m_drv_cb.tgd_o <= '0; // data tag currently not supported
  
  sigs.m_drv_cb.we  <= 1'b1;
  sigs.m_drv_cb.sel <= s_item.select; // byte strobe lanes
  
  // start phase
  sigs.m_drv_cb.stb <= 1'b1;
  
  common_mthds.wait_for_response( .response(s_item.response_e) );
  
  sigs.m_drv_cb.stb <= 1'b0; //terminate phase
  sigs.m_drv_cb.cyc <= 1'b0; //terminate cycle
  
endtask: write_transaction

//------------------------------------------------------------------------//
task wishbone_b3_master_driver::read_transaction(td_wishbone_b3_sequence_item s_item);
  // wait for inactive reset
  wait(sigs.rst_i === 1'b0);
  
  // wait for free bus
  wait(~sigs.m_drv_cb.ack & ~sigs.m_drv_cb.err & ~sigs.m_drv_cb.rty);
  
  //stating a cycle
  sigs.m_drv_cb.cyc <= 1'b1; 
  sigs.m_drv_cb.tgc <= '0; // cycle tag currently not supported
  
  sigs.m_drv_cb.adr <= s_item.address;
  sigs.m_drv_cb.tga <= '0; // address tag currently not supported
  
  sigs.m_drv_cb.we  <= 1'b0;
  sigs.m_drv_cb.sel <= s_item.select; // byte strobe lanes
  
  // start phase
  sigs.m_drv_cb.stb <= 1'b1;
  
  common_mthds.wait_for_response( .response(s_item.response_e) );
  
  s_item.data = sigs.m_drv_cb.dat_i;
  //sigs.m_drv_cb.tgd_i; //currently data tag not supported
  
  sigs.m_drv_cb.stb <= 1'b0; //terminate phase
  sigs.m_drv_cb.cyc <= 1'b0; //terminate cycle
  
endtask: read_transaction

//------------------------------------------------------------------------//
// during reset, drive X to outputs to verify there isn't X propagation
// while reset is asserted. 
// This isn't being sent through a clocking block since the
// reset is asynchronous and there is no guarantee the clock is toggling
task wishbone_b3_master_driver::drive_x_to_outputs_during_reset();
  wait(sigs.rst_i === 1'b1);
  sigs.dat_o = 'x;
  sigs.tgd_o = 'x;
  sigs.adr   = 'x;
  sigs.cyc   = 'x;
  sigs.lock  = 'x;
  sigs.sel   = 'x;
  sigs.stb   = 'x;
  sigs.tga   = 'x;
  sigs.tgc   = 'x;
  sigs.we    = 'x;
  
  wait(sigs.rst_i === 1'b0);
  sigs.dat_o = '0;
  sigs.tgd_o = '0;
  sigs.adr   = '0;
  sigs.cyc   = '0;
  sigs.lock  = '0;
  sigs.sel   = '0;
  sigs.stb   = '0;
  sigs.tga   = '0;
  sigs.tgc   = '0;
  sigs.we    = '0;
      
endtask: drive_x_to_outputs_during_reset

`endif //WISHBONE_B3_DRIVER__SV
