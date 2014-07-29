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

`ifndef I2C_SEQUENCE_PACKAGE
`define I2C_SEQUENCE_PACKAGE

// package: i2c_sequence_package
// Sequence package for all I2C master sequences. Import package for tests
// instantiating and calling these sequences. 
// (start code)
// import   i2c_sequence_package::*;
// (end code)
package i2c_sequence_package;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  import i2c_package::*;
  
  `include "i2c_base_sequence.sv"
  `include "i2c_basic_sequence.sv"
  
endpackage: i2c_sequence_package

`endif // I2C_SEQUENCE_PACKAGE
