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
//  Modifications:
//      2016-06-08: by Jan Pospisil (fosfor.software@seznam.cz)
//          * file extensions renamed (.sv for compilable units, .svh for
//            include-able units)
//////////////////////////////////////////////////////////////////////////////

`ifndef WISHBONE_B3_PACKAGE__SV
`define WISHBONE_B3_PACKAGE__SV

// package: wishbone_b3_package
// The wishbone b3 package contains a parameterizable wishbone b3 master 
// agent capable of driving and monitoring a wishbone b3 compliant bus.
package wishbone_b3_package;
  
  timeunit      1ns;
  timeprecision 1ps;
  
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  //------------------//
  // enum: e_wishbone_b3_direction
  // Request type, read or write
  //
  // WB_B3_DIR_READ  - read request
  // WB_B3_DIR_WRITE - write request
  typedef enum {
    WB_B3_DIR_READ  = 0,
    WB_B3_DIR_WRITE = 1
  } e_wishbone_b3_direction;
  
  //------------------//
  // enum: e_wishbone_b3_response
  // Response type, OK, ERR or RTY
  //
  // WB_B3_RESPONSE_ACK_OK  - normal bus termination
  // WB_B3_RESPONSE_ACK_ERR - abnormal cycle termination
  // WB_B3_RESPONSE_ACK_RTY - interface not ready for cycle, retry current cycle
  typedef enum {
    WB_B3_RESPONSE_ACK_OK  = 0,
    WB_B3_RESPONSE_ACK_ERR = 1,
    WB_B3_RESPONSE_ACK_RTY = 2
  } e_wishbone_b3_response;

  `include "wishbone_b3_common_methods.svh"
  `include "wishbone_b3_master_cfg.svh"
  `include "wishbone_b3_sequence_item.svh"
  `include "wishbone_b3_master_driver.svh"
  `include "wishbone_b3_monitor.svh"
  `include "wishbone_b3_reg_adapter.svh"
  `include "wishbone_b3_master_agent.svh"
  
endpackage: wishbone_b3_package

`endif
