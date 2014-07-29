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

`ifndef I2C_MASTER_DRIVER__SV
`define I2C_MASTER_DRIVER__SV

// Class: i2c_master_driver
// Master driver begins driving an I2C transaction when an <i2c_sequence_item> is received from the 
// agents sequencer and the I2C bus is not busy. When the bus is busy, the driver will wait for the
// bus to release and then begin the transaction. The pin wiggles are a function
// of the current sequence item and the agents <i2c_master_cfg> objects members values. 
class i2c_master_driver extends uvm_driver #(i2c_sequence_item);
    `uvm_component_utils(i2c_master_driver)
        
    virtual i2c_if      sigs;
    i2c_master_cfg      cfg;
    i2c_common_methods  common_mthds;                         // object holding common methods used by multiple I2C components
    
    bit                 bus_is_busy;                          // set on a start detection, dropped on a stop detection
    bit                 stop_scl;                             // used to notify SCL thread to terminate
    bit                 abritration_current_drive_value;      // arbitration process uses this to compare current to bus value
    bit                 abritration_checking_enabled;         // only when driving the bus should the arbitration be checking
    event               start_detection_e;                    // triggered on a start detection
    event               stop_detection_e;                     // triggered on a stop detection
    
    // bus timing values represented in clocking block cycles
    int                 num_of_clocks_for_scl_high_period;    // calculated number of clock cycles for a SCL high period
    int                 num_of_clocks_for_scl_low_period;     // calculated number of clock cycles for a SCL low period
    int                 num_of_clocks_for_t_hd_sta_min;       // start hold time before SCL toggle
    int                 num_of_clocks_for_t_hd_dat_max;       // data hold time from SCL negedge
    int                 num_of_clocks_for_t_su_dat_min;       // data setup time to SCL posedge
    int                 num_of_clocks_for_t_su_sta_min;       // repeated start SDA toggle from SCL negedge
    int                 num_of_clocks_for_t_su_sto_min;       // setup time from SCL posedge to SDA assert
    int                 num_of_clocks_for_t_buf_min;          // buffer time between stop and start conditions
    
    extern function              new(string name = "i2c_master_driver", uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task          run_phase(uvm_phase phase); 
    extern virtual task          monitor_for_start_condition();
    extern virtual task          monitor_for_stop_condition();
    extern virtual task          report_if_bus_is_busy();
    extern virtual task          calculate_closest_scl_frequency_to_configuration();
    extern virtual task          calculate_all_bus_timing_variables_in_num_of_clocks();
    extern virtual task          drive_transaction();
    extern virtual task          toggle_scl();
    extern virtual task          create_start_condition(uvm_phase phase);
    extern virtual task          create_stop_condition(uvm_phase phase);
    extern virtual task          transmit_address();
    extern virtual task          get_slave_ack(output logic ack);
    extern virtual task          setup_for_a_continuous_start();
    extern virtual task          transmit_write_data();
    extern virtual task          receive_read_data();
    extern virtual task          transmit_ack_for_read(bit ack = 0);
    extern virtual task          drive_data_bit_to_sda(logic data_bit);
    extern virtual task          check_if_arbitration_is_lost(output logic arbitration_lost);
    
endclass: i2c_master_driver

//------------------------------------------------------------------------//
function i2c_master_driver::new(string name = "i2c_master_driver", uvm_component parent);
  super.new(name, parent);

endfunction: new

//------------------------------------------------------------------------//
function void i2c_master_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
        
  //set initial values
  bus_is_busy                     = 0; 
  abritration_current_drive_value = 0;
  abritration_checking_enabled    = 0;
  
  common_mthds = i2c_common_methods::type_id::create("common_mthds", this);
  common_mthds.sigs = sigs;
  
endfunction: build_phase

//------------------------------------------------------------------------//
// task: run_phase
// run phase is called by UVM flow. Driver is active during this phase.
task i2c_master_driver::run_phase(uvm_phase phase);
  process         thread_process[$];
  int             thread_number                               = 0;
  bit             drive_thread_check_if_arbitration_was_lost  = 0;
  super.run_phase(phase);
  
  common_mthds.calculate_input_clock_period();// set the clocking block period for the common_mthds object, must be done in the run_phase to guarantee clock is toggling
  calculate_all_bus_timing_variables_in_num_of_clocks();
  calculate_closest_scl_frequency_to_configuration();
  
  fork
    forever common_mthds.drive_x_to_outputs_during_reset();
    forever monitor_for_start_condition(); // used to verify if bus is free
    forever monitor_for_stop_condition();  // used to verify if bus is free
    forever report_if_bus_is_busy();
    
    forever begin
      fork
        begin // drive thread
          thread_process[thread_number] = process::self();
          
          if(drive_thread_check_if_arbitration_was_lost) drive_thread_check_if_arbitration_was_lost = 0; // use the previously item since it wasn't transmitted
          else                                           seq_item_port.get_next_item(req); //wait for a sequence item from the sequencer
          wait(!bus_is_busy);
          do begin
            
            create_start_condition( .phase(phase) );
            drive_transaction();
            req.print();
            
            seq_item_port.item_done();
            seq_item_port.try_next_item(req); // if another item is ready process it now, create a continuous start
          end
          while(req);
          
          create_stop_condition( .phase(phase) );
           
        end
        
        // termination thread. terminate the drive thread if arbitration is lost. 
        // terminate this thread once the drive thread has completed
        begin
          int wait_for_thread_number = thread_number;
          logic arbitration_lost = '0;
          
          
          while(!arbitration_lost && 
                (thread_process[wait_for_thread_number].status != process::FINISHED) ) check_if_arbitration_is_lost( .arbitration_lost(arbitration_lost) );
          
          if (thread_process[wait_for_thread_number].status != process::FINISHED) thread_process[wait_for_thread_number].kill();
          if (arbitration_lost) begin
            `uvm_info(get_type_name(),  $sformatf("arbitration has been lost"), UVM_NONE )
            drive_thread_check_if_arbitration_was_lost = 1; //notify the drive thread so the next round won't pull a new item from the sequencer
          end
        end
      
      join_any
      
      thread_number++;
      
    end
  join
  
