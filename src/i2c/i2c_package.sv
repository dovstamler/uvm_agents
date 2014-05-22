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
 
`ifndef I2C_PACKAGE__SV
`define I2C_PACKAGE__SV

// package: i2c_package
// The I2C package contains an UVM agent capable of driving and monitoring
// a standard I2C bus.

package i2c_package;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  //------------------//
  // enum: e_i2c_direction
  // Request type, read or write
  //
  // I2C_DIR_WRITE - write request
  // I2C_DIR_READ  - read request
  typedef enum {
    I2C_DIR_WRITE = 0,
    I2C_DIR_READ  = 1
  } e_i2c_direction;
  
  //------------------//
  // enum: e_i2c_type
  // Agent driver type, Master or Slave
  //
  // I2C_SLAVE  - agent is a slave
  // I2C_MASTER - agent is a master
  typedef enum {
    I2C_SLAVE  = 0,
    I2C_MASTER = 1
  } e_i2c_type;
  
  
  `include "i2c_cfg.sv"
  `include "i2c_sequence_item.sv"
  `include "i2c_monitor.sv"
  `include "i2c_slave_driver.sv"
  `include "i2c_agent.sv"
  
endpackage: i2c_package

`endif // I2C_PACKAGE__SV
