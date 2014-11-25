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

This repository is directed to design verification engineers looking for
environment agents which can drive, respond and monitor a Design Under Test (DUT). 
Agents are implemented with the SystemVerilog 1800-2012 standard and the UVM methodology. 

Cores highlights:

- All cores were implemented with the UVM-1.1d framework.

I2C: 
- Master & slave agents.
- Compatible to the Philips standard. (http://www.nxp.com/documents/user_manual/UM10204.pdf)
- Agents Support 7 bit addressing & continuous start.
- Master agent additionally supports clock stretching and arbitration functionality. 
- Slave agent was tested against the I2C opencore RTL (http://opencores.org/project,i2c)

Wishbone:
- Master agent.
- Compatible to the Wishbone B3 standard. (http://cdn.opencores.org/downloads/wbspec_b3.pdf)
- Agent is parametrized to support configurable bus widths

Documentation: 
- References to integrating and modifying cores can be found in the 
  documentation provided. Please see the Cores_Documentation.html.

Release Notes:
- Release notes for each core can be found at: src/<core name>/release_notes.txt
