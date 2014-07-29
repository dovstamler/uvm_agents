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
 
`ifndef I2C_SEQUENCE_ITEM__SV
`define I2C_SEQUENCE_ITEM__SV
      
// class: i2c_sequence_item
// The I2C sequence item encapsulates an entire transaction including
// multiple transmitted / received words for a single address request.
// A transaction begins with a start condition and ends with either
// a stop condition or a repeated start condition.
class i2c_sequence_item extends uvm_sequence_item;
  
  // variable: direction_e
  // defines if the request is a read or write. See <i2c_package>
  // for valid enumerations.
  rand e_i2c_direction direction_e;
  
  // variable: address
  // requested address. Address can be 7 or 10 bits wide.
  rand logic [9:0]     address;
  
  // variable: address_ack 
  // high when there was a slave response to the requested address.
  rand logic           address_ack;
  
  // variable: data
  // holds either received data from a read request or write data to transmit. 
  // each request can send or receive multiple 8 bit data words.
  rand logic [7:0]     data[$];
  
  `uvm_object_utils_begin (i2c_sequence_item)
    `uvm_field_enum( e_i2c_direction, direction_e,UVM_ALL_ON) 
    `uvm_field_int(                   address,    UVM_ALL_ON) 
    `uvm_field_int(                   address_ack,UVM_ALL_ON) 
    `uvm_field_queue_int(             data,       UVM_ALL_ON)
  `uvm_object_utils_end

  extern function  new(string name = "i2c_sequence_item");
  
endclass: i2c_sequence_item

//------------------------------------------------------------------------//
// function: new
// constructor
function i2c_sequence_item::new(string name = "i2c_sequence_item");
  super.new(name);

endfunction: new

`endif //I2C_SEQUENCE_ITEM__SV
