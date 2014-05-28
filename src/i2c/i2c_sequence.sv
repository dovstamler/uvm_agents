`ifndef I2C_SEQUENCE__SV
`define I2C_SEQUENCE__SV

class i2c_sequence extends uvm_sequence #(i2c_sequence_item);

  `uvm_object_utils(i2c_sequence)
  
  extern         function   new(string name = "i2c_sequence");
  extern virtual task       pre_body();
  extern virtual task       body();
  extern virtual task       post_body();

endclass: i2c_sequence

//------------------------------------------------------------------//
function i2c_sequence::new(string name = "i2c_sequence");
  super.new(name);

endfunction: new

//------------------------------------------------------------------//
task i2c_sequence::pre_body();
  super.pre_body();
  
  if (starting_phase != null) starting_phase.raise_objection(this);

endtask: pre_body
//------------------------------------------------------------------//

task i2c_sequence::body();
  /***************************
   * Write sequence code here,
   * this is an example for creating a random 
   * item and sending it out
   ***************************/
   `uvm_do(req);
   
endtask: body
//------------------------------------------------------------------//
task i2c_sequence::post_body();
  super.post_body();

 if (starting_phase != null) starting_phase.drop_objection(this);
 
endtask: post_body
`endif //I2C_SEQUENCE__SV
