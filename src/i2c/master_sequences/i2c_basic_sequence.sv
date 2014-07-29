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

`ifndef I2C_BASIC_SEQUENCE__SV
`define I2C_BASIC_SEQUENCE__SV

// Class: i2c_basic_sequence
// This sequence creates a number of constrainted I2C transactions to 
// demonstrate the use of the I2C master agent. 
class i2c_basic_sequence extends i2c_base_sequence;
  `uvm_object_utils(i2c_basic_sequence)
  
  extern         function   new(string name = "i2c_basic_sequence");
  extern virtual task       body();

endclass: i2c_basic_sequence

//------------------------------------------------------------------//
// function: new
// object constructor
function i2c_basic_sequence::new(string name = "i2c_basic_sequence");
  super.new(name);

endfunction: new

//------------------------------------------------------------------//
// task: body
// creates example <i2c_sequence_item> objects requests. See code for examples.
task i2c_basic_sequence::body();
  
  // address: constrained to only valid addresses
  // data.size: value used for both write and read requests. 
  //            Write request - amount of words written out
  //            Read request  - amount of words master will receive from the slave before ending the transaction
  // direction: random
  for(int i = 0; i < 5; i++) begin
    `uvm_do_with(req, { if(cfg.address_num_of_bits == 7) address[9:7] == '0;
                        address   inside cfg.valid_slave_address;
                        data.size inside {[1: cfg.max_num_of_master_words]};
                      } 
                 );
  end

endtask: body

`endif //I2C_BASIC_SEQUENCE__SV