endtask: run_phase

//------------------------------------------------------------------------//
// monitor if a different master created a start condition. This is used 
// to determine if the bus is busy.
task i2c_master_driver::monitor_for_start_condition();
  
  common_mthds.monitor_for_start_condition( .start_e(start_detection_e) );
  if(start_detection_e.triggered) `uvm_info(get_type_name(),  $sformatf("Start detected"), UVM_FULL )
    
endtask: monitor_for_start_condition

//------------------------------------------------------------------------//
// monitor if a different master created a stop condition. used to determine when the bus is clear.
task i2c_master_driver::monitor_for_stop_condition();
  
  common_mthds.monitor_for_stop_condition( .stop_e(stop_detection_e) );
  if(stop_detection_e.triggered) `uvm_info(get_type_name(),  $sformatf("Stop detected"), UVM_FULL )
  
endtask: monitor_for_stop_condition

//------------------------------------------------------------------------//
// raise bus_is_busy on a start condition, drop bus_is_busy on a stop condition. 
// bus is busy only after t_hd time. 
task i2c_master_driver::report_if_bus_is_busy();
  
  wait(start_detection_e.triggered);
  repeat(num_of_clocks_for_t_hd_sta_min) @(sigs.drv_cb);
  bus_is_busy = 1;
  `uvm_info(get_type_name(),  $sformatf("bus busy set"), UVM_FULL )

  wait(stop_detection_e.triggered);
  repeat(num_of_clocks_for_t_buf_min) @(sigs.drv_cb); // don't release the bus for the buffer time between a start and stop
  bus_is_busy = 0;
 `uvm_info(get_type_name(),  $sformatf("bus busy cleared"), UVM_FULL )
 
endtask: report_if_bus_is_busy

