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
//      2016-06-14: by Jan Pospisil (fosfor.software@seznam.cz)
//          * added get_type_name() and convert2string() methods; now this
//            call is possible:
//            $sformatf(
//              "Transaction \"%s\" received: %s",
//              t.get_type_name(), t.convert2string())
//////////////////////////////////////////////////////////////////////////////

`ifndef WISHBONE_B3_SEQUENCE_ITEM__SV
`define WISHBONE_B3_SEQUENCE_ITEM__SV

// class: wishbone_b3_sequence_item
// wishbone b3 sequence item encapsulates in its members all information
// necessary to create a wishbone transaction.
class wishbone_b3_sequence_item #(ADR_W = 32, DAT_W = 64, TAG_W = 1) extends uvm_sequence_item;

  // variable: direction_e
  // defines if the request is a read or write. See <wishbone_b3_package>
  // for valid enumerations.
  rand e_wishbone_b3_direction  direction_e;
  
  // variable: address
  // requested address. A master agent will drive the address bus with this
  // value while a slave agent will receive the value on the address bus.
  rand logic [ADR_W-1:0]        address;
  
  // variable: data
  // transaction data value. A master agent sets this members value for a write
  // request and receives a value for a read request. 
  rand logic [DAT_W-1:0]        data;
  
  // variable: select
  // byte select. Each select bit represents a valid data byte in the <data> member.
  rand logic [(DAT_W/8)-1:0]    select; // data strobe
  
  // variable: response_e
  // response notifying if the transaction was successful. See <wishbone_b3_package> for valid enumerations. 
  rand e_wishbone_b3_response response_e;
  
  `uvm_object_param_utils_begin (wishbone_b3_sequence_item #(.ADR_W(ADR_W), .DAT_W(DAT_W), .TAG_W(TAG_W)))
    `uvm_field_enum( e_wishbone_b3_direction, direction_e, UVM_ALL_ON) 
    `uvm_field_int(                           address,     UVM_ALL_ON) 
    `uvm_field_int(                           data,        UVM_ALL_ON)
    `uvm_field_int(                           select,      UVM_ALL_ON)
    `uvm_field_enum( e_wishbone_b3_response,  response_e,  UVM_ALL_ON)
  `uvm_object_utils_end

  extern function new(string name = "wishbone_b3_sequence_item");
  extern function string get_type_name();
  extern function string convert2string();
  
  extern constraint response_c;
  extern constraint select_c;
  
endclass: wishbone_b3_sequence_item

//------------------------------------------------------------------------//
// function: new
// constructor
function wishbone_b3_sequence_item::new(string name = "wishbone_b3_sequence_item");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
// function: get_type_name
// override of super's method for parametrized class
function string wishbone_b3_sequence_item::get_type_name();
  return "wishbone_b3_sequence_item";

endfunction 

//------------------------------------------------------------------------//
// function: convert2string
// for custom displaying class content
function string wishbone_b3_sequence_item::convert2string();
  // convert2string = "TBD";
  convert2string = $sformatf(
    "direction_e = %s, address = 0x%H, data = 0x%H, select = 0b%B, response_e = %s",
    direction_e.name(), address, data, select, response_e.name());

endfunction

//------------------------------------------------------------------------//
// constraint: response_c
// constraints variable <response_e>. Default value = WB_B3_RESPONSE_ACK_ERR.
constraint wishbone_b3_sequence_item::response_c { soft response_e == WB_B3_RESPONSE_ACK_ERR;} 

//------------------------------------------------------------------------//
// constraint: select_c
// constraints variable <select>. set default value so all bytes are valid. Default select = '1.
constraint wishbone_b3_sequence_item::select_c { soft select == '1;} 

`endif //WISHBONE_B3_SEQUENCE_ITEM__SV
