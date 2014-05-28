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
 
`ifndef I2C_SLAVE_DRIVER__SV
`define I2C_SLAVE_DRIVER__SV

// Class: i2c_slave_driver
// Slave driver waits for a master to begin a transaction and responds 
// in accordance with the current configuration defined in <i2c_cfg>. 
class i2c_slave_driver extends uvm_driver #(i2c_sequence_item);

  
  virtual i2c_if  sigs;
  i2c_cfg         cfg;
  
  logic [9:0]     address;
  bit   [7:0]     data[int]; //associative array so it can be allocated on the fly
  bit             start_detection;
  
  event           start_detection_e;
  event           stop_detection_e;
  
  `uvm_component_utils(i2c_slave_driver)
  
  extern         function       new(string name, uvm_component parent);
  extern virtual function void  build_phase(uvm_phase phase);
  extern virtual task           run_phase(uvm_phase phase);
  extern virtual task           drive_x_to_outputs_during_reset();
  extern virtual task           slave_search_for_start_condition(uvm_phase phase);
  extern virtual task           slave_search_for_stop_condition(uvm_phase phase);
  extern virtual task           slave_address_is_to_this_slave(output logic address_is_for_salve);
  extern virtual task           slave_get_read_write(output e_i2c_direction transaction_direction);
  extern virtual task           send_ack();
  extern virtual task           slave_write_request();
  extern virtual task           slave_read_request();
  extern virtual task           wait_for_ack_from_master(output bit ack);
  extern virtual task           wait_for_scl_negedge_plus_n_cycles();

  endclass: i2c_slave_driver
  
//------------------------------------------------------------------------//
// Function: new
// constructor
function i2c_slave_driver::new(string name, uvm_component parent);
  super.new(name, parent);

endfunction: new

//------------------------------------------------------------------------//
function void i2c_slave_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  phase.raise_objection(this);
  
  if ( cfg  == null ) `uvm_fatal("DRV",  $sformatf("i2c cfg object is null!") )
  
  phase.drop_objection(this);
  
endfunction: build_phase

//------------------------------------------------------------------------//
// task: run_phase
// run phase is called by UVM flow. Driver is active during this phase.
task i2c_slave_driver::run_phase(uvm_phase phase);
  logic           enable_slave  = 0;
  int             thread_number = 0;
  process         thread_process[$];
  e_i2c_direction transaction_direction;
  super.run_phase(phase);
  start_detection = 1'b0; 
  
  fork
    forever drive_x_to_outputs_during_reset();
    forever slave_search_for_start_condition( .phase(phase) );
    forever slave_search_for_stop_condition(  .phase(phase) );
    forever begin

      fork 
        begin // respond to request thread
          thread_process[thread_number] = process::self();
          wait(start_detection_e.triggered);
          slave_address_is_to_this_slave( .address_is_for_salve(enable_slave) );

          if (enable_slave) begin
            slave_get_read_write( .transaction_direction(transaction_direction) ); 
            send_ack();
            
            case (transaction_direction)
              I2C_DIR_WRITE : slave_write_request();
              I2C_DIR_READ  : slave_read_request();
              default   : `uvm_fatal("DRV",  $sformatf("Slave read / write request unknown!") )
            endcase
          end
        end
        
        begin // start event is detected, wait for stop or repeated start to end this thread.
          //grab the current thread number since the thread number can increment if the response thread terminates naturally
          int wait_for_thread_number = thread_number;
          wait(start_detection_e.triggered); 
          #1; //wait so start event is no longer triggered
          wait(stop_detection_e.triggered || start_detection_e.triggered);
          
          if(start_detection_e.triggered) phase.drop_objection(this); //continuous start only, stop already drops objection 
          if (thread_process[wait_for_thread_number].status != process::FINISHED) thread_process[wait_for_thread_number].kill();
        end
      join_any
      
      thread_number++; // increment the thread number for next threads spawning

    end
    
  join
  
endtask: run_phase

//------------------------------------------------------------------------//
// during reset, drive X to outputs to verify there isn't X propagation
// while reset is asserted. 
// This isn't being sent through a clocking block since the
// reset is asynchronous and there is no guarantee the clock is toggling
task i2c_slave_driver::drive_x_to_outputs_during_reset();
  
  @(negedge sigs.resetn);
  sigs.scl_out <= 'x;
  sigs.sda_out <= 'x;
  
  @(posedge sigs.resetn);
  sigs.scl_out <= 1'b1;
  sigs.sda_out <= 1'b1;
  
endtask:drive_x_to_outputs_during_reset

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_search_for_start_condition(uvm_phase phase);
  
  @(negedge sigs.drv_cb.sda_in);
  if (sigs.drv_cb.scl_in === 1'b1) begin
    ->start_detection_e;
    start_detection = 1'b1;
    phase.raise_objection(this);
    `uvm_info("DRV",  $sformatf("Start detected"), UVM_MEDIUM )
  end
  
