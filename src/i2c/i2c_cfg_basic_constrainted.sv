`ifndef I2C_CFG_BASIC_CONSTRAINTED__SV
`define I2C_CFG_BASIC_CONSTRAINTED__SV
	
class i2c_cfg_basic_constrainted extends i2c_cfg;
    `uvm_object_utils(i2c_cfg_basic_constrainted)
    
	/**** Example of adding variables to the factory for usage
	 * Note: remove the line "`uvm_object_utils" and uncomment the section "`uvm_object_utils_begin"
	 *
	 * int my_int;
	 * `uvm_object_utils_begin(i2c_cfg_basic_constrainted)
	 *    `uvm_field_int(my_int, UVM_ALL_ON)
	 *  `uvm_object_utils_end
	 ****/
	 
    extern function new(string name = "i2c_cfg_basic_constrainted");
    extern constraint address_c;

endclass: i2c_cfg_basic_constrainted

//------------------------------------------------------------------------//
function i2c_cfg_basic_constrainted::new(string name = "i2c_cfg_basic_constrainted");
  super.new(name);

endfunction: new

//------------------------------------------------------------------------//
constraint i2c_cfg_basic_constrainted::address_c {
  
}
`endif //I2C_CFG_BASIC_CONSTRAINTED__SV
