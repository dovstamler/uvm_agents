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
   
`ifndef I2C_CFG__SV
`define I2C_CFG__SV
	
// Class: i2c_cfg
// I2C agent configuration object
class i2c_cfg extends uvm_object;
    
    // Variables: is_active
    // Agent can be defined passive or active.
    rand uvm_active_passive_enum is_active;
    
    // Variable: is_master_or_slave_e
    // Agent driver can be a master or slave. See <i2c_package> 
    // for valid enumeration.
    rand e_i2c_type is_master_or_slave_e;
    
    // Variable: address_num_of_bits
    // Address can be 7 or 10 bits wide.
    rand int address_num_of_bits;
    
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
    
    // Variable: wait_cycles_from_scl_negedge
    // Amount of system clock cycles the agent waits from the SCL
    // negative edge before modifying the SDA to its next value.
    rand int  wait_cycles_from_scl_negedge;

    `uvm_object_utils_begin(i2c_cfg)
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
      `uvm_field_enum(e_i2c_type,is_master_or_slave_e,    UVM_ALL_ON)
      `uvm_field_int(address_num_of_bits,                 UVM_ALL_ON)
      `uvm_field_int(slave_address,                       UVM_ALL_ON)
      `uvm_field_int(max_write_word_access_before_nack,   UVM_ALL_ON)
      `uvm_field_int(max_read_word_access_before_nack,    UVM_ALL_ON)
      `uvm_field_int(wait_cycles_from_scl_negedge,        UVM_ALL_ON)
    `uvm_object_utils_end

    extern constraint agent_is_active_c;
    extern constraint slave_address_c;
    extern constraint address_bits_c;
    extern constraint max_word_access_c;
    extern constraint wait_cycles_from_scl_negedge_c;
    extern constraint is_master_or_slave_c;
 
    extern function new(string name = "i2c_cfg");

endclass: i2c_cfg

//------------------------------------------------------------------------//
// Function: new
// constructor
function i2c_cfg::new(string name = "i2c_cfg");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
// constraint: agent_is_active_c
// constraints variable <is_active>. Default: is_active = UVM_ACTIVE.
constraint i2c_cfg::agent_is_active_c { soft is_active == UVM_ACTIVE; }
//------------------------------------------------------------------------//
// constraint: slave_address_c
// constraints variable <slave_address>. Default: slave_address = 'h50.
constraint i2c_cfg::slave_address_c { soft slave_address == 'h50; }
//------------------------------------------------------------------------//
// constraint: address_bits_c
// constraints variable <address_num_of_bits>. 
// Define the number of address bits used. Valid values are 7 or 10.
constraint i2c_cfg::address_bits_c { address_num_of_bits == 7; } // currently only 7 bit is supported
//------------------------------------------------------------------------//
// constraint: max_word_access_c
// constraints variables <max_write_word_access_before_nack> and <max_read_word_access_before_nack>.
//
// Default:
// - max_write_word_access_before_nack >= 1
// - max_write_word_access_before_nack <  50
// - max_read_word_access_before_nack  == max_write_word_access_before_nack
constraint i2c_cfg::max_word_access_c { 
  soft max_write_word_access_before_nack >= 1;
  soft max_write_word_access_before_nack < 50;
  
  soft max_read_word_access_before_nack == max_write_word_access_before_nack;

}
//------------------------------------------------------------------------//
// constraint: wait_cycles_from_scl_negedge_c
// constraints variable <wait_cycles_from_scl_negedge>. Default: wait_cycles_from_scl_negedge = 6.
constraint i2c_cfg::wait_cycles_from_scl_negedge_c { soft wait_cycles_from_scl_negedge == 6; }
//------------------------------------------------------------------------//
// constraint: is_master_or_slave_c
// constraints variable <is_master_or_slave_e>. 
// Select if the agent is a master or slave. Default: is_master_or_slave_e = I2C_SLAVE
constraint i2c_cfg::is_master_or_slave_c { is_master_or_slave_e == I2C_SLAVE; } // currently only slave mode is implemented

`endif //I2C_CFG__SV 
