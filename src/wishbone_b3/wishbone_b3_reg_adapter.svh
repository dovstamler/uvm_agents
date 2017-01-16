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

`ifndef WISHBONE_B3_REG_ADAPTER_SV
`define WISHBONE_B3_REG_ADAPTER_SV

// class: wishbone_b3_reg_adapter
// Register Abstraction Layer (RAL) adapter for a wishbone master agent. Converts RAL requests to 
// a wishbone bus transaction. 
class wishbone_b3_reg_adapter #(ADR_W = 32, DAT_W = 64, TAG_W = 1) extends uvm_reg_adapter;
  `uvm_object_param_utils(wishbone_b3_reg_adapter #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W) ))
  
  typedef wishbone_b3_sequence_item #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) td_wishbone_b3_sequence_item;

//--------------------------------------------------------------//
// function: new
// constructor  
  function new(string name="wishbone_b3_reg_adapter");
    super.new(name);

  endfunction: new
//--------------------------------------------------------------//
// function: reg2bus
// Converts a RAL request to a <wishbone_b3_sequence_item>.
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    td_wishbone_b3_sequence_item wb_b3_item = td_wishbone_b3_sequence_item::type_id::create("wb_b3_item");
    
    wb_b3_item.direction_e = (rw.kind == UVM_READ) ? WB_B3_DIR_READ : WB_B3_DIR_WRITE;
    wb_b3_item.address     =  rw.addr;
    wb_b3_item.data        =  rw.data;
    wb_b3_item.select      = '1; // for a register request all bytes are valid
    
    return wb_b3_item;
    
  endfunction: reg2bus
  
//--------------------------------------------------------------//
// function: bus2reg
// Converts a <wishbone_b3_sequence_item> to a RAL request.
  virtual function void bus2reg(uvm_sequence_item bus_item,
                                ref uvm_reg_bus_op rw);
    td_wishbone_b3_sequence_item wb_b3_item;
    if (!$cast(wb_b3_item, bus_item)) `uvm_fatal(get_type_name(),"Bus item is not of type td_wishbone_b3_sequence_item")

    rw.kind   = (wb_b3_item.direction_e == WB_B3_DIR_READ) ? UVM_READ : UVM_WRITE;
    rw.addr   =  wb_b3_item.address;
    rw.data   =  wb_b3_item.data;
    rw.status = (wb_b3_item.response_e === WB_B3_RESPONSE_ACK_OK) ? UVM_IS_OK : UVM_NOT_OK;
    
  endfunction: bus2reg

endclass: wishbone_b3_reg_adapter

`endif // WISHBONE_B3_REG_ADAPTER_SV
