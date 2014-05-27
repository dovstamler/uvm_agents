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
Agents are implemented in SystemVerilog using the UVM methodology. 

Cores highlights:
I2C: 
- Slave agent
- Supports 7 bit addressing
- Supports continuous start
- Agents sequence item encapsulates an entire transaction including
  multiple transmitted / received words for a single address request. 

Documentation: 
- References to integrating and modifying cores can be found in the 
  documentation provided. Please see the Cores_Documentation.html.

Release Notes:
- Release notes for each core can be found at: src/<core name>/release_notes.txt