endtask: slave_search_for_start_condition

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_search_for_stop_condition(uvm_phase phase);

  wait(sigs.drv_cb.sda_in !== 1'bx); // don't trigger from an X to 1 transition
  @(posedge sigs.drv_cb.sda_in);
  if (sigs.drv_cb.scl_in === 1'b1) begin
    ->stop_detection_e;
    `uvm_info("DRV",  $sformatf("Stop detected"), UVM_MEDIUM )
    if(start_detection) begin // verify a start was triggered before lowering the objection
      `uvm_info("DRV",  $sformatf("Start existed, drop objection"), UVM_DEBUG )
      start_detection = 1'b0;
      phase.drop_objection(this);
    end
  end
  
endtask: slave_search_for_stop_condition

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_address_is_to_this_slave(output logic address_is_for_salve);

  address               = '0;
  address_is_for_salve  =  0; 
  `uvm_info("DRV",  $sformatf("Beginning address identification"), UVM_MEDIUM )
  
  // get address
  for(int i = 0; i < cfg.address_num_of_bits; i++)begin
    @(posedge sigs.drv_cb.scl_in);
    address = { address[8:0], sigs.drv_cb.sda_in };
  end

  if (address === cfg.slave_address) address_is_for_salve = 1;

endtask: slave_address_is_to_this_slave

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_get_read_write(output e_i2c_direction transaction_direction);
  
  @(posedge sigs.drv_cb.scl_in);
  transaction_direction = e_i2c_direction'(sigs.drv_cb.sda_in);
  
endtask: slave_get_read_write

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_write_request();
  logic [7:0] input_data      = '0;
  int         num_of_accesses =  0;
  `uvm_info("DRV",  $sformatf("Slave write"), UVM_DEBUG )
  
  while(num_of_accesses <= cfg.max_write_word_access_before_nack) begin
    input_data = '0;
    for (int i = 0; i < 8; i++) begin
      @(posedge sigs.drv_cb.scl_in);
      input_data = { input_data[6:0], sigs.drv_cb.sda_in};
    end
    data[address++] = input_data;
    send_ack();
    num_of_accesses++;
  end
  
endtask: slave_write_request

//------------------------------------------------------------------------//
task i2c_slave_driver::slave_read_request();
  int       current_address   = this.address; // start of read address is the requested address on the i2c bus
  bit [7:0] data_to_transmit  = '0;
  bit       ack_from_master   = '0;
  `uvm_info("DRV",  $sformatf("Slave read"), UVM_DEBUG )
  
  do begin
    if (!data.exists(current_address)) begin
      data[current_address] = $urandom_range(1 << 8); // data values are byte wide
      `uvm_info("DRV",  $sformatf("Created a random value %0h for address %0h", data[current_address], current_address), UVM_HIGH )
    end
    
    data_to_transmit = data[current_address];
    `uvm_info("DRV",  $sformatf("transmitting read request data %0h", data_to_transmit), UVM_HIGH )
    
    //TX to master the data requested by the read request
    for (int i = 8; i; i--) begin
      sigs.drv_cb.sda_out <= data_to_transmit[i - 1];
      wait_for_scl_negedge_plus_n_cycles();
    end
    sigs.drv_cb.sda_out <= 1'b1; // done transmitting read request, release the SDA
    
    current_address++;
    wait_for_ack_from_master( .ack(ack_from_master) );
  end 
  while(ack_from_master);
  
endtask: slave_read_request

//------------------------------------------------------------------------//
task i2c_slave_driver::send_ack();
  wait_for_scl_negedge_plus_n_cycles();
  sigs.drv_cb.sda_out <= 1'b0;
  
  wait_for_scl_negedge_plus_n_cycles();
  sigs.drv_cb.sda_out <= 1'b1;
endtask: send_ack

//------------------------------------------------------------------------//
task i2c_slave_driver::wait_for_ack_from_master(output bit ack);
  @(posedge sigs.drv_cb.scl_in);
  ack = ~ (sigs.drv_cb.sda_in); // ack = 0, nack = 1
  `uvm_info("DRV",  $sformatf("received ACK from master %0h", sigs.drv_cb.sda_in), UVM_DEBUG )
  
  wait_for_scl_negedge_plus_n_cycles();
endtask: wait_for_ack_from_master

//------------------------------------------------------------------------//
task i2c_slave_driver::wait_for_scl_negedge_plus_n_cycles();
  @(negedge sigs.drv_cb.scl_in);
  repeat(cfg.wait_cycles_from_scl_negedge) @(sigs.drv_cb);
  
endtask: wait_for_scl_negedge_plus_n_cycles

`endif //I2C_SLAVE_DRIVER__SV

