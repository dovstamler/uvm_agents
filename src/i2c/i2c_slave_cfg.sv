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

`ifndef I2C_SLAVE_CFG__SV
`define I2C_SLAVE_CFG__SV

// Class: i2c_slave_cfg
// I2C slave agents configuration object. 
class i2c_slave_cfg extends i2c_cfg;
    
  // Variable: slave_address
  // Address to which the agent will respond. The agents response is 
  // to accesses requests from / to this address.
  rand logic[9:0] slave_address;
  
  // Variable: max_write_word_access_before_nack
  // Amount of consecutive write word requests the agent  
  // allows before returning a NACK.
  rand int max_write_word_access_before_nack;
  
  // Variable: max_read_word_access_before_nack
  // Amount of consecutive read word requests the agent  
  // allows before returning a NACK.
  rand int max_read_word_access_before_nack;
   
  `uvm_object_utils_begin(i2c_slave_cfg)
    `uvm_field_int(slave_address,                     UVM_ALL_ON)
    `uvm_field_int(max_write_word_access_before_nack, UVM_ALL_ON)
    `uvm_field_int(max_read_word_access_before_nack,  UVM_ALL_ON)
  `uvm_object_utils_end
  
  extern function new(string name = "i2c_slave_cfg");
    
  extern constraint agent_is_active_c;
  extern constraint address_bits_c;
  extern constraint slave_address_c;
  extern constraint max_word_access_c;

endclass: i2c_slave_cfg

//------------------------------------------------------------------------//
function i2c_slave_cfg::new(string name = "i2c_slave_cfg");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
// constraint: agent_is_active_c
// constraints variable <i2c_cfg::is_active>. Default: is_active = UVM_ACTIVE.
constraint i2c_slave_cfg::agent_is_active_c { soft is_active == UVM_ACTIVE; }
//------------------------------------------------------------------------//
// constraint: address_bits_c
// constraints variable <i2c_cfg::address_num_of_bits>. 
// Define the number of address bits used. Valid values are 7 or 10. Default: address_num_of_bits == 7.
constraint i2c_slave_cfg::address_bits_c { address_num_of_bits == 7; } // currently only 7 bit is supported
//------------------------------------------------------------------------//
// constraint: slave_address_c
// constraints variable <slave_address>. Default: slave_address = <i2c_package::I2C_DEFAULT_SLAVE_ADDRESS>.
constraint i2c_slave_cfg::slave_address_c { if (is_active == UVM_ACTIVE)  soft slave_address == `I2C_DEFAULT_SLAVE_ADDRESS;
                                            else                          soft slave_address == 0;
                                          }
//------------------------------------------------------------------------//
// constraint: max_word_access_c
// constraints variables <max_write_word_access_before_nack> and <max_read_word_access_before_nack>.
//
// Default:
// - max_write_word_access_before_nack >= 1
// - max_write_word_access_before_nack <  50
// - max_read_word_access_before_nack  == max_write_word_access_before_nack
constraint i2c_slave_cfg::max_word_access_c { 
  if (is_active == UVM_ACTIVE) {
    soft max_write_word_access_before_nack >= 1;
    soft max_write_word_access_before_nack < 50;
    soft max_read_word_access_before_nack == max_write_word_access_before_nack;
  }
  else {
    soft max_write_word_access_before_nack == 0;
    soft max_write_word_access_before_nack == 0;
  }
}

`endif //I2C_SLAVE_CFG__SV
