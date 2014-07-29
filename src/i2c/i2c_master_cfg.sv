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

`ifndef I2C_MASTER_CFG__SV
`define I2C_MASTER_CFG__SV

// Class: i2c_master_cfg
// I2C master agents configuration object.  
class i2c_master_cfg extends i2c_cfg;
  
  // Variable: requested_scl_frequency_in_khz
  // SCL frequency in KHz. constrainted to the <i2c_cfg::frequency_mode_range> variable.
  rand int requested_scl_frequency_in_khz;
  
  // Variable: max_num_of_master_words
  // Maximum number of words agent can transmit for a single address
  // request.
  rand int max_num_of_master_words;
  
  // Variable: valid_slave_address
  // Contains all valid slave addresses in the environment.
  rand logic[9:0] valid_slave_address[$];
  
  `uvm_object_utils_begin(i2c_master_cfg)
    `uvm_field_int(requested_scl_frequency_in_khz, UVM_ALL_ON)
    `uvm_field_int(max_num_of_master_words,        UVM_ALL_ON)
    `uvm_field_queue_int(valid_slave_address,      UVM_ALL_ON)
  `uvm_object_utils_end
  
  extern function new(string name = "i2c_master_cfg");
  
  extern constraint agent_is_active_c;
  extern constraint address_bits_c;
  extern constraint frequency_mode_range_c;
  extern constraint requested_scl_frequency_in_khz_c;
  extern constraint max_num_of_master_words_c;
  extern constraint valid_slave_address_c;

endclass: i2c_master_cfg

//------------------------------------------------------------------------//
// function: new
// Object constructor
function i2c_master_cfg::new(string name = "i2c_master_cfg");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
// constraint: agent_is_active_c
// Constraints variable <i2c_cfg::is_active>. Default: is_active = UVM_ACTIVE.
constraint i2c_master_cfg::agent_is_active_c { soft is_active == UVM_ACTIVE; }
//------------------------------------------------------------------------//
// constraint: address_bits_c
// Constraints variable <i2c_cfg::address_num_of_bits>. 
// Define the number of address bits used. Valid values are 7 or 10. Default: address_num_of_bits == 7.
constraint i2c_master_cfg::address_bits_c { address_num_of_bits == 7; } // currently only 7 bit is supported

//------------------------------------------------------------------------//
// constraint:frequency_mode_range_c
// Constraints variable <frequency_mode_range>. Default: frequency_mode_range = I2C_STANDARD_MODE. 
constraint i2c_master_cfg::frequency_mode_range_c { frequency_mode_range == I2C_STANDARD_MODE;}

//------------------------------------------------------------------------//
// constraint: requested_scl_frequency_in_khz_c
// Constraints variable <requested_scl_frequency_in_khz>. 
// Sets SCL frequency for masters. dependent on <i2c_cfg::frequency_mode_range> value.
constraint i2c_master_cfg::requested_scl_frequency_in_khz_c { 
       (frequency_mode_range == I2C_STANDARD_MODE)   -> requested_scl_frequency_in_khz inside {[10:100]};
       (frequency_mode_range == I2C_FAST_MODE)       -> requested_scl_frequency_in_khz inside {[100:400]};
       (frequency_mode_range == I2C_FAST_MODE_PLUS)  -> requested_scl_frequency_in_khz inside {[400:1000]};
       (frequency_mode_range == I2C_HIGH_SPEED_MODE) -> requested_scl_frequency_in_khz inside {[1000:3400]};
       soft requested_scl_frequency_in_khz == 0; // should never reach here, used as a default value
}

//------------------------------------------------------------------------//
// constraint: max_num_of_master_words_c
// Constraints variable <max_num_of_master_words>. 
// Default allows a maximum of 10 transmission words per address.
constraint i2c_master_cfg::max_num_of_master_words_c {if (is_active == UVM_ACTIVE) {
                                                           soft max_num_of_master_words <= 10;
                                                           soft max_num_of_master_words  > 0;
                                                      }
                                                      else soft max_num_of_master_words == 0;
                                                     }

//------------------------------------------------------------------------//
// constraint: valid_slave_address_c
// Constraints queue <valid_slave_address> to the default slave address for the initial integration phase. Basic setup has a 
// single slave constrained to address <i2c_package::I2C_DEFAULT_SLAVE_ADDRESS>. This constraint is used only for the initial integration phase and
// can be ignored when setting the environment I2C addresses.
constraint i2c_master_cfg::valid_slave_address_c { soft valid_slave_address.size == 1;
                                                   soft valid_slave_address[0]  == `I2C_DEFAULT_SLAVE_ADDRESS;
                                                 }
                                                 
`endif //I2C_MASTER_CFG__SV
