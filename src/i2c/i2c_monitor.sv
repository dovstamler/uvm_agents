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
 
`ifndef I2C_MONITOR__SV
`define I2C_MONITOR__SV

// Class: i2c_monitor
// Monitors the I2C SDA and SCL lines and outputs via an analysis
// port an <i2c_sequence_item>.
class i2c_monitor extends uvm_monitor;

  i2c_cfg                                 cfg;
	virtual i2c_if                          sigs;
	uvm_analysis_port #(i2c_sequence_item)  analysis_port;
  
  event start_detection_e;
  event stop_detection_e;
	
	`uvm_component_utils(i2c_monitor)
	
	extern         function      new(string name, uvm_component parent);
	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task          run_phase(uvm_phase phase);
  extern virtual task          search_for_start_condition();
  extern virtual task          search_for_stop_condition();

	endclass: i2c_monitor
	
//------------------------------------------------------------------------//
// function: new
// constructor
function i2c_monitor::new(string name, uvm_component parent);
  super.new(name, parent);

endfunction: new

//------------------------------------------------------------------------//
// function: build_phase
// build phase is called by UVM flow. Creates analysis port to output a sequence item for a
// monitored transaction. 
function void i2c_monitor::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  phase.raise_objection(this);
  
  if ( cfg  == null ) `uvm_fatal("DRV",  $sformatf("i2c cfg object is null!") )
  this.analysis_port = new("analysis_port", this);
  
  phase.drop_objection(this);
  
endfunction: build_phase

//------------------------------------------------------------------------//
// task: run_phase
// run phase is called by UVM flow. Monitor is active during this phase. 
task i2c_monitor::run_phase(uvm_phase phase);
  i2c_sequence_item s_item;
  logic [7:0]     data          = '0;
  logic           data_ack      = '0;
  int             thread_number = 0;
  process         thread_process[$];
  super.run_phase(phase);
  
  fork
    forever search_for_start_condition();
    forever search_for_stop_condition();
    
    forever begin
      fork
        begin
          thread_process[thread_number] = process::self(); 
          wait(start_detection_e.triggered);
          s_item = i2c_sequence_item::type_id::create("s_item", this);
          
          // address
          s_item.address = '0;
          for(int i = 0; i < cfg.address_num_of_bits; i++)begin
            @(posedge sigs.mon_cb.scl_in);
            s_item.address = { s_item.address[8:0], sigs.mon_cb.sda_in };
          end 
 
          // read / write bit
          @(posedge sigs.mon_cb.scl_in);
          s_item.direction_e = e_i2c_direction'(sigs.mon_cb.sda_in); // cast received value to sequence item field enum
          
          // continue only if current agent receives an ACK on the address.
          @(posedge sigs.mon_cb.scl_in);
          s_item.address_ack = sigs.mon_cb.sda_in;
          
          if (s_item.address_ack == 1'b0) begin // begin collecting data only if there was a slave response to the address
            while(data_ack === 1'b0) begin
              for (int i = 0; i < 8; i++) begin // data is always 8 bit
                @(posedge sigs.mon_cb.scl_in);
                data = { data[6:0], sigs.mon_cb.sda_in};
              end
              s_item.data.push_back(data);

              @(posedge sigs.mon_cb.scl_in);
              data_ack = sigs.mon_cb.sda_in;
            end
          end
        end
        
        begin // start event is detected, wait for stop or repeated start to end this thread.
          //grab the current thread number since the thread number can increment if the response thread terminates naturally
          int wait_for_thread_number = thread_number;
          wait(start_detection_e.triggered);
          #1; //wait so start event is no longer triggered
          wait(stop_detection_e.triggered || start_detection_e.triggered); // if a stop condition was given even in the middle of a transaction, stop the thread, the word has been lost
          if (thread_process[wait_for_thread_number].status != process::FINISHED) thread_process[wait_for_thread_number].kill();
        end
      join_any
      
      thread_number++; // increment the thread number for next thread spawning

      `uvm_info("MON",  $sformatf("%s", s_item.sprint() ), UVM_HIGH )
      analysis_port.write(s_item);
    end
  join
        
endtask: run_phase	

//------------------------------------------------------------------------//
task i2c_monitor::search_for_start_condition();
  
  @(negedge sigs.mon_cb.sda_in);
  if (sigs.mon_cb.scl_in === 1'b1) begin
    ->start_detection_e;
    `uvm_info("MON",  $sformatf("Start detected"), UVM_DEBUG )
  end
  
endtask: search_for_start_condition

//------------------------------------------------------------------------//
task i2c_monitor::search_for_stop_condition();
  
  wait(sigs.mon_cb.sda_in !== 1'bx); // don't trigger from an X to 1 transition
  @(posedge sigs.mon_cb.sda_in);
  if (sigs.mon_cb.scl_in === 1'b1) begin
    ->stop_detection_e;
    `uvm_info("MON",  $sformatf("Stop detected"), UVM_DEBUG )
  end
  
endtask: search_for_stop_condition

`endif //I2C_MONITOR__SV
