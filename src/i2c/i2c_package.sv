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
// The I2C package contains UVM master and slave agents capable of driving 
//and monitoring a standard I2C bus.
package i2c_package;
  
  timeunit      1ns;
  timeprecision 1ps;
  
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
  // enum: e_i2c_frequency_mode
  // SCL frequency ranges defined in the I2C standard.
  //
  // I2C_STANDARD_MODE    - 0 : 100KHz
  // I2C_FAST_MODE        - 0 : 400KHz
  // I2C_FAST_MODE_PLUS   - 0 : 1MHz
  // I2C_HIGH_SPEED_MODE  - 0 : 3.4MHz
  typedef enum {
    I2C_STANDARD_MODE     = 0,
    I2C_FAST_MODE         = 1,
    I2C_FAST_MODE_PLUS    = 2,
    I2C_HIGH_SPEED_MODE   = 3
  } e_i2c_frequency_mode;
  
  // define: I2C_DEFAULT_SLAVE_ADDRESS 
  // Default address set for slave agents. Master agents receive this value as the 
  // default valid slave address in the environment. Value = 'h52.
  `define I2C_DEFAULT_SLAVE_ADDRESS 'h52
    
  `include "i2c_cfg.sv"
  `include "i2c_slave_cfg.sv"
  `include "i2c_master_cfg.sv"
  `include "i2c_sequence_item.sv"
  `include "i2c_common_methods.sv"
  `include "i2c_monitor.sv"
  `include "i2c_slave_driver.sv"
  `include "i2c_master_driver.sv"
  `include "i2c_slave_agent.sv"
  `include "i2c_master_agent.sv"
  
endpackage: i2c_package

`endif // I2C_PACKAGE__SV