//------------------------------------------------------------------------//
// the requested SCL frequency is an exact number where the driver works with 
// a clocking block. calculate the closest frequency value to the requested SCL frequency in clock cycles.
task i2c_master_driver::calculate_closest_scl_frequency_to_configuration();
  int      num_of_input_clock_for_scl   = 0;
  realtime requested_period             = 0;
  
  requested_period = 1s / (1000 * cfg.requested_scl_frequency_in_khz); // convert from KHz to seconds
  num_of_input_clock_for_scl = common_mthds.calculate_number_of_clocks_for_time( .time_value(requested_period) );
  
  //set values used by SCL creation task, for an odd number of cycles, split the high and low period to different values
  if (num_of_input_clock_for_scl % 2) begin
    num_of_clocks_for_scl_high_period = (num_of_input_clock_for_scl - 1) /2;
    num_of_clocks_for_scl_low_period  = (num_of_input_clock_for_scl) /2;
  end
  else begin
    num_of_clocks_for_scl_high_period = (num_of_input_clock_for_scl) /2;
    num_of_clocks_for_scl_low_period  = (num_of_input_clock_for_scl) /2;
  end
  
  `uvm_info(get_type_name(),  $sformatf("SCL: number of clocks per period = %0d, closest period = %0t", num_of_input_clock_for_scl, num_of_input_clock_for_scl * common_mthds.input_clock_period_in_ps), UVM_MEDIUM )
  `uvm_info(get_type_name(),  $sformatf("SCL: closest frequency = %0d KHz", 1s/( 1000* num_of_input_clock_for_scl * common_mthds.input_clock_period_in_ps * 1ps) ), UVM_MEDIUM )
  
endtask: calculate_closest_scl_frequency_to_configuration

//------------------------------------------------------------------------//
// bus timing is represent in exact time value. driver drives bus with a clocking
// block therefore, calculate the closest times for each variable based on the 
// clocking block period.
// min values are not floored since then the requested value won't be met.
task i2c_master_driver::calculate_all_bus_timing_variables_in_num_of_clocks();

  num_of_clocks_for_t_hd_sta_min = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_hd_sta_min), .floor_calculation(0) );
  num_of_clocks_for_t_hd_dat_max = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_hd_dat_max), .floor_calculation(1) );
  num_of_clocks_for_t_su_dat_min = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_su_dat_min), .floor_calculation(0) );
  num_of_clocks_for_t_su_sta_min = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_su_sta_min), .floor_calculation(0) );
  num_of_clocks_for_t_su_sto_min = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_su_sto_min), .floor_calculation(0) );
  num_of_clocks_for_t_buf_min    = common_mthds.calculate_number_of_clocks_for_time( .time_value(cfg.t_buf_min),    .floor_calculation(0) );
  
  `uvm_info(get_type_name(),  $sformatf("num_of_clocks_for_t_hd_sta_min = %d", num_of_clocks_for_t_hd_sta_min) , UVM_FULL )
  `uvm_info(get_type_name(),  $sformatf("num_of_clocks_for_t_hd_dat_max = %d", num_of_clocks_for_t_hd_dat_max) , UVM_FULL )
  `uvm_info(get_type_name(),  $sformatf("num_of_clocks_for_t_su_dat_min = %d", num_of_clocks_for_t_su_dat_min) , UVM_FULL )
  `uvm_info(get_type_name(),  $sformatf("num_of_clocks_for_t_su_sta_min = %d", num_of_clocks_for_t_su_sta_min) , UVM_FULL )
  `uvm_info(get_type_name(),  $sformatf("num_of_clocks_for_t_su_sto_min = %d", num_of_clocks_for_t_su_sto_min) , UVM_FULL )
  `uvm_info(get_type_name(),  $sformatf("num_of_clocks_for_t_buf_min    = %d", num_of_clocks_for_t_buf_min) ,    UVM_FULL )

endtask:calculate_all_bus_timing_variables_in_num_of_clocks

//------------------------------------------------------------------------//
task i2c_master_driver::drive_transaction();
  logic ack = 1;
  stop_scl  = 0;
    
  `uvm_info(get_type_name(),  $sformatf("drive_transaction start"), UVM_FULL )
  
  fork // creating start condition has completed previously, begin SCL toggle
    toggle_scl();
  join_none
  
  transmit_address();
  get_slave_ack( .ack(ack) );
  if (ack === 1'b0) begin //0 = ACK, 1 = NACK
    case(req.direction_e)
      I2C_DIR_WRITE: transmit_write_data();
      I2C_DIR_READ:  receive_read_data();
      default:       `uvm_error(get_type_name(),  $sformatf("requested %s direction is not supported", req.direction_e.name() ) )
    endcase
  end
  
endtask: drive_transaction

