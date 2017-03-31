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
//      2017-03-31: by Jan Pospisil (fosfor.software@seznam.cz)
//          * added transaction timeout
//////////////////////////////////////////////////////////////////////////////

`ifndef WISHBONE_B3_COMMON_METHODS__SV
`define WISHBONE_B3_COMMON_METHODS__SV
  
class wishbone_b3_common_methods #(ADR_W = 32, DAT_W = 64, TAG_W = 1) extends uvm_object;
  `uvm_object_param_utils( wishbone_b3_common_methods #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)) )
  
  virtual wishbone_b3_if #(.DAT_W(DAT_W), .ADR_W(ADR_W), .TAG_W(TAG_W)) sigs;
  wishbone_b3_master_cfg cfg;
  
  extern          function new(string name = "wishbone_b3_common_methods");
  extern virtual  task     wait_for_response(output e_wishbone_b3_response response);
    
endclass: wishbone_b3_common_methods

//------------------------------------------------------------------------//
function wishbone_b3_common_methods::new(string name = "wishbone_b3_common_methods");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
task wishbone_b3_common_methods::wait_for_response(output e_wishbone_b3_response response);
  fork
   begin
     wait( (sigs.m_drv_cb.ack === 1'b1) || (sigs.m_drv_cb.err === 1'b1) || (sigs.m_drv_cb.rty === 1'b1) );
     // specifically not if-else so the value will overwrite if there is an erroneous multiple 
     // response.
     if (sigs.m_drv_cb.ack === 1'b1) response = WB_B3_RESPONSE_ACK_OK;
     if (sigs.m_drv_cb.rty === 1'b1) response = WB_B3_RESPONSE_ACK_RTY;
     if (sigs.m_drv_cb.err === 1'b1) response = WB_B3_RESPONSE_ACK_ERR;
   end
   begin
     #cfg.timeout `uvm_error("WB_MON", "Transaction time-out!")
     response = WB_B3_RESPONSE_ACK_ERR;
   end
  join_any
  disable fork;
 
endtask: wait_for_response

`endif //WISHBONE_B3_COMMON_METHODS__SV
