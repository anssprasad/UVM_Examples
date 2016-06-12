//------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
//   All Rights Reserved Worldwide
//   
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//   
//       http://www.apache.org/licenses/LICENSE-2.0
//   
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//------------------------------------------------------------

// TITLE: UVM Register Miscellaneous 

typedef string name_list_t[$];

function string uvm_print_name_list(
  string name, 
  name_list_t name_list);

  string str;

  $swrite(str, "%s -> ", name);
  foreach (name_list[s])
    $swrite(str, "%s '%s',", str, name_list[s]);
  return str;
endfunction

function automatic void 
  uvm_parse_path_name(output name_list_t l, input string path_name);

  string s;
  int path_name_len, start;

  // Find the first non-dot. It skips leading dots
  // - like the UNIX filesystem skipping leading slashes.
  path_name_len = path_name.len();
  for(int i = 0; i < path_name_len; i++)
    if (path_name[i] != ".") begin
      // Found the FIRST non-dot. Start the
      // path_name here and break out.
      path_name = path_name.substr(i, path_name_len-1);
      break;
    end

  if (path_name[0] == ".") begin
	// Must have been an entry like ".....". Error.
	uvm_report_error("PARSENAME", 
	  $psprintf("Error: Illegal name - '%s'", path_name)); 
    l.push_back("ILLEGAL NAME");
  end
  else begin
    // We are starting on a character that is NOT a dot.
    start = 0;
    path_name_len = path_name.len(); // Recalculate.
    for(int i = 0; i < path_name_len; i++)
      if (path_name[i] == ".") begin
        // Found a separator. Push onto the stack.
        s = path_name.substr(start, i-1);
        l.push_back(s);
        start = i+1; // Advance past the dot.
      end
  
    // Last part, after the last dot.
    s = path_name.substr(start, path_name.len()-1);
    l.push_back(s);
  end
endfunction
