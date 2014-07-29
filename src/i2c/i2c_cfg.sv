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
// I2C agent base configuration object. <i2c_master_cfg> and <i2c_slave_cfg> configuration objects 
// inherit this class which contains members used by both master and slave agents. Class members values 
// are modified by overriding the constraints in the inherited object. 
class i2c_cfg extends uvm_object;
    
  // Variables: is_active
  // Agent can be defined passive or active.
  rand uvm_active_passive_enum is_active;
  
  // Variable: address_num_of_bits
  // Address can be 7 or 10 bits wide.
  rand int address_num_of_bits;
    
  // Variable: frequency_mode_range
  // Requested transmission frequency range on the I2C bus. Requests
  // vary between 100 Kbit/s (standard), 400 Kbit/s (fast), 1 Mbit/s (fast mode plus fm+), and 3.4 Mbit/s (high speed). 
  rand e_i2c_frequency_mode frequency_mode_range;
    
  // timing signals. define the bus's timing base on the requested SCL frequency. This is dependent on the <frequency_mode_range>
  // and are not random variable since they are updated after the random has completed
  realtime t_hd_sta_min;  // minimum hold time of a repeated start. after this period,the first clock pulse is generated
  realtime t_low_min;     // minimum low period of the SCL clock
  realtime t_high_min;    // minimum high period of the SCL clock
  realtime t_su_sta_min;  // minimum setup time for a repeated start
  realtime t_hd_dat_min;  // minimum data hold time from the SCL negedge
  realtime t_hd_dat_max;  // maximum data hold time from the SCL negedge
  realtime t_su_dat_min;  // minimum data setup time
  realtime t_su_sto_min;  // setup time for stop condition
  realtime t_buf_min;     // minimum time bus must be free between a stop and start condition

  `uvm_object_utils_begin(i2c_cfg)
    `uvm_field_enum(uvm_active_passive_enum, is_active,        UVM_ALL_ON)
    `uvm_field_int(address_num_of_bits,                        UVM_ALL_ON)
    `uvm_field_enum(e_i2c_frequency_mode,frequency_mode_range, UVM_ALL_ON)
  `uvm_object_utils_end

  // default constraints which are good for both master and slave 
  // implementations. constraints are overridden by master/slave 
  // configuration classes and then updated according to the
  // master/slave needs.
  extern constraint agent_is_active_c;
  extern constraint address_bits_c;
  extern constraint frequency_mode_range_c;
 
  extern function      new(string name = "i2c_cfg");
  extern function void post_randomize();
endclass: i2c_cfg

//------------------------------------------------------------------------//
// Function: new
// constructor
function i2c_cfg::new(string name = "i2c_cfg");
  super.new(name);

endfunction: new
//------------------------------------------------------------------------//
function void i2c_cfg::post_randomize();
  string values_to_log = "";
  
  case(frequency_mode_range)
    I2C_STANDARD_MODE: begin
      t_hd_sta_min = 4.0us;
      t_low_min    = 4.7us;
      t_high_min   = 4.0us;
      t_su_sta_min = 4.7us;
      t_hd_dat_min = 300ns;
      t_hd_dat_max = 3.45us;
      t_su_dat_min = 250ns;
      t_su_sto_min = 4.0us;
      t_buf_min    = 4.7us;
    end
    
    I2C_FAST_MODE: begin
      t_hd_sta_min = 0.6us;
      t_low_min    = 1.3us;
      t_high_min   = 0.6us;
      t_su_sta_min = 0.6us;
      t_hd_dat_min = 300ns;
      t_hd_dat_max = 0.9us;
      t_su_dat_min = 100ns;
      t_su_sto_min = 0.6us;
      t_buf_min    = 1.3us;
    end
    
    I2C_FAST_MODE_PLUS: begin
      t_hd_sta_min = 0.26us;
      t_low_min    = 0.5us;
      t_high_min   = 0.26us;
      t_su_sta_min = 0.26us;
      t_hd_dat_min = 300ns;
      t_hd_dat_max = 300ns; //no max is defined therefore max=min
      t_su_dat_min = 50ns;
      t_su_sto_min = 0.26us;
      t_buf_min    = 0.5us;
    end
    
    I2C_HIGH_SPEED_MODE: begin
      t_hd_sta_min = 160ns;
      t_low_min    = 160ns;
      t_high_min   = 60ns;
      t_su_sta_min = 160ns;
      t_hd_dat_min = 10ns; //spec writes zero, define as fall time of SCL
      t_hd_dat_max = 70ns;
      t_su_dat_min = 10ns;
      t_su_sto_min = 160ns;
      t_buf_min    = 0.5us; //isn't written in the spec
    end
    
    default: `uvm_fatal(get_type_name(), $sformatf("illegal mode %s", frequency_mode_range.name()) )
  endcase

  values_to_log = "i2c bus timing values:\n";
  values_to_log = {values_to_log, "------------------------\n" };
  values_to_log = {values_to_log, $sformatf("t_hd_sta_min = %t\n", t_hd_sta_min)};
  values_to_log = {values_to_log, $sformatf("t_low_min = %t\n", t_low_min)};
  values_to_log = {values_to_log, $sformatf("t_high_min = %t\n", t_high_min)};
  values_to_log = {values_to_log, $sformatf("t_su_sta_min = %t\n", t_su_sta_min)};
  values_to_log = {values_to_log, $sformatf("t_su_sta_min = %t\n", t_su_sta_min)};
  values_to_log = {values_to_log, $sformatf("t_hd_dat_min = %t\n", t_hd_dat_min)};
  values_to_log = {values_to_log, $sformatf("t_hd_dat_max = %t\n", t_hd_dat_max)};
  values_to_log = {values_to_log, $sformatf("t_su_dat_min = %t\n", t_su_dat_min)};
  values_to_log = {values_to_log, $sformatf("t_su_sto_min = %t\n", t_su_sto_min)};
  values_to_log = {values_to_log, $sformatf("t_buf_min = %t\n", t_buf_min)};
  `uvm_info(get_type_name(), values_to_log, UVM_FULL)
endfunction: post_randomize

//------------------------------------------------------------------------//
// constraint: agent_is_active_c
// constraints variable <is_active>. Default: is_active == UVM_PASSIVE.
constraint i2c_cfg::agent_is_active_c { soft is_active == UVM_PASSIVE; }

//------------------------------------------------------------------------//
// constraint: address_bits_c
// constraints variable <address_num_of_bits>. 
// Define the number of address bits used. Valid values are 7 or 10. Default: address_num_of_bits == 7.
constraint i2c_cfg::address_bits_c { soft address_num_of_bits == 7; } // currently only 7 bit is supported

//------------------------------------------------------------------------//
// constraint: frequency_mode_range_c
// constraints variable <frequency_mode_range>. Default: frequency_mode_range = I2C_STANDARD_MODE. 
constraint i2c_cfg::frequency_mode_range_c { frequency_mode_range == I2C_STANDARD_MODE;}

`endif //I2C_CFG__SV 