//------------------------------------------------------------------------//
task i2c_master_driver::toggle_scl();
 `uvm_info(get_type_name(),  $sformatf("toggle_scl start"), UVM_NONE )
 
  @(sigs.drv_cb); //synchronize to current clock
  while(!stop_scl) begin 
    sigs.drv_cb.scl_out <= 1'b0;
    repeat(num_of_clocks_for_scl_low_period) @(sigs.drv_cb);
    
    sigs.drv_cb.scl_out <= 1'b1;
    wait(sigs.drv_cb.scl_in === 1'b1); // if the slave stretches the clock, wait for it to release
    repeat(num_of_clocks_for_scl_high_period) @(sigs.drv_cb);
  end
  
  stop_scl = 0;
  
  `uvm_info(get_type_name(),  $sformatf("toggle_scl end"), UVM_NONE )
endtask: toggle_scl

//------------------------------------------------------------------------//
task i2c_master_driver::create_start_condition(uvm_phase phase);
  `uvm_info(get_type_name(),  $sformatf("create_start_condition start"), UVM_FULL )
  
  if (bus_is_busy) setup_for_a_continuous_start(); 
  else             phase.raise_objection(this); // when grabbing the bus, raise objection
  
  if (sigs.drv_cb.scl_in !== 1'b1) `uvm_fatal(get_type_name(),  $sformatf("creating start condition but SCL is not high") )
  sigs.drv_cb.sda_out <= 1'b0;
  
  repeat(num_of_clocks_for_t_hd_sta_min) @(sigs.drv_cb);
  
  `uvm_info(get_type_name(),  $sformatf("create_start_condition end"), UVM_FULL )
endtask: create_start_condition

//------------------------------------------------------------------------//
task i2c_master_driver::create_stop_condition(uvm_phase phase);
  
  wait(sigs.drv_cb.scl_in === 1'b0);
  repeat(num_of_clocks_for_t_hd_dat_max) @(sigs.drv_cb);
  sigs.drv_cb.sda_out <= 1'b0; //prepare SDA to rise when clock is high
  
  wait(sigs.drv_cb.scl_in === 1'b1);
  repeat(num_of_clocks_for_t_su_sto_min) @(sigs.drv_cb);
  sigs.drv_cb.sda_out <= 1'b1;
  
  stop_scl = 1;
  
  repeat(num_of_clocks_for_t_buf_min) @(sigs.drv_cb);
  
  phase.drop_objection(this);
  
endtask: create_stop_condition

//------------------------------------------------------------------------//
task i2c_master_driver::transmit_address();
  
  for(int i = cfg.address_num_of_bits; i; i--) drive_data_bit_to_sda( .data_bit(req.address[i-1]) );
  drive_data_bit_to_sda( .data_bit( logic'(req.direction_e) ) );
  
endtask: transmit_address

//------------------------------------------------------------------------//
task i2c_master_driver::get_slave_ack(output logic ack);
  
  wait(sigs.drv_cb.scl_in === 1'b0); // wait for negedge where the slave drives the ack value
  wait(sigs.drv_cb.scl_in === 1'b1); // read the value when SCL is high
  ack = sigs.drv_cb.sda_in;
  
endtask:get_slave_ack

//------------------------------------------------------------------------//
task i2c_master_driver::setup_for_a_continuous_start();
  `uvm_info(get_type_name(),  $sformatf("setup_for_a_continuous_start start"), UVM_FULL )
  
  wait(sigs.drv_cb.scl_in === 1'b0);
  repeat(num_of_clocks_for_t_hd_dat_max) @(sigs.drv_cb);
  sigs.drv_cb.sda_out <= 1'b1; //prepare SDA to fall when clock is high
  
  stop_scl = 1; // SCL will be restarted after the continuous start is complete
  
  wait(sigs.drv_cb.scl_in === 1'b1);
  //repeat(num_of_clocks_for_scl_high_period) @(sigs.drv_cb); // TBD
  repeat(num_of_clocks_for_t_su_sta_min) @(sigs.drv_cb); //continuous start setup time
  
  `uvm_info(get_type_name(),  $sformatf("setup_for_a_continuous_start end"), UVM_FULL )
endtask: setup_for_a_continuous_start

//------------------------------------------------------------------------//
task i2c_master_driver::transmit_write_data();
  logic ack;
  
  for(int data_word = 0; data_word < req.data.size(); data_word++) begin
    // transmit current data word 1 bit at a time MSB to LSB, data is always 8 bit
    for(int i = 8; i ; i--)  drive_data_bit_to_sda( .data_bit(req.data[data_word][i-1]) ); 

    get_slave_ack( .ack(ack) ); // get the ack from the slave for each data word
    if (ack === 1'b1) break;    // received a NACK, stop transmitting data words
  end

endtask: transmit_write_data

//------------------------------------------------------------------------//
task i2c_master_driver::receive_read_data();
  int         number_of_read_words = req.data.size();
  logic [7:0] received_data        = '0;
  
  if (number_of_read_words === 0) `uvm_error(get_type_name(),  $sformatf("number_of_read_words = %0d", number_of_read_words) )
  req.data.delete(); //remove any data that exists so that only data received will be in the data queue
  
  for(int current_read_word = 0; current_read_word < number_of_read_words; current_read_word++) begin
    
    // if the master previously responded with an ACK, release the SDA line here for the next read word
    // so the slave won't be blocked for transmission. 
    if (sigs.drv_cb.sda_in === 1'b0) begin
      wait(sigs.drv_cb.scl_in === 1'b0);
      repeat(num_of_clocks_for_t_hd_dat_max) @(sigs.drv_cb);
      sigs.drv_cb.sda_out <= 1'b1;
    end
    
    // get data from slave
    for(int i = 8; i ; i--) begin
      wait(sigs.drv_cb.scl_in === 1'b0);
      wait(sigs.drv_cb.scl_in === 1'b1);
      req.data[current_read_word][i-1] = sigs.drv_cb.sda_in;
      `uvm_info(get_type_name(),  $sformatf("i = %0d, sigs.drv_cb.sda_in = %0h, req.data[%0d] = %0h", i, sigs.drv_cb.sda_in, current_read_word,req.data[current_read_word]), UVM_FULL )
    end
  
    if ( (current_read_word+1) !== number_of_read_words)  transmit_ack_for_read( .ack(0) );
    else                                                  transmit_ack_for_read( .ack(1) ); // last read word, return NACK
    
    `uvm_info(get_type_name(),  $sformatf("req.data[%0d] = %0h", current_read_word, req.data[current_read_word]), UVM_NONE )
  end
    
endtask: receive_read_data

//------------------------------------------------------------------------//
task i2c_master_driver::transmit_ack_for_read(bit ack = 0);
  drive_data_bit_to_sda( .data_bit(ack) );
endtask: transmit_ack_for_read

//------------------------------------------------------------------------//
// data is driven on the SDA only when the SCL is low and after the t_hd_dat.
// t_hd_dat moves the data transition from the SCL falling edge. 
task i2c_master_driver::drive_data_bit_to_sda(logic data_bit);
  abritration_checking_enabled = 1; // checking arbitration only when data is driven to the bus by the driver
  
  wait(sigs.drv_cb.scl_in === 1'b0);
  repeat(num_of_clocks_for_t_hd_dat_max) @(sigs.drv_cb);
  sigs.drv_cb.sda_out             <= data_bit;
  abritration_current_drive_value  = data_bit;
  wait(sigs.drv_cb.scl_in === 1'b1);
  
  abritration_checking_enabled = 0;
endtask: drive_data_bit_to_sda

//------------------------------------------------------------------------//
task i2c_master_driver::check_if_arbitration_is_lost(output logic arbitration_lost);
  arbitration_lost = '0;
  `uvm_info(get_type_name(),  $sformatf("check_if_arbitration_is_lost start"), UVM_FULL )
  
  wait(sigs.drv_cb.scl_in === 1'b0);
  wait(sigs.drv_cb.scl_in === 1'b1);
  if (abritration_checking_enabled) begin //arbitration is verified when SCL is high
    `uvm_info(get_type_name(),  $sformatf("sigs.drv_cb.sda_in = %0h, arbitration_current_drive_value = %0h", sigs.drv_cb.sda_in, abritration_current_drive_value), UVM_FULL )
    if(sigs.drv_cb.sda_in !== abritration_current_drive_value) arbitration_lost = 1'b1;
  end
  
endtask: check_if_arbitration_is_lost

`endif //I2C_MASTER_DRIVER__SV
