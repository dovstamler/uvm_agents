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
 
`ifndef I2C_IF__SV
`define I2C_IF__SV
    
// interface: i2c_if
// Interface connecting the agent to an I2C SCL / SDA bus
//
// Parameters: 
//
// clk    - i2c block input clock. Clocking blocks are dependent on this input.
// (start code)
// 
// i2c_if i2c_sigs( .clk(clk) ); // interface instance
// 
// // connect the signals as a tri-state buffer to the SDA/SCL lines
// assign sda_io          = (i2c_sigs.sda_out) ? 1'bz : i2c_sigs.sda_out;
// assign i2c_sigs.sda_in = sda_io;
// 
// assign scl_io          = (i2c_sigs.scl_out) ? 1'bz : i2c_sigs.scl_out;
// assign i2c_sigs.scl_in = scl_io;
//
// (end code)
interface i2c_if (input bit clk);
  logic resetn; // used for i2c block level verification
    
  logic sda_in;
  logic sda_out;
  logic scl_in;
  logic scl_out;
  
  clocking drv_cb @(posedge clk);
      default input #1step output #1;
      
      input   resetn;
      
      input   sda_in;
      output  sda_out;
      
      input   scl_in;
      output  scl_out;
  
  endclocking: drv_cb
  
  //---------------------------------//
  clocking mon_cb @(posedge clk);
      default input #1step output #1;
      
      input scl_in;
      input sda_in;
      
  endclocking: mon_cb

endinterface: i2c_if
    
`endif //I2C_IF__SV
