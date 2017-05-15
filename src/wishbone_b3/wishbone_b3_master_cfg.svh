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
 
`ifndef WISHBONE_B3_MASTER_CFG__SV
`define WISHBONE_B3_MASTER_CFG__SV

// Class: wishbone_b3_master_cfg
// Wishbone master agent configuration class. 
class wishbone_b3_master_cfg extends uvm_object;
  
  // Variables: is_active
  // Agent can be defined passive or active.
  rand uvm_active_passive_enum is_active;

  `uvm_object_utils_begin(wishbone_b3_master_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_object_utils_end
  
  extern function new(string name = "wishbone_b3_master_cfg");

  extern constraint agent_is_active_c;
  
endclass: wishbone_b3_master_cfg

//------------------------------------------------------------------------//
// Function: new
// constructor
function wishbone_b3_master_cfg::new(string name = "wishbone_b3_master_cfg");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
// constraint: agent_is_active_c
// constraints variable <is_active>. Default: is_active == UVM_ACTIVE.
constraint wishbone_b3_master_cfg::agent_is_active_c { is_active == UVM_ACTIVE; }

`endif //WISHBONE_B3_MASTER_CFG__SV
