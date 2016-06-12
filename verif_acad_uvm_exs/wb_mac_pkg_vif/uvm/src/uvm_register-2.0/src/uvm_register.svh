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

// TITLE: UVM Register Base Classes
// The UVM Register Base classes reprent functionality
// for the fields, registers, register files and register maps. 

/* ************************************* *
 * UVM Register and Register Address Map *
 * ************************************* */

  // 32 bit addresses and offsets. 

  // Typedef : UVM_REGISTER_BIT_TYPE
  // The fundamental bit type - really just a 
  // SystemVerilog 'bit'.
  typedef bit unsigned UVM_REGISTER_BIT_TYPE;

  // Parameter : The length of the longest register.
  // Mostly used in error checking and the by name
  // routines.
  parameter int MAX_REGISTER_WIDTH = 64;

  // Typedef : A "maximially" sized bit vector.
  typedef bit   [MAX_REGISTER_WIDTH-1:0] BV;
  typedef logic [MAX_REGISTER_WIDTH-1:0] LV;

  // Typedef : Useful types
  typedef UVM_REGISTER_BIT_TYPE [31:0] bv32_t;
  typedef UVM_REGISTER_BIT_TYPE [63:0] bv64_t;
  typedef logic [31:0] lv32_t;
  typedef logic [63:0] lv64_t;

  // Convenient maximally sized constants.
  const BV BV_1 = '1;
  const BV BV_0 = '0;

  // Typedefs : offset_t, address_t
  // Used for addresses and offsets.
  typedef int unsigned offset_t;
  typedef int unsigned address_t;

  // Typedef : address_list_t
  // Used as the list of addresses for a register.
  typedef address_t address_list_t[$];

  // Typedef : address_range_list_t
`ifndef NCV
  typedef struct {
    address_t start_range, end_range;
  } address_range_t;
  typedef address_range_t address_range_list_t[$];
`else
  class address_range_t;
    address_t start_range, end_range;
  endclass
  class address_range_list_c;
    address_range_t LIST[$];
  endclass
  typedef address_range_list_c address_range_list_t;
`endif

  // Typedef : Used internally to set or get field 
  // values by name.
  typedef enum bit {
     UVM_REGISTER_FIELD_SET_BY_NAME, 
     UVM_REGISTER_FIELD_GET_BY_NAME
  } UVM_REGISTER_FIELD_ACCESS_T;

  // Typedef : bytearray_t
  // An unsized array of 8 bits, usually used to represent
  // an arbitrarily sized transfer (of bytes).
  typedef UVM_REGISTER_BIT_TYPE [7:0] bytearray_t[];

  // Forward declaration
  typedef class uvm_register_base;

  // Typedef : register_list_t
  // A list of registers; used for randomly accessing the 
  // registers in an address map.
  typedef uvm_register_base register_list_t[$];

//XXX_ ------------------------------
  class string_tree_c;
    string tree[string];
  endclass
  static string_tree_c NCV_string_forest[int];
  static int last_NCV_string_forest = 0;

  // Typedef : uvm_register_field_info_t
  // Definition of meta information about fields in 
  // a register.
`ifdef NCV
  // IUS does not currently (2/12/2010) support
  //  strings in a struct, nor class handles in a struct,
  //  nor an associative array of strings. When those
  //  are supported, a more sane implementation (see FUTURE, 
  //  above) will be supported. For now, a struct is 
  //  created which contains ints. Those ints are pointers 
  //  into string tables.
  //
  //  Knowing the integer you can get the string by doing:
  //     string_table[i].
  // Iname and Iaccess are such strings.
  // 
  // Itags is an integer which is used to index into
  // a table of "tag lists". Use the index to get the
  // correct list of tags:
  //     NCV_field_forest[Itags]
  //
  typedef struct {
    int Iname;
    BV resetValue;
    int Iaccess;
    int Itags; // An integer used to index 
               //  into the GLOBAL forest of 
               //  string trees.
    int nbits;
  } uvm_register_field_info_t;


  static uvm_register_field_info_t NCV_field_forest[1000]; 
  static int last_NCV_field_forest = 0;

  static string NCV_string_table[int];
  static int    NCV_string_table_index[string];
  static int    NCV_string_table_available_index = 0;

  function void string_table_dump();
    $display("Available index = %0d", 
      NCV_string_table_available_index);
    for (int i = 0; i < NCV_string_table_available_index; i++)
      $display("Index %4d = '%s'", i, NCV_string_table[i]);
  endfunction

  function int string_table_allocate(string name);
    if (NCV_string_table_index.exists(name) == 0) begin
      // This string hasn't ever been entered.
      // Create a new index.
      // The missing ELSE is that this string has already 
      // been entered and we're just going to reuse it....
      NCV_string_table_index[name] = 
        NCV_string_table_available_index++;
      NCV_string_table[NCV_string_table_index[name]] = name;
    end
    return NCV_string_table_index[name];
  endfunction

  function string string_table_fetch(int i);
    if (NCV_string_table.exists(i)) begin
      return NCV_string_table[i];
    end
    else begin
      uvm_report_fatal("field name lookup", 
        $psprintf("Index '%0d' does not exist", i));
      return "ILLEGAL_FIELD_NAME";
    end
  endfunction
`else
  /* 
   * "Field Descriptor"
   * Simple struct of (name, resetValue, access, tags, nbits).
   */
  typedef struct {
    string name;         // The name of the field.
    BV resetValue;       // The reset value of the field.
    string access;       // The "special" access of the field.
                         //  Ex: "RW", "RO", "RC".
    string tags[string]; // Arbitrary "tags" associated
                         //  with this field.
    int nbits;           // The number of bits in this field.
                         //  Used in checking.
  } uvm_register_field_info_t;
`endif

  // Typedef : field_list_t
  // A list of fields (from one register)
  //RICH typedef uvm_register_field_info_t field_list_t[$];

//XXX_ ------------------------------

  static string m_registers_using_constructor_args[string];

  function void show_register_deprecation_messages();
    // If are no messages, just return.
`ifdef NCV
    // SV 1800-2005
    if (m_registers_using_constructor_args.num() == 0)
      return;
`else
    // SV 1800-2009
    if (m_registers_using_constructor_args.size() == 0)
      return;
`endif // NCV

    uvm_report_info("ResetValueInConstructor", 
      $psprintf(
  "Some registers have reset values in the constructor."));
    foreach (m_registers_using_constructor_args[s]) 
      uvm_report_info("ResetValueInConstructor",
        $psprintf("  %s", s));
  endfunction


`ifdef NCV
  static string m_legal_masks[$];
  function bit init_m_legal_masks();
    m_legal_masks.push_back("RMASK");
    m_legal_masks.push_back("WMASK");
    m_legal_masks.push_back("RESETVALUE");
    m_legal_masks.push_back("W1CLRMASK");
    m_legal_masks.push_back("W0SETMASK");
    m_legal_masks.push_back("CLRONREAD");
    m_legal_masks.push_back("SETONREADMASK");
    return 1;
  endfunction
  static bit static_init_m_legal_masks = init_m_legal_masks();
`else
  static string m_legal_masks[$] = {
    "RMASK",
    "WMASK",
    "RESETVALUE",
    "W1CLRMASK",
    "W0SETMASK",
    "CLRONREAD",
    "SETONREADMASK"
  };
`endif

`ifdef NCV
  static string m_legal_access_policies[$];
  function bit init_m_legal_access_policies();
    m_legal_access_policies.push_back("RW");
    m_legal_access_policies.push_back("RO");
    m_legal_access_policies.push_back("WO");
    m_legal_access_policies.push_back("W1C");
    m_legal_access_policies.push_back("RW1C" );
    m_legal_access_policies.push_back("W0S");
    m_legal_access_policies.push_back("RW0S" );
    m_legal_access_policies.push_back("R2C");
    m_legal_access_policies.push_back("RC");
    m_legal_access_policies.push_back("RCW");
    m_legal_access_policies.push_back("R2S");
    m_legal_access_policies.push_back("RS");
    m_legal_access_policies.push_back("RSW");
    return 1;
  endfunction
  static bit static_init_m_legal_access_policies = 
    init_m_legal_access_policies();
`else
    static string m_legal_access_policies[$] = {
        "RW",
        "RO",
        "WO",
        "W1C", "RW1C" ,
        "W0S", "RW0S" ,
        "R2C", "RC", "RCW",
        "R2S", "RS", "RSW"
    };
`endif

  /*
   * CLASS: uvm_register_base
   *
   * Base class for registers. This class contains access
   * functions and utilities for accessing registers using
   * a base class handle.
   */
  virtual class uvm_register_base extends uvm_named_object;

    protected bit m_isMemory = 0;

    function bit isMemory();
      return m_isMemory;
    endfunction

    // Variable: register_name
    // The name of the register; a simple string usually.
    // Like "regA" or "r102"
    protected string register_name;

    // Variable: register_type
    // The type of the register; an optional field.
    string register_type;

    // Variable: register_attribute
    // Optional field.
    string register_attribute;

    // Full HDL path name to the register.
    // Given a name, the user must figure out how to
    // retrieve the DUT register value, without
    // bus cycles or other time consuming behavior.
    // Note : This HDL path is not yet used.
    protected string dut_register_name;
    protected bit    backdoor_on;

    protected chandle dut_register_handle;

    // Field Utilities
    // List of all the fields. Indexed by the field name.

//XXX_ ------------------------------
    
`ifdef NCV
    int fields[string]; 

    function uvm_register_field_info_t get_field(
        string field_name);
      int forest_index;
      forest_index = fields[field_name];
      return NCV_field_forest[forest_index];
    endfunction

    function string get_field_name(int i);
      uvm_register_field_info_t f;
      f = NCV_field_forest[i]; 
      return string_table_fetch(f.Iname);
    endfunction
`else
    uvm_register_field_info_t fields[string]; 
`endif

//XXX_ ------------------------------

    //Future: TODO
    // Find a different macro implementation
    // which implements a create() call which 
    // does NOT call new.
    /*
    `uvm_object_utils_begin(uvm_register_base)
      `uvm_field_string(register_name,      UVM_ALL_ON)
      `uvm_field_string(register_type,      UVM_ALL_ON)
      `uvm_field_string(register_attribute, UVM_ALL_ON)
    `uvm_object_utils_end
    */

    function void connect();
      // Normally (always?) a register has no connect()
      // functionality, and this implementation will
      // be used.
    endfunction

    // Private helper routine to generate a unique name
    local function string m_check_name(string l_name);
      // If name is not provided, create one.
      if (( l_name == "" ) ) begin
        // Unnamed. Generate a name.
        l_name = generate_name();
      end
      // Set register_name attribute.
      //set_name(l_name);
      return l_name;
    endfunction

    // Function: new()
    //
    // Construct a register base class, providing a name and
    // a parent.
    function new(string l_name = "", 
        uvm_named_object p = null);
      //super.new(m_check_name(l_name), p);
      super.new(l_name, p);
      m_set_full_name();
    endfunction

    // Function: build()
    // Match the UVM engine
    virtual function void build();
    endfunction

    // Function: build_maps()
    // 
    virtual function void build_maps();
    endfunction

// Group: Field Access By Name

    // Function: find_field
    // Given a name, return the field info structure 
    // for that field.
    virtual function uvm_register_field_info_t 
      find_field(string name);

      uvm_register_field_info_t f;
      if (fields.exists(name))
`ifdef NCV
        f = NCV_field_forest[fields[name]];
`else
        f = fields[name];
`endif
      return f;
    endfunction

`ifdef RICH
    // Function: find_fields_with_tag
    // Given a tag name, return ALL the fields for 
    // this register that have that tag.
    virtual function void 
      find_fields_with_tag(output field_list_t field_list, 
        string tag_name);

      foreach (fields[i])
        //RICH - Works in QUESTA.
        //  if ( fields[i].tags.exists(tag_name) )
        //    field_list.push_back(fields[i]);
        if (field_has_tag(field_name, tag_name))
          field_list.push_back(NCV_field_forest[fields[i]]);
    endfunction
`endif

    // Function: has_field
    // Given a name, return 1, if this is a name of a 
    // field in this register. Return 0 otherwise.
    virtual function bit has_field(string name);
      if (fields.exists(name))
        return 1;
      else
        return 0;
    endfunction

    // Function: has_tag
    // Given a name, return 1, if any field has this tag
    // in this register. Return 0 otherwise.
    virtual function bit has_tag(string tag_name);
      foreach (fields[i])
`ifdef NCV
        if (NCV_string_forest[
              NCV_field_forest[
                fields[i]].Itags].tree.exists(tag_name))
`else
        if (fields[i].tags.exists(tag_name))
`endif
          return 1;
      return 0;
    endfunction

`ifdef RICH
    virtual function bit field_has_tag(
      string field_name, 
      string tag_name);

      string name;
      foreach (fields[i]) begin
`ifdef NCV
        if (field_name == name)
          if (NCV_string_forest[
               NCV_field_forest[
                fields[i]].Itags].tree.exists(tag_name))
`else
        //XXX_RICH name = get_field_name(i);
`endif
            return 1;
      end
      return 0;
    endfunction
`endif

    // Function: add_field_tag
    // Given a field name, add the tag to the list 
    // of tags for this field.
    virtual function void 
      add_field_tag(string name, string tag);

      if (!is_field_defined(name, "add_field_tag"))
        return;
`ifdef NCV
      NCV_string_forest[
        NCV_field_forest[fields[name]].Itags].tree[tag] = tag;
`else
      fields[name].tags[tag] = tag;
`endif
    endfunction

    // Function: add_field
    // Define a new field. Provide the name, the reset 
    // value and the access policy. See also: 
    // set_access_policy_field_by_name()
    //
    // Where "access" is one of:
    //    "RW"               Read-Write
    //    "RO"               Read-only
    //    "WO"               Write-only
    //    "W1C", "RW1C"      Write-1-to-Clear
    //    "W0S", "RW0S"      Write-0-to-Set
    //    "R2C", "RC", "RCW" Clear-on-Read 
    //    "R2S", "RS", "RSW" Set-on-Read 
    virtual function void add_field(
        string name, BV resetValue, string access);

      uvm_register_field_info_t f;

      if (fields.exists(name)) begin
`ifdef NCV
        uvm_report_error("field_by_name", $psprintf(
          "Field '%s.%s' is already defined", 
          get_full_name(), name));
`else
        uvm_report_error("field_by_name", $psprintf(
          "Field '%s.%s' is already defined as %p", 
          get_full_name(), name, fields[name]));
`endif
        return;
      end

      // Assert: field 'name' doesn't exist yet.

      //----------------------------------------------------
      // Setup the NAME field in the Field Descriptor.
      //----------------------------------------------------
`ifdef NCV
      // Make a new tag tree.
      f.Itags = last_NCV_string_forest++; 
      NCV_string_forest[f.Itags] = new();

      f.Iname = string_table_allocate(name);
      begin
        string tname;
        tname = string_table_fetch(f.Iname);
        if (tname != name) begin
          string_table_dump();
          uvm_report_fatal("NameCheck", 
            $psprintf("Orig = '%s'", name));
          uvm_report_fatal("NameCheck", 
            $psprintf(" New = '%s'", tname));
        end
      end
`else
      f.name = name;             // Populate the field info db
`endif

      //----------------------------------------------------
      // Setup the RESETVALUE field in the Field Descriptor.
      //----------------------------------------------------
      f.resetValue = resetValue; 
                                 // Assign the field reset 
                                 //    value.
                                 // - used later to populate
                                 //   the register reset value

      //----------------------------------------------------
      // Setup the ACCESS field in the Field Descriptor.
      //----------------------------------------------------
`ifdef NCV
      f.Iaccess = string_table_allocate(access);
`else
      f.access = access;         // Assign the access.
                                 // - used later to populate 
                                 //   the register mask values
`endif

      //----------------------------------------------------
      // Put the new Field Descriptor into a "by-name" lookup
      // array.
      //----------------------------------------------------
`ifdef NCV
      if (last_NCV_field_forest > 1000) begin
        // Sigh. 1000 fields is enough. We should
        // improve this check/algorithm, but there are
        // 3 alternatives:
        //  1. Just use Questa.
        //  2. Edit this library and change the 1000 to a
        //     larger limit.
        //  3. NCV supports arrays of structs.
        uvm_report_fatal("NCVCOMPAT", 
          $psprintf("%s has too many fields. (>1000)",
            get_full_name()));
      end
      fields[name] = last_NCV_field_forest++;
      NCV_field_forest[fields[name]] = f; 
`else
      fields[name] = f;          // Put this field_info in 
                                 //  the db, indexed by name
`endif

      //----------------------------------------------------
      // By default, each field gets a tag of the field name.
      //----------------------------------------------------
      add_field_tag(name, name); // Fancy. Add a tag of the
                                 // same name as the field.


      //----------------------------------------------------
      // At this point the field descriptor is setup.
      //----------------------------------------------------

      m_check_field_by_name(name);   // Double check.
      set_access_policy_field_by_name(name, access);
    endfunction

    // Function: is_field_defined
    // Like has_field, but spit out an error if not defined.
    virtual function bit 
      is_field_defined(string name, string msg = "");

      if (fields.exists(name))
        return 1;
      else begin
        uvm_report_error("field_by_name",
          $psprintf("%s - Field '%s' does not exist. [%s]", 
          get_full_name(), name, msg));
        return 0;
      end
    endfunction

`ifdef NCV
    function string struct_to_string(string s);
      uvm_register_field_info_t f;

      f = NCV_field_forest[fields[s]];
      return $psprintf(
        "Name='%s', ResetValue='%0b', Access='%s', Nbits=%0d",
        string_table_fetch(f.Iname),
        f.resetValue,
        string_table_fetch(f.Iaccess),
        f.nbits);
    endfunction
`endif

    // Function: print_fields
    // Dump the field info structure for all the fields.
    // Most useful in debug.
    virtual function void print_fields();
      uvm_report_info("REG", 
        $psprintf("Register %s", get_full_name()));
      foreach (fields[s]) begin
`ifdef NCV
        uvm_report_info("REG", 
          $psprintf("  Field %s", struct_to_string(s)));
        foreach ( NCV_string_forest[
            NCV_field_forest[fields[s]].Itags].tree[t])
          uvm_report_info("REG", $psprintf("    tag %s", t));
`else
        uvm_report_info("REG", 
          $psprintf("  Field %p", fields[s]));
        foreach (fields[s].tags[t])
          uvm_report_info("REG", $psprintf("    tag %s", t));
`endif
      end
    endfunction

    // Defined by te XML2SV generator, or the user, or ...
    // If you EVER want to use the "...field_by_name()" 
    // functions, then you must define this function in 
    // the user register definition file. 
    /*pure*/ virtual function BV m_register_field_by_name(
      UVM_REGISTER_FIELD_ACCESS_T cmd, 
      string name, BV x, BV v = 0);
      uvm_report_error("m_register_field_by_name", 
"Function m_register_field_by_name() has not been defined.");
      return 0;
    endfunction

    // Function: m_poke_field_by_name
    // Provide a current value, passed in as 'x'. 
    // Provide a new value, passed in as 'v'. 
    // Provide the name of the field in 'name'.
    // The FULL bit vector value, 'x', will be treated
    // like a packed struct, and then the named field
    // within the bit vector (packed struct) will be
    // assigned the new value, 'v'.
    // Note - Returns the WHOLE Bit-vector, not 
    // simply the field value.
    virtual function BV m_poke_field_by_name(
        string name, BV x, BV v);
      return m_register_field_by_name(
        UVM_REGISTER_FIELD_SET_BY_NAME, name, x, v);
    endfunction

    // Function: m_peek_field_by_name
    // Provide a current value, passed in as 'x'. 
    // Provide the name of the field in 'name'.
    // The FULL bit vector value, 'x', will be treated
    // like a packed struct, and then the named field
    // within the bit vector (packed struct) will be
    // returned.
    // Note - Returns the FIELD value only (not the 
    // whole Bit-vector).
    virtual function BV m_peek_field_by_name(
        string name, BV x);
      return m_register_field_by_name(
        UVM_REGISTER_FIELD_GET_BY_NAME, name, x);
    endfunction
            
    // Function: m_check_field_by_name
    // Check to make sure the field as defined can hold the
    // defined reset value.
    virtual function void m_check_field_by_name(string name);
      uvm_register_field_info_t f = find_field(name);
      int nbits_bv;
      int nbits_local;
      BV field_v = '1;
      BV register_value;

      // Question 1: How many bits are there in this field?
      field_v = m_peek_field_by_name(name, BV_1);
`ifdef NCV
      NCV_field_forest[fields[name]].nbits = $countones(field_v);
`else
      fields[name].nbits = $countones(field_v);
`endif

      // Question 2: Can this field fit in the max size 
      //  BV defined?
      nbits_bv = $bits(BV);

`ifdef NCV
      nbits_local = NCV_field_forest[fields[name]].nbits;
`else
      nbits_local = fields[name].nbits;
`endif

      if ( ( nbits_local == 0) || 
           (nbits_bv < nbits_local) ) begin
        uvm_report_error("field_by_name", 
          $psprintf("Field '%s.%s' is wider (%0d bits) than the",
            get_full_name(), name, nbits_local));
        uvm_report_info("field_by_name", $psprintf(
          " largest defined bit-vector (%0d bits)", nbits_bv));
        uvm_report_info("field_by_name", $psprintf(
          "       Recompile the library with a wider"));
        uvm_report_info("field_by_name", $psprintf(
          " bit-vector defined."));
      end

      // Question 3: What's the maximum this field can hold?
      register_value = BV_0;
      register_value = 
        m_poke_field_by_name(name, register_value, 
          f.resetValue);
      field_v = m_peek_field_by_name(name, register_value);
      if ( field_v != f.resetValue ) begin
        uvm_report_error("field_by_name", $psprintf(
          "Field '%s.%s' cannot hold the value ",
            get_full_name(), name));
        uvm_report_error("field_by_name", $psprintf(
          "'%0x' in %0d bits.",
            f.resetValue, nbits_local));
        uvm_report_error("field_by_name", $psprintf(
          "       Truncating resetValue for %s.%s to %0x",
            get_full_name(), name, field_v));

`ifdef NCV
         NCV_field_forest[fields[name]].resetValue = field_v;
`else
         fields[name].resetValue = field_v;
`endif
      end

      // Set the reset value.
      set_MASK_field_by_name("RESETVALUE", name, 
        f.resetValue);
    endfunction

    /*pure*/ virtual function 
      BV   peek_field_by_name( string name);
        uvm_report_error("peek_field_by_name", 
"Function peek_field_by_name() has not been defined.");
        return 0;
      endfunction
    /*pure*/ virtual function 
      void poke_field_by_name( string name, BV v);
        uvm_report_error("poke_field_by_name", 
"Function poke_field_by_name() has not been defined.");
      endfunction
    /*pure*/ virtual function 
      BV   read_field_by_name( string name);
        uvm_report_error("read_field_by_name", 
"Function read_field_by_name() has not been defined.");
        return 0;
      endfunction
    /*pure*/ virtual function 
      void write_field_by_name(string name, BV v);
        uvm_report_error("write_field_by_name", 
"Function write_field_by_name() has not been defined.");
      endfunction

    /*pure*/ virtual function 
      void set_MASK_field_by_name(string mask_name, 
        string name, BV v);
        uvm_report_error("set_MASK_field_by_name", 
"Function set_MASK_field_by_name() has not been defined.");
      endfunction
    /*pure*/ virtual function 
      void set_access_policy_field_by_name( 
        string name, string access);
        uvm_report_error("set_access_policy_field_by_name", 
"Function set_access_policy_field_by_name() has not been defined.");
      endfunction

    /*pure*/ virtual function 
      void reset_field_by_name(string name);
        uvm_report_error("reset_field_by_name", 
"Function reset_field_by_name() has not been defined.");
      endfunction
    /*pure*/ virtual function 
      void reset_field_by_name_with_tag(string tag_name);
        uvm_report_error("reset_field_by_name", 
"Function reset_field_by_name() has not been defined.");
      endfunction

`ifdef NOT_DEFINED
    /*pure*/ virtual function bit compare_by_name();
    /*pure*/ virtual function void print_by_name();
`endif

    virtual function void build_ap(
      uvm_named_object container);
      // Usually (always?) implemented in the derived class.
      uvm_report_info("uvm_register_base", 
        "build_ap() not implemented");
    endfunction

    virtual function string generate_name();
      string s;
      $sformat(s, "_R%0d", named_object_id);
      return s;
    endfunction

    virtual function void set_dut_register_name(
        string new_dut_register_name);
      dut_register_name = new_dut_register_name;
    endfunction

    virtual function string get_dut_register_name();
      return dut_register_name;
    endfunction

    virtual function bit get_backdoor_on();
      return backdoor_on;
    endfunction

    virtual function void set_backdoor_on();
      backdoor_on = 1;
    endfunction

    virtual function void set_backdoor_off();
      backdoor_on = 0;
    endfunction

    // Function backdoor_write()
    // Write the argument to the named location, 
    // using a DPI/PLI routime. Only call the
    // DPI/PLI routine if the flag backdoor_on is
    // set to non-zero.
    // TODO: Use BUS_WIDTH or array of bytes (and put this
    //       in the extended class).
    virtual function void backdoor_write(LV v);
      uvm_report_info("BACKDOOR", 
        $psprintf("Writing %x to register %s, HDL_PATH='%s'",
          v, get_full_name(), get_dut_register_name()));
      uvm_register_set_hdl(dut_register_name, v);
    endfunction

    // Function backdoor_read()
    // TODO: Use BUS_WIDTH or array of bytes (and put this
    //       in the extended class).
    virtual function void backdoor_read(output LV v);
      uvm_report_info("BACKDOOR", 
        $psprintf("Reading from register %s, HDL_PATH='%s'",
          get_full_name(), get_dut_register_name()));

      uvm_register_get_hdl(dut_register_name, v);

      uvm_report_info("BACKDOOR", 
        $psprintf("  ...got %x from '%s'",
          v, get_dut_register_name()));
    endfunction

// Group: Naming and Structure

    // Function: get_full_name()
    // Return the full pathname of the register. 
    //  ie. top.i2.apb.d2.reg3
    virtual function string deprecated_get_full_name();
      string s;
      if (m_parent == null)
        $sformat(s, "%s.%s", 
          "<UNNAMED-CONTAINER>", register_name);
      else
        $sformat(s, "%s.%s", 
          m_parent.get_full_name(), get_name());
      return s;
    endfunction

    //DEPRECATED. Use get_full_name()
    virtual function string get_fullname();
      return get_full_name();
    endfunction

    // Function: get_name()
    // Return the short name for the register, like "REG1".
    //virtual function string get_name();
      //return register_name;
    //endfunction

    // Function: set_name()
    // Set the short name for the register, like "REG1".
    // This function is mostly used when using the factory,
    // since the factory create() call will call the
    // register constructor as new() - since a register
    // is a transaction.
    // Overrides uvm_object::set_name()
    virtual function void xxx_set_name(string name);
      register_name = name;
    endfunction

    // Function: convert2string()
    // Should be implemented in the extended class.
    // Return a pretty string representing the register.
    virtual function string convert2string();
      uvm_report_error("uvm_register_base", 
        "convert2string() not implemented");
        return "convert2string() not implemented";
    endfunction

    // Function: get_container()
    // DEPRECATED: Just use get_parent().
    //
    // Return the uvm_named_object that "contains" this 
    // register. This is similar to 'parent', but not 
    // strictly enforced.
    virtual function uvm_named_object get_container();
      return get_parent();
    endfunction

     // Function: get_num_bits()
     // Return the number of bits this register contains.
     virtual function int get_num_bits();
      uvm_report_error("uvm_register", 
        "get_num_bits() not implemented");
       return 0;
     endfunction

// Group: Data Access

    // Function: poke_data32()
    // Set the data value as a raw 32 bit vector.
    virtual function void poke_data32( lv32_t bv);
      uvm_report_error("uvm_register", 
        "poke_data32() not implemented");
    endfunction

    // Function: peek_data32()
    // Return the data value as a raw 32 bit vector.
    virtual function lv32_t peek_data32();
      uvm_report_error("uvm_register", 
        "peek_data32() not implemented");
      return 0;
    endfunction

    // Function: poke_data64()
    // Set the data value as a raw 64 bit vector.
    virtual function void poke_data64( lv64_t bv);
      uvm_report_error("uvm_register", 
        "poke_data64() not implemented");
    endfunction

    // Function: peek_data64()
    // Return the data value as a raw 64 bit vector.
    virtual function lv64_t peek_data64();
      uvm_report_error("uvm_register", 
        "peek_data64() not implemented");
      return 0;
    endfunction

    // Function: read_data32()
    // Calls read_data32() in the extended class.
    virtual function lv32_t read_data32();
      uvm_report_error("uvm_register", 
        "read_data32() not implemented");
      return 0;
    endfunction
    
    // Function: write_data32()
    // Calls write_data32() in the extended class.
    virtual function void write_data32(lv32_t bv);
      uvm_report_error("uvm_register", 
        "write_data32() not implemented");
    endfunction
    
    // Function: read_data64()
    // Calls read_data64() in the extended class.
    virtual function lv64_t read_data64();
      uvm_report_error("uvm_register", 
        "read_data64() not implemented");
      return 0;
    endfunction
    
    // Function: write_data64()
    // Calls write_data64() in the extended class.
    virtual function void write_data64(lv64_t bv);
      uvm_report_error("uvm_register", 
        "write_data64() not implemented");
    endfunction
    
// Group: Data Access (DEPRECATED)

    // Function: set_data32()
    // DEPRECATED. Use poke_data32();
    virtual function void set_data32( lv32_t bv);
      poke_data32(bv);
    endfunction

    // Function: get_data32()
    // DEPRECATED. Use peek_data32();
    virtual function lv32_t get_data32();
      return peek_data32();
    endfunction

    // Function: set_data64()
    // DEPRECATED. Use poke_data64();
    virtual function void set_data64( lv64_t bv);
      poke_data64(bv);
    endfunction

    // Function: get_data64()
    // DEPRECATED. Use peek_data64();
    virtual function lv64_t get_data64();
      return peek_data64();
    endfunction

// Group: Shadow checking routines (sized bit vector) 

    // Function: bus_read32()
    // Must be implemented in the extended class.
    pure virtual function void bus_read32( 
        input bv32_t read_data_bv,
        address_t address = 0);

    // Function: bus_write32()
    // Must be implemented in the extended class.
    pure virtual function void bus_write32( 
        input bv32_t write_data_bv );

    // Function: bus_read()
    // Must be implemented in the extended class.
    pure virtual function void bus_read( 
      input bytearray_t read_data,
      address_t address = 0);

    // Function: bus_write()
    // Must be implemented in the extended class.
    pure virtual function void bus_write( 
      input bytearray_t write_data );

    // Function: set_byte_array()
    // Return the data value as a list of bytes. 
    virtual function void set_byte_array(input bytearray_t i);
      uvm_report_error("uvm_register", 
        "set_byte_array() not implemented");
    endfunction

    // Function: get_byte_array()
    // Return the data value as a list of bytes. 
    // Note : Return value is through the parameter list.
    virtual function void get_byte_array(ref bytearray_t o);
      uvm_report_error("uvm_register", 
        "get_byte_array() not implemented");
    endfunction

    // Function: get_byte_array_no_masking()
    // Return the data value as a list of bytes. 
    // Note : Return value is through the parameter list.
    virtual function void get_byte_array_no_masking(
        ref bytearray_t o);
      uvm_report_error("uvm_register", 
        "get_byte_array_no_masking() not implemented");
    endfunction

    virtual function void peek_bytes(
        output bytearray_t ba,
        input address_t address, int nbytes = 0);
      // For the degenerate case of a register, ignore 
      // the address and nbytes, and just return the 
      // data as bytes.
      // This code is more usually called from a memory.
      get_byte_array(ba);
    endfunction

    virtual function void poke_bytes(
        address_t address, bytearray_t new_data);
      // For the degenerate case of a register, ignore 
      // the address, and just set the data as bytes.
      // This code is more usually called from a memory.
      set_byte_array(new_data);
    endfunction


// Group: Coverage

     // Function: sample()
     // Should be implemented in the extended class. The
     // implementation will usually call the covergroup 
     // sample function.
     virtual function void sample();
        uvm_report_error("uvm_register", 
          "sample() not implemented");
     endfunction

     // DEPRECATED. Use sample() instead.
     virtual function void do_cover(); 
        // Temporary placeholder. Use sample().
        sample();
     endfunction

    // Function: reset()
    // Should be implemented in the extended class.
    // Causes the register to take the resetValue.
    virtual function void reset();
      uvm_report_error("uvm_register", 
        "reset() not implemented");
    endfunction

    virtual function void set_start_range(address_t offset);
    endfunction

    virtual function void set_end_range(address_t offset);
    endfunction

    virtual function address_t get_start_range();
      return 0;
    endfunction

    virtual function address_t get_end_range();
      return 0;
    endfunction

  endclass


  /*
   * CLASS: uvm_register
   *
   * The register class that a user build registers from. 
   * This is a parameterized class which should be 
   * parameterized with a packed struct or bit vector 
   * which represents the register.
   *
   * For example,
   *   typedef packed struct {
   *     bit a[1:0];
   *     bit b[7:0];
   *   } r1_t;
   *
   *   class r1 extends uvm_register#(r1_t);
   *    ...
   *   endclass
   */
  class uvm_register #(type T = int)
      extends uvm_register_base;

    typedef uvm_register #(T) this_type;
    typedef UVM_REGISTER_BIT_TYPE[$bits(T)-1:0] bitvector_t;

    // Bit vector of length 8, 16, 24, etc. 
    //  Must be a multiple of 8.
    typedef UVM_REGISTER_BIT_TYPE
      [((($bits(T)+7)/8)*8)-1:0] bitvector_full_width_t;

    // ----------------------------------
    // Start of Class Member Variables.

    // Variable: data
    // The register data. The actual value stored in the 
    // register.
    rand T data;

    // Variable: resetValue
    // The reset value. This is the value of the 
    // register after reset() is called.
    T resetValue;

    // Variable: previous_data
    // The previous value of the register.
    T previous_data;

    // Group: Bit masks for permission.

    // These are the "well-defined" masks. They
    // describe "permission" (as opposed to behavior).
    // Default is all bits are readable and writable.

    // Variable: RMASK
    // This bit mask defines bits that are readable. If a bit
    // is a 1, then the bit in the register is readable. 
    // If it is a 0, then it is not readable.
    T RMASK = '1;         // Default: All bits readable.

    // Variable: WMASK
    // This bit mask defines bits that are writable. If a bit
    // is a 1, then the bit in the register is writable. 
    // If it is a 0, then it is not writable.
    T WMASK = '1;         // Default: All bits writable.

    // Variable: UNPREDICTABLE
    // This bit mask is used as an additional compare mask.
    // If a bit is 1 in this mask, then that bit is 
    // "unpredictable". If the bit is 0, then it is 
    // "predictable". A bit which is unpredictible will NOT
    // be compared in the compare_data() function. That
    // unpredictable bit will be ignored.
    T UNPREDICTABLEMASK = '0; // Default: All bits are 
                              //  predictable.

    // W0MASK - DEPRECATED use W0SETMASK
    T W0MASK = '1;
    // W1MASK - DEPRECATED use W1CLRMASK
    T W1MASK = '1;

    // Group: Bit masks for behavior.

    // These are the "well-defined" actions. 
    // They describe "behavior".
    // Variable: CLRONREAD
    // This bit mask defines bits that when read, they are 
    // cleared.
    // If a bit is a 1, then the it in the register is 
    // cleared when it is read. 
    // If the bit is a 0, then nothing special happens.
    // Default = 0 (nothing special happens)
    T CLRONREAD = '0;     // Set to ZERO on READ
                          // Clear-on-Read
                          // Default: off - no clear on read.
                          // Should really be named 
                          //  CLRONREADMASK,
                          //  but for backward compatability,
                          //  we leave it as CLRONREAD
  
    T SETONREADMASK = '0; // Set to ONE on READ
                          // Set-on-Read
                          // Default: off - no set on read.
  
    T W0SETMASK     = '0; // Write-Zero-to-Set
                          //  (writing a zero writes a 1)
                          // Default: off
  
    T W1CLRMASK     = '0; // Write-One-to-Clear
                          //  (writing a one writes a 0)
                          // Default: off

    // Variable: compare_read_only_bits
    // If set, then READ-ONLY bits are included in
    // compare operations. If NOT set, then READ-ONLY bits
    // are not included in compare operations.
    bit compare_read_only_bits = 0; // Default: Do NOT compare
                                    //  read-only bits

    // Variable: compareMask
    // This bit mask is used to define bits that should not 
    // participate in a comparison. 
    // If a bit is 1, then this bit from the register 
    // should be compared. 
    // If a bit is 0, then this bit from the register
    // should not be compared.  
    // Default = 1 (compare all bits from the register)
    T compareMask = '1;// Compare all bits.


    // Assign to NULL when there is NO indirection.
    // Assign to some register handle (another instance
    // of this type), when you want to have two registers
    // that have different masks or behaviors.
    local this_type m_actual_register = null;

    // End of Class Member Variables.
    // ----------------------------------

    // Function: set_actual_register
    // Setup the special mirroring code.
    // This assignment causes peek(), poke() and sample()
    // to be re-directed in this register to the register
    // pointed to by 's'. See peek(), poke() and sample()
    // implementations below.
    function void set_actual_register(this_type s);
      if (!$cast(m_actual_register, s)) begin
        uvm_report_error("set_actual_register()",
          $psprintf(
            "The type of '%s' and '%s' are not compatible.",
            get_full_name(), s.get_full_name()));
      end
    endfunction

    function this_type get_actual_register();
      return m_actual_register;
    endfunction

// Group: UVM Register semaphore

    // An UVM Register semaphore, with the same
    // interfaces and semantics as the built-in
    // SystemVerilog semaphore.
    //
    // If you want restricted access to this register,
    // then you should lock it. The library code
    // will not lock it for you - you should do something 
    // like:
    //
    //  Call get() and put() directly.
    //
    //   function test1();
    //     r.get();
    //       /* Enter locked region */
    //       r.write(...);
    //       r.read(...);
    //       r.bus_read32(...);
    //       /* Exit locked region */
    //     r.put();
    //   endfunction
    //
    //   function test2();
    //     r.get();
    //       /* Enter locked region */
    //       r.write(...);
    //       r.read(...);
    //       r.bus_read32(...);
    //       /* Exit locked region */
    //     r.put();
    //   endfunction
    //
    // Notice that these two tests (test1 and test2) are
    // "cooperating" with the locks. If some other test is
    // written, like test3, the locking scheme is broken:
    // 
    //   function test3();
    //     // No locking!
    //       r.write(...);
    //   endfunction
    //
    // TODO: Add check in poke() to check that only the locker
    //       can change the value. This is enforcement of 
    //       the lock, as opposed to a cooperative locking 
    //       scheme, enforced at a higher level. But how do 
    //       we tell who has the lock? Per-process? 
    //       uvm_named_object container?  secret id or password?
    //
    protected semaphore lock;
    // process who_has_this_register_locked;

    // Function: put()
    // Unlock the lock, by "putting back" n keys. 
    // put() can be passed an argument, n for the number of
    // keys, but usually no argument is passed, and the 
    // default of 1 is used.
    // put() is a function and cannot block. The lock
    // will have the number of keys added back to it.
    function void put(int n = 1);
      lock.put(n);
    endfunction

    // Task: get()
    // Lock the lock, by "getting" n keys.
    // If there are NOT enough keys available,
    // then this task will not return (it blocks)
    // until there are enough keys available.
    // get() can be passed an argument, n for the number of
    // keys, but usually no argument is passed, and 
    // the default of 1 is used.
    task get(int n = 1);
      lock.get(n);
    endtask

    // Function: try_get()
    // Like get() above, but if the lock would fail (block),
    // then a zero is returned instead of actually blocking.
    // In the failure case, no keys are "gotten" and a 0
    // is returned.
    // If there are enough keys - if the get() would not
    // block, n keys will be gotten and a 1 returned.
    // try_get() can be passed an argument, n for the 
    // number of keys, but usually no argument is passed, 
    // and the default of 1 is used.
    function int try_get(int n = 1);
      return lock.try_get(n);
    endfunction

    `uvm_object_param_utils_begin(uvm_register#(T))
      `uvm_field_int(data,       UVM_ALL_ON)
      `uvm_field_int(resetValue, UVM_ALL_ON)
    `uvm_object_utils_end

    // Function: get_num_bits()
    // Return the number of bits in this type.
    virtual function int get_num_bits();
      return $bits(T);
    endfunction

    // Function: check_width()
    // Convenience function that makes sure
    // the width you supply (n) will fit into
    // the space of the data.
    local function void check_width(string place, int n);
      if ($bits(T) > n) begin
        uvm_report_error(place, 
           $psprintf(
"%s: Data type is %0d bits wide. Too wide for %0d bits",
           get_full_name(), $bits(T), n));
      end
    endfunction

// Group: Field By Name Access

    // Function: m_register_field_by_name
    // This code is NOT implemented in a library base
    // class. This code is implemented in the user's
    // extended class. This implementation is here
    // in case the user did not implement the by
    // name code, and will never use it. In that case,
    // this function will never be called. If it ever is
    // called, then it is an error.

    // If you remove this implementation, then the extended
    // user class MUST implement it. A compile-time error
    // will occur if he forgets.
    virtual function BV m_register_field_by_name(
        UVM_REGISTER_FIELD_ACCESS_T cmd, 
        string name, BV x, BV v = 0);
      uvm_report_error("m_register_field_by_name", 
"Function m_register_field_by_name() has not been defined.");
      return 0;
    endfunction


    // Function: set_MASK_field_by_name
    // Given a mask name and a field name, set the field to 
    // value v in that mask.
    virtual function void set_MASK_field_by_name(
        string mask_name, string name, BV v);
      case (mask_name)
        "RMASK":         // Read Mask
         RMASK = m_poke_field_by_name(name, RMASK, v);

        "WMASK":         // Write Mask
         WMASK = m_poke_field_by_name(name, WMASK, v);

        "RESETVALUE":    // The Reset Value (not a mask)
    resetValue = m_poke_field_by_name(name, resetValue, v);

        "W1CLRMASK":     // Write-1-to-Clear Mask
     W1CLRMASK = m_poke_field_by_name(name, W1CLRMASK, v);

        "W0SETMASK":     // Write-0-to-Set Mask
      W0SETMASK = m_poke_field_by_name(name, W0SETMASK, v);

        "CLRONREAD":     // Clear-on-Read Mask
     CLRONREAD = m_poke_field_by_name(name, CLRONREAD, v);

        "SETONREADMASK": // Set-on-Read Mask
 SETONREADMASK = m_poke_field_by_name(name, SETONREADMASK, v);

        default: begin
          uvm_report_error("set_MASK_field_by_name", 
            $psprintf("Mask (%s) cannot be reset by name",
              mask_name));
          uvm_report_info("set_MASK_field_by_name", 
              "Legal masks are:");
          foreach (m_legal_masks[i])
            uvm_report_info("set_MASK_field_by_name", 
              $psprintf("  \"%s\"", m_legal_masks[i]));
        end
      endcase
    endfunction

/* From rgm_1.1, Section 1.3.12 "Access policies"

  o  RW - default access policy, act as basic 
          write or read access. This access policy 
          is allowed in fields that have RW access mode.

  o  RO - act as basic read access. This access 
          policy is allowed in fields that have RO 
          access mode.

  o  WO - act as basic write access. This access 
          policy is allowed in fields that have WO 
          access mode.

  o  RC - Read of this field will clear all of its 
          bits to 0. This access policy is allowed 
          only in fields that have RO access mode.
  o  RCW - Read of this field will clear all of its 
          bits to 0. This access policy is allowed 
          only in fields that have RW access mode.

  o  RS - Read of this field will be followed by set. 
          The rest of the field's bits remain unchanged.
          This access policy is allowed only in fields 
          that have RO access mode.
  o  RSW - Read of this field will be followed by set. 
          The rest of the field's bits remain unchanged.
          This access policy is allowed only in fields 
          that have RW access mode.

  o  RW1C - Write 1 to a bit will clear it to 0. This 
          access policy is allowed only in fields that 
          have RW access mode.

  o  RW1S - Write 1 to a bit will be followed by set. 
          The rest of the field's bits remain 
          unchanged. This access policy is allowed 
          only in fields that have RW access mode.

  o RSVD - This access policy should be used to set a 
          reserved field. by default the parser will 
          fill any gap between a user defined fields 
          with this access policy. A reserved field 
          considered as RO access mode field. 
*/

    // Function: set_access_policy_field_by_name
    // Given an "access policy", interrpret it into
    // the proper mask settings.
    virtual function void set_access_policy_field_by_name(
        string name, string access);
      case (access)
        "RW": begin // Read-Write
          set_MASK_field_by_name("RMASK", name, BV_1);
          set_MASK_field_by_name("WMASK", name, BV_1);
        end
        "RO": begin // Read-only
          set_MASK_field_by_name("RMASK", name, BV_1);
          set_MASK_field_by_name("WMASK", name, BV_0);
        end
        "WO": begin // Write-only
          set_MASK_field_by_name("RMASK", name, BV_0);
          set_MASK_field_by_name("WMASK", name, BV_1);
        end
        "W1C", "RW1C" : begin // Write-1-to-Clear
          set_MASK_field_by_name("W1CLRMASK", name, BV_1);
        end
        "W0S", "RW0S" : begin // Write-0-to-Set
          set_MASK_field_by_name("W0SETMASK", name, BV_1);
        end
        "R2C", "RC", "RCW": begin // Clear-on-Read 
          // Do we need differentiation of RC and RCW?
          // RCW is the normal mode, and RC is
          // when a field is marked RO. But the current
          // implementation already behaves correctly
          // when RC and RCW are considered equivalent.
          set_MASK_field_by_name("CLRONREAD", name, BV_1);
        end
        "R2S", "RS", "RSW": begin // Set-on-Read 
          // Do we need differentiation of RS and RSW?
          // See discussion above.
          set_MASK_field_by_name("SETONREADMASK", name, BV_1);
        end
        default: begin
          uvm_report_error("set_access_policy", 
           $psprintf("%s.%s access policy '%s' is not legal.",
            get_full_name(), name, access));

          uvm_report_info("set_access_policy",
            "Legal Access Policies are:");
          foreach (m_legal_access_policies[i])
            uvm_report_info("set_access_policy", 
              $psprintf("  \"%s\"", 
                m_legal_access_policies[i]));

          uvm_report_info("set_access_policy",
    "Setting access policy to unreadable and unwriteable.");
          set_MASK_field_by_name("RMASK", name, BV_0);
          set_MASK_field_by_name("WMASK", name, BV_0);
        end
      endcase
    endfunction
 
    // Function: peek_field_by_name
    // User callable function to return the value of
    // a field.
    virtual function BV peek_field_by_name(string name);
      if (!is_field_defined(name, "peek_field_by_name"))
        return 0;
      return m_peek_field_by_name(name, peek());
    endfunction

    // Function: poke_field_by_name
    // User callable function to set the value of
    // a field.
    virtual function void 
        poke_field_by_name(string name, BV v);
      if (!is_field_defined(name, "poke_field_by_name"))
        return;
      poke(m_poke_field_by_name(name, peek(), v));
    endfunction

    // Function: read_field_by_name
    // User callable function to return the value of
    // a field.
    virtual function BV read_field_by_name(string name);
      T local_mask;
      if (!is_field_defined(name, "read_field_by_name"))
        return 0;
      //TODO: Trigger side-effects and notifications.
      // Need a mask to only trigger this field.
      //return m_peek_field_by_name(calc_read(peek()), name);
      local_mask = BV_0;
      local_mask = 
        m_poke_field_by_name(name, local_mask, BV_1);
      return m_peek_field_by_name(name, read(local_mask));
    endfunction

    // Function: write_field_by_name
    // User callable function to set the value of
    // a field.
    virtual function void 
        write_field_by_name(string name, BV v);
      T local_mask;
      if (!is_field_defined(name, "write_field_by_name"))
        return;
      local_mask = BV_0;
      local_mask = 
        m_poke_field_by_name(name, local_mask, BV_1);

      //TODO: Trigger side-effects and notifications.
      // TODO: calc_write?
      // TODO: l_mask?
      //T new_v;
      //new_v = m_poke_field_by_name(peek(), name, v);
      //poke_field_by_name(name, 
        //m_peek_field_by_name(calc_write(peek(), 
        //   new_v, local_mask), name));

      write(m_poke_field_by_name(name, peek(), v), 
        local_mask);
    endfunction

    // Function: reset_field_by_name
    // User callable function to reset a field by name
    virtual function void reset_field_by_name(string name);
      if (!is_field_defined(name, "reset_field_by_name"))
        return;
      poke_field_by_name(name, 
        m_peek_field_by_name(name, resetValue));
    endfunction

    // FUNCTION: reset_field_by_name_with_tag()
    // User callable function to reset a field which has
    // the given tag name.
    virtual function void reset_field_by_name_with_tag(
        string tag_name);
`ifdef RICH 
      field_list_t list_of_fields_with_tag;

      // Find the fields with this tag and reset them.
      find_fields_with_tag(list_of_fields_with_tag, tag_name);
      //XXX_ foreach (list_of_fields_with_tag[i])
        //XXX_ reset_field_by_name(list_of_fields_with_tag[i].XXX_name);
`endif
    endfunction

    // Function: peek_data32()
    // Check to make sure the register can return at 
    // least 32 bits. Then return 32 bits.
    // Returns the RAW value.
    virtual function lv32_t peek_data32();
      check_width("peek_data32()", 32);
      return peek();
    endfunction

    // Function: poke_data32()
    // First check to make sure that there are at least 
    // 32 bits, then call poke() to assign data.
    virtual function void poke_data32(lv32_t bv);
       check_width("poke_data32()", 32);
       poke(bv);
    endfunction

    // Function: peek_data64()
    // Check to make sure the register can return at 
    // least 64 bits. Then return 64 bits.
    // Returns the RAW value.
    virtual function lv64_t peek_data64();
      check_width("peek_data64()", 64);
      return peek();
    endfunction

    // Function: poke_data64()
    // First check to make sure that there are at least 
    // 64 bits, then call poke() to assign data.
    virtual function void poke_data64(lv64_t bv);
      check_width("poke_data64()", 64);
      poke(bv);
    endfunction

    // Function: read_data32()
    // Returns the masked value. Not the RAW value.
    virtual function lv32_t read_data32();
      check_width("read_data32()", 32);
      return read();
    endfunction
    
    // Function: write_data32()
    // Writes the masked value. Not the RAW value.
    virtual function void write_data32(lv32_t bv);
      check_width("write_data32()", 32);
      write(bv);
    endfunction

    // Function: read_data64()
    // Returns the masked value. Not the RAW value.
    virtual function lv64_t read_data64();
      check_width("read_data64()", 64);
      return read();
    endfunction
    
    // Function: write_data64()
    // Writes the masked value. Not the RAW value.
    virtual function void write_data64(lv64_t bv);
      check_width("write_data64()", 64);
      write(bv);
    endfunction

    protected function void dump_bytes(
        string msg, 
        input bytearray_t i);
      // How many bytes are in the bit stream?
      int number_of_bytes = ($bits(T)+7)/8;

`ifdef NCV
      uvm_report_info("dump_bytes()", 
        $psprintf("(Byte) %s: Beginning. val = %0x", msg, i[0]));
`else
      uvm_report_info("dump_bytes()", 
        $psprintf("(Byte) %s: Beginning. val = %p", msg, i));
`endif

      // Print all the bytes from the array of bytes.
      for(int byte_num = 0; 
          byte_num < number_of_bytes; byte_num++) begin

        uvm_report_info("dump_bytes()", 
          $psprintf("    Byte#%0d = %b", 
            byte_num, i[byte_num]));
      end
    endfunction

    // Group: Shadow checking routines (Type specific vector)

    // Function: bus_read_bv()
    // This function is called when a "READ" transaction 
    // is detected. When this function executes, it first 
    // checks the data passed in with the current value 
    // in the shadow. If the data matches, then the new 
    // data is written to the shadow, just in case there 
    // are side-effects or other field behavior. This write
    // to the shadow is updating the shadow with the 
    // currently read value from the real register.
    // After the compare, if the data didn't match, then 
    // an error message is issued.
    // Before the routine returns, it issues a 
    // "register read()" call, which is a trick to have 
    // the shadow register publish itself on the
    // read analysis ports. This is done for any monitor 
    // that might be monitoring the register and wants 
    // to keep track of reads.
    virtual function void bus_read_bv( 
        input T read_data_bv,
        address_t address = 0);

      if (compare_data(read_data_bv)) begin
        // Compare OK.
        // TODO: Always do the update, even if compare fails.
        write_without_notify(read_data_bv);
      end
      else begin
        // TODO: Should we return 0/1 for fail/pass, 
        //       and let the caller decide what to do? 
        //       Helps with memory compare.
        //       The memory code can print the failing 
        //       address.
        //
        // Error. Data doesn't match.
        // TODO: Printing data should be convert2string()
        //       or do_print() or ...
        // Produce the "backup" information as INFO.
        // Then produce ONE error message.
        uvm_report_info("bus_read_bv()", $psprintf(
          "   bus_read_bv(%x) (bus value - actual),",
           read_data_bv));
        uvm_report_info("bus_read_bv()", $psprintf(
          "   register = (%x) (shadow value - expected).",
           data)); 
`ifdef NCV
        uvm_report_error("bus_read_bv()", $psprintf( 
          "Register (%s) mismatch. Address=%0x, val=(%s).", 
            get_fullname(), address, convert2string())); 
`else
        uvm_report_error("bus_read_bv()", $psprintf( 
          "Register (%s) mismatch. Address=%0x, val=(%p).", 
            get_fullname(), address, data)); 
`endif
      end
      // Always issue a "fake read", we don't use the
      //   read results, but we want to TRIGGER
      //   the read_ap.write(). We want to notify any 
      //   monitors that want to be notified on a read().
      void'(read());
    endfunction

    // Function: bus_write_bv()
    // This function is called when a "WRITE" transaction 
    // is detected. When this function executes, it 
    // simply 'writes' the new value to the shadow.
    virtual function void bus_write_bv( 
        input T write_data_bv );
      // trigger the analysis ports and do the masking.
      write(write_data_bv);
    endfunction

    // Group: Shadow checking routines (sized bit vector)

    // Function: bus_read32()
    // First check to make sure that there are at least 32 
    // bits, then call bus_read_bv() to do the real work.
    virtual function void bus_read32( 
        input bv32_t read_data_bv,
        address_t address = 0);
      check_width("bus_read32()", 32);
      bus_read_bv(read_data_bv, address);
    endfunction

    // Function: bus_write32()
    // First check to make sure that there are at least 
    // 32 bits, then call bus_write_bv() to do the real work.
    virtual function void bus_write32( 
        input bv32_t write_data_bv );
      check_width("bus_write32()", 32);
      bus_write_bv(write_data_bv);
    endfunction

    // Function: bus_read()
    // An alias for bus_read_bv() which takes an array 
    // of bytes as input.
    virtual function void bus_read( 
        input bytearray_t read_data,
        address_t address = 0);
      bitvector_t bv;
      convert2bitvector(read_data, bv);
      bus_read_bv(bv, address);
    endfunction

    // Function: bus_write()
    // An alias for bus_write_bv() which takes an array 
    // of bytes as input.
    virtual function void bus_write( 
        input bytearray_t write_data);
      bitvector_t l_data;
      convert2bitvector(write_data, l_data);
      bus_write_bv(l_data);
    endfunction

    // convert2bitvector()
    // Helper function.
    //TODO: Check odd-size (7?) registers.
    function void convert2bitvector(
        input bytearray_t i, 
        ref bitvector_t o);
      // Reverse is needed because we expect the
      // bytes in the order [0], [1], [2], [3] ...
      // but the bitvector is [31:0]
`ifdef NCV
      for (int k=0; k<=i.size(); k++)
        for (int j=0; j<7; j++) 
          o[k*8+j] = i[k][j];
`else
      i.reverse();
      o = bitvector_full_width_t'(i);
`endif
    endfunction

    // convert2bytearray()
    // Helper function.
    function void convert2bytearray(
        ref bitvector_t i, 
        ref bytearray_t o);
`ifdef NCV
      int nbytes;
      nbytes = ($bits(i)+7)/8;
      o = new[nbytes];
      for (int k=0; k<=nbytes; k++)
        for (int j=0; j<7; j++)
          o[k][j]  = i[k*8+j];
`else
      o = bytearray_t'(bitvector_full_width_t'(i));
      o.reverse();
`endif
    endfunction

    // Function: set_byte_array()
    // This is an alias for bus_write(). 
    virtual function void set_byte_array(input bytearray_t i);
      bus_write(i);
    endfunction

    // Function: get_byte_array()
    // This is an alias for read(). 
    virtual function void get_byte_array(ref bytearray_t o);
      bitvector_t m_data;
      // trigger the analysis ports and do the masking.
      m_data = read();
      convert2bytearray(m_data, o); 
    endfunction

    // Function: get_byte_array_no_masking()
    // This is an alias for get_dataN(). 
    virtual function void get_byte_array_no_masking(
        ref bytearray_t o);
      bitvector_t m_data;
      m_data = peek(); 
      convert2bytearray(m_data, o); 
    endfunction

    // GROUP: Ports for notification

    // Useful flags for debug.
    bit register_written;
    bit register_read;

    // Ports: read_ap, write_ap
    // Type specific notification to any 
    //   type specific subscriber.
    uvm_analysis_port #(this_type) read_ap;
    uvm_analysis_port #(this_type) write_ap;

    // Ports: generic_read_ap, generic_write_ap
    // General notification - register is type-less 
    //  (uvm_register_base type).
    uvm_analysis_port #(uvm_register_base) generic_read_ap;
    uvm_analysis_port #(uvm_register_base) generic_write_ap;

    // In extended class, write contraints here.
    // constraint {
    //   ....
    // }
    constraint register_builtin {
    }

    // In extended class, write coverage here.
    // covergroup {
    //   ....
    // }

    //TODO: - Don't need this anymore.
    //TODO: - change to make a unique name in the
    //             uvm_named_object_top.
    //
    // create_name()
    // Simple routine to find a unique name in the TOP. 
    //
    // Always generates a unique name of the form 
    //   <name>_<NNNN>
    //
    // If <name> already exists in TOP, then it tries
    // <name>_<NNNN> and repeats until the name is NOT
    // a duplicate.
    //
    local function string create_name(string name);
      string l_new_name;
      int id = $urandom; // Start from some random place.

      // First just try the name we want. 
      // If it works we're good.
      l_new_name = name;

      // Turn off the unhelpful (in this case) messages
      // from the UVM. When we can't find something in
      // this case, it is GOOD news. We don't want
      // the UVM issuing a WARNING message.
      uvm_top.set_report_id_action("Lookup Error", UVM_NO_ACTION);

      while (uvm_named_object_top.lookup(l_new_name) != null) 
      begin
        // This name already exists. Generate a new one.
        // Try the name = "name_NNNN".
        $sformat(l_new_name, "%s_%0d", name, id++);
      end

      // Probably more correct is to save the current
      // setting above, and then restore it here.
      uvm_top.set_report_id_action("Lookup Error", UVM_WARNING);

      // When we exit the while loop, we have a name that
      // doesn't already exist in the named_component.
      return l_new_name;
    endfunction

    // Function: build_ap()
    // Construct the analysis ports. This code is separate 
    // because there are occasions where the analysis ports 
    // are not needed.
    // Note: container is NOT used.
    function void build_ap(uvm_named_object container = null);

      if ( read_ap == null )
        read_ap = new( 
          create_name({get_full_name(), ".", 
            "read_ap"}), null/*m_parent*/);

      if ( write_ap == null )
        write_ap = new( 
          create_name({get_full_name(), ".", 
            "write_ap"}), null/*m_parent*/);

      if ( generic_read_ap == null )
        generic_read_ap  = new( 
          create_name({get_full_name(), ".", 
            "generic_read_ap"}), null/*m_parent*/);

      if ( generic_write_ap == null )
        generic_write_ap = new( 
          create_name({get_full_name(), ".", 
            "generic_write_ap"}), null/*m_parent*/);
    endfunction

    // GROUP: Construction and reset

    // Function: new()
    // Construct the register, given a name, a parent and 
    // a reset value. The name is normally a full path 
    // name of the parent combined with a short name for 
    // the register : { p.get_full_name(), "reg1" }
    // The parent can be NULL, in which case no analysis 
    // ports will be created.
    function new(string l_name = "registerName", 
        uvm_named_object p = null, T l_resetVal = 0);

      static int resetValue_deprecation_warning_issued = 0;

      super.new(l_name, p);

      if ( $bits(T) > $bits(BV) ) begin
        uvm_report_error("Register",
        $psprintf(
          "Register '%s' is wider (%0d bits)",
            get_full_name(), $bits(T)));
        uvm_report_info("Register",
        $psprintf(" than the bit-vector defined (%0d bits)",
            $bits(BV)));
        uvm_report_fatal("Register",
        $psprintf(
"  Recompile the library with a larger bit-vector size."));
        // $fatal();
      end

      lock = new(1);

      if (l_resetVal != 0) begin
        // Issue deprecation warning.
        if (!resetValue_deprecation_warning_issued) begin
          // Only issue one warning.
          resetValue_deprecation_warning_issued++;
          uvm_report_info("ResetValueInConstructor",
$psprintf("Register %s sets a reset value in the constructor argument",
           get_full_name()));
        end
        begin
          string s = get_full_name();
          m_registers_using_constructor_args[s] = s;
        end
      end
      resetValue = l_resetVal;
      register_written = 0;
      register_read = 0;
    endfunction

    // Function: reset()
    // Set the value of the register to the reset value.
    // Use poke(), so that all masks and behavior are
    // bypassed. No notification is performed.
    virtual function void reset();
      poke(resetValue);
    endfunction

    // Function: set_reset_value()
    // Use this function to set the default reset value.
    // TODO: Move into base class (using bit vector)
    // TODO: Allow for N types of reset. (soft and hard)
    virtual function void set_reset_value(T resetValue);
      this.resetValue = resetValue;
    endfunction

    // GROUP: Data Access functions (masked behavior)

    // Function: calc_read()
    // Calculate the new value, based on the old value, the
    // local mask, and the register masks.
    virtual function T calc_read(
        T current_value, 
        output T new_register_value, 
        input T local_mask = '1);

      T l_data;
      l_data = current_value & RMASK;
      new_register_value = 
        (current_value & ~CLRONREAD) | SETONREADMASK;
      return l_data; 
    endfunction

    // Function: calc_write()
    // Calculate the new value, based on the old value, 
    // the new value, the local mask, and the register masks.
    virtual function T calc_write(
        T current_value, T new_value, T local_mask = '1);

      T calculated_value;
      /*
       * #1: If W0 is set, then create 1's where there 
       *     are zeros.
       * #2: If W1 is SET, then create 0's where there 
       *     are ones.
       * #3: Only change the bits we can write.
       * #4: Keep the old value, if not writable.
       */
        calculated_value = 
          ((((~new_value &  W0SETMASK) |               // #1
             ( new_value & ~W1CLRMASK)))               // #2
             & (WMASK&local_mask))                     // #3
             | (current_value & ~(WMASK&local_mask));  // #4

      return calculated_value;
    endfunction

    // Function: read_without_notify()
    // Read the masked data without notify. This function 
    // can be overridden by extended registers to 
    // implement new behaviors.
    virtual function T read_without_notify(T local_mask = '1);
      T l_data, new_register_value;

      register_read = 1;
      l_data = 
        calc_read(peek(), new_register_value, local_mask);

      // The new_register_value is usually the same as the old
      // register value, so this poke() may not be necessary 
      // in cases where CLR or SET behaviors are NOT used.
      poke(new_register_value);

      return l_data; 
    endfunction

    // Function: write_without_notify()
    // Write masked data without notify. This function can 
    // be overridden by extended registers to implement 
    // new behaviors.
    virtual function void write_without_notify(T v, 
        T local_mask = '1);
      T data_copy;
      if (get_backdoor_on())
        backdoor_write(v);
      poke(calc_write(peek(), v, local_mask));
      register_written = 1;
    endfunction


    // Function: read()
    // Read masked data with notify.
    virtual function T read(T local_mask = '1);
      // Notify BEFORE read.
      if (read_ap != null)
        read_ap.write(this);
      if (generic_read_ap != null)
        generic_read_ap.write(this);
      return read_without_notify(local_mask);
    endfunction

    // Function: write()
    // Write masked data with notify.
    virtual function void write(T v, T local_mask = '1);
      write_without_notify(v, local_mask);
      // Notify AFTER write.
      if (write_ap != null)
        write_ap.write(this);
      if (generic_write_ap != null)
        generic_write_ap.write(this);
    endfunction

    // GROUP: Data Access functions (RAW value)

    // Function: poke()
    // "Raw" interface to write data. No masking or 
    // notification is performed.
    virtual function void poke(T v);
      if (m_actual_register!=null)
        m_actual_register.poke(v);
      else begin
        previous_data = peek();
        data = v;
      end
    endfunction

    // Function: peek()
    // "Raw" interface to read data. No masking or 
    // notification is performed.
    virtual function T peek();
      if (m_actual_register!=null)
        return m_actual_register.peek();
      else
        return data;
    endfunction

    // GROUP: Copy and clone

    function void copy(this_type t);
      register_name = t.register_name;

      data          = t.data;
      previous_data = t.previous_data;
      resetValue    = t.resetValue;

      RMASK = t.RMASK;
      WMASK = t.WMASK;
      UNPREDICTABLEMASK = t.UNPREDICTABLEMASK;

      W0MASK = t.W0MASK;
      W1MASK = t.W1MASK;

      CLRONREAD     = t.CLRONREAD;
      SETONREADMASK = t.SETONREADMASK;
      W0SETMASK     = t.W0SETMASK;
      W1CLRMASK     = t.W1CLRMASK;

      // register_container = t.register_container;
      compareMask = t.compareMask;

      m_actual_register = t.m_actual_register;

      // Don't copy lock!
      // lock = t.lock;

      // Don't copy register_written and register_read.
      register_written = 0;
      register_read = 0;

      // Dispose of the analysis_port connections.
      //  A copy can't notify anyone. Explicitly null.
      read_ap = null;
      generic_read_ap = null;
      write_ap = null;
      generic_write_ap = null;

      compare_read_only_bits = t.compare_read_only_bits;
    endfunction

    virtual function uvm_object clone();
      uvm_report_info("uvm_register_base",
        "Calling clone() for uvm_register_base class");
      uvm_report_error("uvm_register_base", $psprintf(
        "Register '%s' must provide a clone() implementation",
          get_full_name()));
      return null;
    endfunction

    // Group: Printing/Formating

    // convert2string()
    // Construct and return a "pretty" string 
    // representation of the register.
    virtual function string convert2string();
      //!!! Note the '%p' - automatic fancy format. 
`ifdef NCV
      return $psprintf( "%0d", peek());
`else
      return $psprintf( "%p", peek());
`endif
    endfunction

    // GROUP: Comparison

    // Function: compare_data()
    // Compare the data field using the compare mask.
    // Return 1 if the new_data matches the existing value.
    // Return 0 otherwise.
    virtual function bit compare_data(T new_data);
      T mask;

      // Figure out what mask to use. Sometimes (most
      // of the time) you don't want to compare Read-Only
      // bits - since they haven't been modeled with
      // expected behavior. But other times, when you
      // are running a special test, you may want to
      // compare the Read-Only bits, because you have
      // modeled them (and can predict the expected value).
      //
      // Normally, the comparison is done with just
      // the compareMask. The compareMask tells what
      // bits will be compared. For example, if a bit
      // in the compareMask is '1', then that bit will
      // be used in the comparison.
      //
      // In the case where READ-ONLY bits should be
      // compared, then the default setting are NOT OK:
      //   compare_read_only_bits = 0;
      //
      // If you want to compare READ-ONLY bits, then
      // you need to set compare_read_only_bits:
      //   compare_read_only_bits = 1;
      //   
      // When READ-ONLY bits are being compared, then
      // we just use the compareMask. We're comparing ALL
      // the bits.
      // 
      // When READ-ONLY bits are NOT being compared, then
      // we must "modify" the mask we're going to use.
      //
      // If (compare_read_only_bits == 0), then
      //   a. Any bit that is marked "UNPREDICTABLE"
      //      will NOT be compared.
      //   b. Any bit that is READ-ONLY will not be
      //      compared.

      if (compare_read_only_bits)
        mask = compareMask;
      else
        mask = compareMask & WMASK & ~UNPREDICTABLEMASK;
        
      if ((peek()&mask) == (new_data&mask))
        return 1;
      return 0;
    endfunction

    virtual function bit compare_b(uvm_register_base b);
      this_type r;
      $cast(r, b);
      return compare_data(r.peek());
    endfunction

    // Function: compare()
    // Same functionality as compare_data(), but a register 
    // is passed in, instead of the register data value.
    // To use custom masks or other fancy compare,
    //  override this function.
    virtual function bit compare(this_type b);
      return compare_b(b);
    endfunction

    // GROUP: Coverage

    // Function: sample()
    // Implement this is the design specific register.
    virtual function void sample();
      // Available for things like:
      //   c.sample();
      if (m_actual_register!=null)
        m_actual_register.sample();
      else
        super.sample();
    endfunction
  endclass

  /* End of Register */
//--------------------------------------------------------//

//--------------------------------------------------------//
// Group: Register Base Classes
  /* Begin Address Mapping */

  /* 
   * uvm_mapped_register
   *
   * This class is used to hold the thing that is
   * sorted. It contains the two keys used, and the
   * "payload" - the register handle.
   */
  class uvm_mapped_register extends uvm_void;
    // -------------------------------
    // The two fields we are keyed on.
    //
    // Key 1: Name - full_path_name
    string full_path_name;    // Full path name. 
                              //   (from the top)

    // Key 2: Address
    //        The list of addresses are each keyed 
    //        individually. Each address has a 
    //        "mapped_register", but they all point to 
    //        the same register.
    address_list_t addresses;
    // -------------------------------

    string hierarchical_name; // Hierarchical path 
                              //   (downward from here)

    // List of address ranges.
    address_range_list_t address_ranges;

    // The Payload: A handle pointing to the register.
    uvm_register_base register;

`ifdef NCV
    function new();
      address_ranges = new();
    endfunction
`endif

    function int size();
      return addresses.size();
    endfunction

    // For debugging.
`ifndef NCV
    local 
`endif
      function string addresses2string();
      string s = "";
      for (int i = 0; i < size(); i++) begin
        if (i != 0)
          $sformat(s, "%s, ", s);
        $sformat(s, "%s%0h", s, addresses[i]);
      end
      return s;
    endfunction

    // For debugging.
    virtual function string convert2string();
        return $psprintf({
          "Name[%s]\n",
          "                      @addr=[%s] %s"},
          full_path_name, 
          addresses2string(),
          (register==null)?
            "<unconstructed>":
            register.convert2string());
    endfunction
  endclass

  typedef class uvm_register_container;
  typedef class uvm_register_map;
  typedef class uvm_register_file;

  typedef class mapped_register_container;

`ifndef NCV
  typedef mapped_register_container 
    mapped_register_container_list[$];
  `define LL(l) l
`else
  class mapped_register_container_list_c;
    mapped_register_container LIST[$];
  endclass
  typedef mapped_register_container_list_c 
    mapped_register_container_list;
  `define LL(l) l.LIST
`endif

  class mapped_register_container extends uvm_void;
    uvm_register_container container;
    address_t start_address;
    address_t end_address;
    uvm_register_container mapped_in;

    virtual function string get_full_name();
      return container.get_full_name();
    endfunction
    virtual function string get_name();
      return container.get_name();
    endfunction

    static function void printlist(
      mapped_register_container_list l);
      uvm_register_container container;

      foreach (`LL(l)[s]) begin
        container = `LL(l)[s].container;
        $display("%s(%s) @ 0x%0x within %s", 
          container.get_full_name(), 
          container.get_type_name(),
          `LL(l)[s].start_address, 
          container.get_full_name());
      end
    endfunction
  endclass


  /*
   * CLASS: uvm_register_container
   *
   * The shared base class for register files and register
   * maps.
   *
   * Holds the FLAT address space and the ByName lookup 
   * space.
   *
   * This class knows how to add a register to the address
   * space, and find it either by name, or by address.
   *
   */
  class uvm_register_container extends
      uvm_named_object;

    `uvm_object_utils(uvm_register_container)

    function new(string name = "", uvm_named_object p = null);
      super.new(name, p);
    endfunction

    // Function: build()
    // Match the UVM engine
    virtual function void build();
	  `uvm_warning("build", "DEPRECATED: The function build() should not be used.")
	  `uvm_info("build", "Use build_maps() instead.", UVM_MEDIUM)
	  build_maps();
    endfunction

    virtual function void build_maps();
	  `uvm_error("build_maps", "The function build_maps() has not been overridden")
	  `uvm_error("build_maps", "The build_maps() function is used to create the address maps")
	endfunction

    //
    // addSpace[] and nameSpace[] are the two places
    // we store register references. A register map
    // or a register file contains a FLAT address space
    // represented by 'addrSpace[]'. It also has a "by-name"
    // space of all the registers. (By name means:
    // "by-container-and-name-of-register").
    //
    // When a register map or a register file is 
    // "copied-into" another register map, its addrSpace 
    // is copied into the new addrSpace, at some offset 
    // (all the old addresses are incremented by the 
    // offset in the new address space).
    //
    // The offset space fills up as registers
    // are added to the register file.
    protected uvm_mapped_register addrSpace[address_t];

    // The name space fills up as registers
    // are added to the register file.
    // For each register there is ONE entry in this
    // array. This IS the name of the register.
    // For example "top.dut1.ahb.blk2.adder.r1"
    // If the register has other names, then it is
    // in nameSpace_alias[]
    /*protected*/ uvm_mapped_register nameSpace[string];

    // nameSpace_alias[s] is an array of mapped_registers,
    // which have previously been created, and are already
    // registered in nameSpace[]. 
    // Any mapped register in nameSpace_alias is also
    // in nameSpace.
    //
    // nameSpace holds registers by full_path_name.
    // nameSpace_alias holds registers by any old name
    //  you like.
    protected uvm_mapped_register nameSpace_alias[string];

    // List of memories, keyed by name.
    uvm_register_base mapped_memories[string];

    function isMapped(address_t address, 
        output address_t mapped_address);

      // First check to see if this is a "regular" mapped
      // address.
      if ( addrSpace.exists(address) ) begin
        mapped_address = address; 
        return 1;
      end
      else begin
        // Second, check to see if this is a memory mapped 
        //  address. We're optimizing memory mapped 
        //  addresses, since mapping an entire memory 
        // could be quite expensive 
        // (Mapping 4G addresses....)
//TODO
`ifdef NOTDEF
        uvm_mapped_register mapped_memory;
        mapped_memory = addrSpace[address];
        return mapped_memory.is_in_range(address);
`endif
        foreach (mapped_memories[s]) begin
          if (
        (address >= mapped_memories[s].get_start_range()) &&
        (address <= mapped_memories[s].get_end_range())
          ) begin
            mapped_address = 
              mapped_memories[s].get_start_range();
            return 1;
          end
        end
      end
      return 0;
    endfunction

    // spaces() - 
    //  Utility function to create a string of 'depth' spaces.
    //
    protected function string spaces(int depth);
      string s = "";
`ifdef NCV
      for(int i = 0; i < depth; i++)
        s = {s, " "};
`else
      if (depth > 0) s = {depth{" "}};
`endif
      return s;
    endfunction

    typedef string instance_name;
    typedef string s_type_name;

    // ---------------------------------------------
    // These are lists of containers that are mapped
    // inside this container. This records all the
    // calls to add_register_file and add_register_map()
    //
    // For example, 'register_files[]' contains
    // a mapped register files that have been added to
    // THIS register file or register map. This array
    // is added to when add_register_file() is called.
    //
    // register_files[] contains all the register files
    //   added.
    // register_maps[] contains all the register maps
    //   added
    //
    mapped_register_container_list 
      register_files[instance_name],
      register_maps[instance_name];

    // Should these _by_type_name arrays be removed?
    mapped_register_container_list 
      register_maps_by_type_name[s_type_name],
      register_files_by_type_name[s_type_name];
    // ---------------------------------------------

    virtual function void 
      m_add_mapped_register_container(
        uvm_register_container container, address_t start);

      uvm_register_file register_file;
      uvm_register_map register_map;

      // Create a new mapped object.
      mapped_register_container mapped_object = new();

      // Point at the register_file or register_map
      // Say at which address this thing is mapped. (start).
      // Point to the place which mapped you.
      mapped_object.container = container;
      mapped_object.start_address = start;
      mapped_object.mapped_in = this;

      // Is it a register map?
      if ($cast(register_map, container)) begin
`ifdef NCV
        if (!register_maps.exists(container.get_name()))
          register_maps[container.get_name()] = new();
        if (!register_files_by_type_name.exists(
            container.get_type_name()))
          register_files_by_type_name[
            container.get_type_name()] = new();
`endif
        `LL(register_maps[
          container.get_name()]).push_back(mapped_object);
        `LL(register_maps_by_type_name[
          container.get_type_name()]).push_back(mapped_object);
      end
      // Is it a register file?
      else if ($cast(register_file, container)) begin
`ifdef NCV
        if (!register_files.exists(container.get_name()))
          register_files[container.get_name()] = new();
        if (!register_files_by_type_name.exists(
            container.get_type_name()))
          register_files_by_type_name[
            container.get_type_name()] = new();
`endif
        `LL(register_files[
          container.get_name()]).push_back(mapped_object);
        `LL(register_files_by_type_name[
          container.get_type_name()]).push_back(mapped_object);
      end
      else
        uvm_report_error("m_add_mapped_register_container()", 
          "Not a register map or register file");
    endfunction

    virtual function void
        m_find_register_file_by_type_name(
        output mapped_register_container_list l, 
        input string name);
      if (register_files_by_type_name.exists(name))
        l = register_files_by_type_name[name];
    endfunction

    virtual function void 
        m_find_register_map_by_type_name(
        output mapped_register_container_list l, 
        input string name);
      if (register_maps_by_type_name.exists(name))
        l = register_maps_by_type_name[name];
    endfunction

    virtual function void
        m_find_register_file_by_name(
        output mapped_register_container_list l, 
        input string name);
      if (register_files.exists(name))
        l = register_files[name];
    endfunction

    virtual function void
        m_find_register_map_by_name(
          output mapped_register_container_list l, 
          input string name);
      if (register_maps.exists(name))
        l = register_maps[name];
    endfunction


/*
  function automatic mapped_register_container_list 
      find_register_container_by_type_name(
        uvm_register_container container, string name); 
  function automatic mapped_register_container_list 
      find_register_file_by_type_name(
        uvm_register_container container, string name); 
  function automatic mapped_register_container_list 
      find_register_map_by_type_name(
        uvm_register_container container, string name); 
*/

  // FUNCTION: find_register_container()
  // Given a name, lookup the name from 'here'.
  // This name is a name relative to the register
  // container we are in currently - this register map
  // or this register file - for example.
  // The name will normally be a path name containing
  // path separators and names - "rf1.dut2.blkA.blkleaf"
  //
  function automatic void 
      find_register_container(
      output mapped_register_container_list list_of_mapped_items, 
      input string name); 

    uvm_register_container container;
    name_list_t l;

    // Turn a string name into a list of names.
    // The string name is a dotted list of names, and
    // the function uvm_parse_path_name() turns the
    // dotted list of names into a list of names
    uvm_parse_path_name(l, name);

    // Given a scope/container and a list of names, drive
    // a search down through the scope, using up
    // one container from the list each each "level".
    // Return the list of scopes/containers found along
    // the way down during our directed search.
    m_find_register_container(list_of_mapped_items, l);
  endfunction

  // Given a list of names representing a hierarchical
  // path, find a container.
  function automatic void 
      m_find_register_container(
      output mapped_register_container_list ret_list, 
      input name_list_t name_stack); 

    mapped_register_container_list l;

    uvm_register_container found_container;
    string name;

    // Grab the one we are working on at this level.
    name = name_stack[0];

    // Find 'name' here in THIS container.
    // First try register maps. Then register files.
    m_find_register_map_by_name(l, name);
    if (`LL(l).size() == 0)
      m_find_register_file_by_name(l, name);

    // Ooops. Not a register map and not a register file.
    if (`LL(l).size() == 0) begin
      uvm_report_error("m_find_register_container()", 
        $psprintf("Cannot find %s", name));
      return;
    end

    //TODO: If this list contains more than one thing
    // that means this "name" is mapped more than once.
    // The name should represent the SAME container. It's the
    // same name isn't it??????????????????????????
    // If the answer is yes, then this is NOT an error,
    // just return the ONE thing.
    // No - it is mapped twice for example at two different
    // offsets.
    if (`LL(l).size() > 1) begin
      mapped_register_container x;
      // Oops. More than one container found. This is a 
      // problem.
      $display("Error: multiple items found for '%s'", name);

      // HACK.
      // Fix the list to contain only one thing...
      while(`LL(l).size() > 1) begin
        x = `LL(l).pop_back();
        $display("       Throwing away '%s' mapped to 0x%x", 
          x.container.get_full_name(),
          x.start_address
          );
      end
      $cast(x, `LL(l)[0].container);
      $display("       Keeping '%s' mapped to 0x%x", 
        x.container.get_full_name(),
        x.start_address
        );
    end
    // We have ONE container on the list now - process it.
    // Good. Keep going.
    $cast(found_container, `LL(l)[0].container);

    // Stop condition. Stop when there is just one 
    // container in the list. We just processed that 
    // one container, so we're done.
    // If there is more than one, recurse down with the
    // rest of the list.
    if ( name_stack.size() > 1 )
        found_container.m_find_register_container(
          ret_list,
          name_stack[1:$]);

    // We're back from recursing, with the answer on top.
    // We ACTUALLY have a very nice stack of found containers
    // being returned. For this code, we're only interest
    // in the leaf node - the one we are after. But the
    // stack provides a nice way to figure out mapping context
    // if that is needed later.
    `LL(ret_list).push_front(`LL(l)[0]);
  endfunction

    virtual function int getContextAddress(
      uvm_register_container mapped_container
    );
      int address = 0;
//TODO
`ifdef NOTDEF
      while ( mapped_container != null ) begin
        address += mapped_container.start_address;
        mapped_container = mapped_container.mapped_in;
      end
`endif
      return address;
    endfunction

    virtual function void print_registers(int depth = 0);
      int topContextAddress = 42;
      uvm_register_base r;

      $display(" %s ---- nameSpace[]", spaces(depth));
      foreach (nameSpace[s]) begin
        r = nameSpace[s].register;
        topContextAddress = getContextAddress(this);

$display(" %s -R  %s (%s)[%s] id=%0d [%s] <TopContextAddr=%0d", 
          spaces(depth), 
          r.get_name(), r.get_full_name(),
          nameSpace[s].hierarchical_name,
          r.named_object_id,
          nameSpace[s].addresses2string(),
          topContextAddress);
      end
      $display(" %s ---- nameSpace_alias[]", spaces(depth));

      foreach (nameSpace_alias[s]) begin
        $display(" %s >A '%s' -> '%s' <id=%0d>",
          spaces(depth), s, 
          nameSpace_alias[s].full_path_name,
          nameSpace_alias[s].register.named_object_id);
      end
      $display(" %s ---- addrSpace[]", spaces(depth));
      foreach (addrSpace[s]) begin
        r = addrSpace[s].register;
        topContextAddress = getContextAddress(this);

$display(" %s -R  %s (%s)[%s] id=%0d [%0x] <TopContextAddr=%0d", 
          spaces(depth), 
          r.get_name(), r.get_full_name(),
          addrSpace[s].hierarchical_name,
          r.named_object_id,
          s, //was: addrSpace[s].addresses2string(),
          topContextAddress);
      end
      $display(" %s ----", spaces(depth));
    endfunction

    virtual function void print_rm(
        int depth = 0, int ok_to_print_registers = 1);
      string s_type;
      uvm_register_map rm;

      if ($cast(rm, this)) s_type = "RM";
      else                 s_type = "RF";

      $display(" %s +%s %s(%s)", 
        spaces(depth), s_type,
        get_name(), get_full_name());

      depth += 2;
      if (ok_to_print_registers)
        print_registers(depth);

      $display(" %s ---- register_maps[]", spaces(depth));
      foreach ( register_maps[t] ) begin
        mapped_register_container_list l = register_maps[t];

        foreach ( `LL(l)[s] ) begin
          $display(" %s +RM %s(%s) 0x%0x mapped in %s", 
            spaces(depth), 
            `LL(l)[s].get_name(), 
            `LL(l)[s].get_full_name(), 
            `LL(l)[s].start_address,
            get_full_name());
          `LL(l)[s].container.print_rm(depth, 
            ok_to_print_registers);
        end
      end

      $display(" %s ---- register_files[]", spaces(depth));
      foreach ( register_files[t] ) begin
        mapped_register_container_list l = register_files[t];

        foreach ( `LL(l)[s] ) begin
          $display(" %s +RF %s(%s) 0x%0x mapped in %s", 
            spaces(depth), 
            `LL(l)[s].get_name(), 
            `LL(l)[s].get_full_name(), 
            `LL(l)[s].start_address,
            get_full_name());
          `LL(l)[s].container.print_rm(depth, 
            ok_to_print_registers);
        end
      end
      depth -= 2;
    endfunction


    // FUNCTION: get_register_array()
    //
    // Return the list of all registers in this address map
    virtual function void get_register_array(
        output register_list_t register_array);

      string name;
      if (nameSpace.first(name)) do
        register_array.push_back(nameSpace[name].register);
      while (nameSpace.next(name));
    endfunction

    // FUNCTION: get_register_field_by_name()
    //
    function void get_register_array_field_by_name(
      output register_list_t registers_with_field, 
      input string field_name);

      register_list_t register;
      get_register_array(register);
      foreach (register[i])
        if ( register[i].has_field(field_name) )
          registers_with_field.push_back(register[i]);
    endfunction

    // FUNCTION: get_register_field_by_name_with_tag()
    //
    function void get_register_array_field_by_name_with_tag(
        output register_list_t registers_with_field,
        input string tag_name);
      register_list_t register;
      get_register_array(register);
      foreach (register[i])
        if ( register[i].has_tag(tag_name) )
          registers_with_field.push_back(register[i]);
    endfunction


    // FUNCTION: reset()
    //
    // For all the registers, call the reset() function
    virtual function void reset();
      register_list_t registers;

      get_register_array(registers);
      foreach (registers[i])
        registers[i].reset();
    endfunction

    // FUNCTION: reset_field_by_name()
    virtual function void reset_field_by_name(
        string field_name);
      register_list_t registers;
      get_register_array_field_by_name(registers, field_name);
      foreach (registers[i])
        registers[i].reset_field_by_name(field_name);
    endfunction

    // FUNCTION: reset_field_by_name_with_tag()
    virtual function void reset_field_by_name_with_tag(
        string tag_name);
      register_list_t registers;
      get_register_array_field_by_name_with_tag(
        registers, tag_name);
      foreach (registers[i])
        registers[i].reset_field_by_name_with_tag(tag_name);
    endfunction

    // FUNCTION: print_fields()
    // Call print_fields() on every register contained
    // in this register_file/register_map.
    virtual function void print_fields();
      register_list_t registers;
      get_register_array(registers);
      foreach (registers[i])
        registers[i].print_fields();
    endfunction

    // FUNCTION: display_address_map_by_address()
    //
    // Print information about the address map, 
    // arranged by address
    virtual function void display_address_map_by_address();
      address_t address;
      uvm_report_info("regmap", 
        "display_address_map_by_address()");
`ifdef NCV
      $display("%s %s %s    %s", 
`else
      $display("%14s %8s %s    %s", 
`endif
        "Name", "Address", "Value", "PathName");
      if ( addrSpace.first(address) ) do begin
`ifdef NCV
        $display("%s %x %s (%s)", 
`else
        $display("%14s %8x %s (%s)", 
`endif
          addrSpace[address].register.get_name(), 
          address, 
          addrSpace[address].register.convert2string(),
          addrSpace[address].register.get_full_name()
          );
      end while ( addrSpace.next( address ) );
    endfunction

    // FUNCTION: display_address_map_by_name()
    //
    // Print information about the address map, 
    // arranged by name
    virtual function void display_address_map_by_name();
      string name;
      uvm_report_info("regmap", 
        "display_address_map_by_name()");
`ifdef NCV
      $display("%s %s %s     %s", 
`else
      $display("%14s %8s %s     %s", 
`endif
        "Name", "Address", "Value", "PathName");
      if ( nameSpace.first(name) ) do begin
`ifdef NCV
        $display("%s %x %s (%s)", 
`else
        $display("%14s %8x %s (%s)", 
`endif
          nameSpace[name].register.get_name(),
          nameSpace[name].addresses[0], 
          nameSpace[name].register.convert2string(),
          nameSpace[name].register.get_full_name());
          for (int i = 1; i < nameSpace[name].size(); i++) 
          begin
`ifdef NCV
            $display("%s %x %s (%s)", 
`else
            $display("%14s %8x %s (%s)", 
`endif
              nameSpace[name].register.get_name(),
              nameSpace[name].addresses[i], 
              nameSpace[name].register.convert2string(),
              nameSpace[name].register.get_full_name());
          end
      end while ( nameSpace.next( name ) );
    endfunction

    // FUNCTION: display_address_map()
    //
    // Print information about the address map.
    virtual function void display_address_map();
      // Watch out - lots of information is possible.
      display_address_map_by_address();
      display_address_map_by_name();
    endfunction

    virtual function string get_summary();
      string s;
      $sformat(s, "REGDUMP: %0d addresses, %0d registers",
        addrSpace.num(), nameSpace.num());
      return s;
    endfunction

    // FUNCTION: add_register_alias()
    //
    // add_register() maps a register using the
    // full path name. 
    // add_register_alias() allows an additional name,
    // or alias to also be mapped (it is NOT actually
    // a new mapping - the "alias mapping" just points
    // to the existing full name mapping.
    //
    function void add_register_alias(
      uvm_register_base register, string alias_name);

      string full_path_name;

      if ( register == null ) begin
        uvm_report_error("add_register_alias", 
"The argument 'register' is null. No alias created.");
        return;
      end

      full_path_name = register.get_full_name();

      /* DEBUG CODE
      $display("");
      $display("-------------");
      $display("Adding alias '%s'", alias_name);
      $display("   for name  '%s'", full_path_name);
      $display("-------------");
      foreach (nameSpace[s]) begin
        $display("nameSpace[%s] = '%p'", s, nameSpace[s]);
      end
      */

      // Is there a mapping already?
      if (nameSpace.exists(full_path_name)) begin

        // Is this the first time THIS alias has been used?
        if (!nameSpace_alias.exists(alias_name)) begin
          // First time for this alias. Point this alias
          // to the nameSpace[] version.
          nameSpace_alias[alias_name] = 
            nameSpace[full_path_name]; 
        end
        else begin
          // Alias already exists.
          // Hmm. Fishy. This alias already exists.
          // Better double check that this existing alias is
          // pointing at the same place....
          if (nameSpace_alias[alias_name] != 
              nameSpace[full_path_name]) begin
            uvm_report_error("uvm_register_container",
              $psprintf(
"Alias name '%s' already exists, and points to '%s'",
                alias_name, 
nameSpace_alias[alias_name].full_path_name));
            uvm_report_info("uvm_register_container",
              $psprintf(
"This add_register() call is trying to point it to '%s'",
              full_path_name));
          end
          else begin
           // The existing alias is already pointing to the
           // right thing, so just ignore this new alias.
          end
        end
      end
      else begin
        // Register is not yet mapped.
        uvm_report_error("uvm_register_container",
$psprintf("Register '%s' not found.", full_path_name));
        uvm_report_info("uvm_register_container",
"In order to alias a register it must be added first");
      end
    endfunction

    // FUNCTION: delete_mappings()
    // Delete all the mapping data structures for this
    // register container. This is usually only done
    // when you plan to rebuild the mappings - for example
    // when you change some set of constraints which will
    // have the affect of changing the mappings.
    //
    // 1. Delete the mappings.
    // 2. Change the constraints, randomize.
    // 3. Rebuild the mappings.
    //
    virtual function void delete_mappings();
      nameSpace.delete();
      nameSpace_alias.delete();
      addrSpace.delete();

      register_maps.delete();
      register_maps_by_type_name.delete();
      register_files.delete();
      register_files_by_type_name.delete();

      mapped_memories.delete();
    endfunction

    // FUNCTION: add_register()
    //
    // Add a register with 'name' and an offset 
    // (or address). The register has been previously 
    //  constructed elsewhere.
    //
    // Note : 'name' is always (should always) be
    //   register.get_fullname(). 
    //
    // The "mapped_register" construct is entered into two
    // search tables:
    //   1. Search by name. The array 'nameSpace[]' is a
    //      search by name associative array.
    //   2. Search by address. The array 'addrSpace[]' is a
    //      search by address associative array.
    function void add_register(
        string name, offset_t offset, 
          uvm_register_base register,
          string hierarchical_name = "");

      uvm_mapped_register mapped_register;
      address_t mapped_address;

      // We need protection from the 
      // user error that the register was never
      // constructed before being added.
      if ( register == null ) begin
        uvm_report_error("uvm_register_container", 
          $psprintf(
            "Register '%s' at address %h is unconstructed",
            name, offset));
        return;
      end

      // At the bottom level, the hierarchical name
      // has not been built.
      if (hierarchical_name == "")
        hierarchical_name = register.get_name();

      // Check to see if the slot is already occupied!
      // If the name already exists, then it is already
      //  mapped. So this new address mapping is
      //  an "alias", and we should reuse (update) 
      //  the previous map entry.
      if (nameSpace.exists(name)) begin
        // Mapped register already exists. Get it.
        mapped_register = nameSpace[name];
      end
      else begin
        // Mapped register does NOT exist. Make it.
        mapped_register = new();
        mapped_register.register = register;
        mapped_register.full_path_name = name;
        mapped_register.hierarchical_name = 
          hierarchical_name;
      end

      // Store the mapped_register away.
      nameSpace[mapped_register.full_path_name] = 
        mapped_register;
      //$display("Added nameSpace[%s]", 
        //mapped_register.full_path_name);

      // We're straight on the nameSpace, now 
      //  add an alias as a convenience for the user.
      add_register_alias(register, hierarchical_name);

      //Note : This code does NOT use a "width" of a 
      //      register to consume multiple address slots.
      //      This is the responsibility of the
      //      user. (When added to the register map,
      //      provide all proper addresses...)
      if (!isMapped(offset, mapped_address)) begin
        // New. No entry at this address.
        addrSpace[offset] = mapped_register;

        // Put the current address on the list of addresses.
        mapped_register.addresses.push_front(offset);
      end
      else begin
        // Already exists. Address already used.
        // TODO: Check if offset != mapped_address, 
        //       then this is a memory.
        uvm_report_error("uvm_register_container", 
          $psprintf(
"\nAddress %0h already filled with %s.\n Cannot add %s",
          mapped_address, 
          addrSpace[mapped_address].register.get_full_name(),
          register.convert2string()));
      end
    endfunction


    // Function: add_register_file()
    //
    // Add a register file to this register map.
    //  All addresses in the "copied-in" register file
    //  are incremented by 'addr' before being stored
    //  in the address map of this object.
    function void
        add_register_file(
          uvm_register_container rf, address_t addr);

       uvm_register_file rf_handle;
       if (!$cast(rf_handle, rf)) begin
         // Cast failed, so this is NOT a register file.
         uvm_report_error("uvm_register_map",
           $psprintf(
"add_register_file() requires a register file. %s is not a register file", rf.get_full_name()));
       end
       else 
         add_register_map(rf, addr);
    endfunction

    // Function: add_register_map()
    //
    // Add a register map to this register map.
    //  All addresses in the "copied-in" map
    //  are incremented by 'addr' before being stored
    //  in the address map of this object.
    function void
        add_register_map(
          uvm_register_container rm, address_t addr);

      address_t address;

       if ( rm == null ) begin
         uvm_report_error("uvm_register_map", 
            "add_register_map() bad register map (null)");
         return;
       end

      m_add_mapped_register_container(rm, addr);

      // TODO: do something about memories when the 
      //       copy happens.

      // Add each register
      if ( rm.addrSpace.first(address) ) do begin
        if ( 
           rm.addrSpace[address].register.isMemory()
        ) begin
          add_memory(
           rm.addrSpace[address].full_path_name,
           rm.addrSpace[address].register.get_start_range() 
             + addr,
           rm.addrSpace[address].register.get_end_range() 
             + addr,
           rm.addrSpace[address].register,
           {rm.get_name(), ".", 
              rm.addrSpace[address].hierarchical_name});
        end
        else begin
          add_register(
            rm.addrSpace[address].full_path_name,
            address + addr,
            rm.addrSpace[address].register,
            {rm.get_name(), ".", 
              rm.addrSpace[address].hierarchical_name});
        end
      end while ( rm.addrSpace.next( address ) );
    endfunction


    function void add_memory(
        string name,
        offset_t offset,
        offset_t last_offset,
        uvm_register_base memory,
        string hierarchical_name = "");

        address_range_t address_range;
        uvm_mapped_register mapped_register;

        // TODO: Check address overlaps with 
        //       existing memories.
        add_register(name, offset, memory, 
          hierarchical_name);

        // When add_register() returns, a mapped_register
        // exists. We guarantee it. But let's double check.
        if (!nameSpace.exists(name)) begin
          uvm_report_error("MEM", 
            $psprintf("Mapped name lookup failed for '%s'", 
              name));
          return;
        end
`ifdef NCV
        address_range = new();
`endif
        address_range.start_range = offset;
        address_range.end_range   = last_offset;

        mapped_register = nameSpace[name];
        `LL(mapped_register.address_ranges).push_back(
          address_range);

        memory.set_start_range(offset);
        memory.set_end_range(last_offset);

        mapped_memories[name] = memory;
    endfunction

    // FUNCTION: add_register_in_range()
    //
    // Shortcut for adding a register with a 
    //  large address range.
    function void add_register_in_range( 
        string name, 
        offset_t first_offset, 
        offset_t last_offset, 
        offset_t grid, 
        uvm_register_base register,
        string hierarchical_name = "");

      for ( offset_t offset = first_offset;
            offset <= last_offset;
            offset += grid )
        add_register( name, offset, register, 
          hierarchical_name);
    endfunction

    // FUNCTION: lookup_register_addresslist_by_name()
    //
    // Given a register name, provide ALL the addresses of 
    // the register.  Returns a list of addresses.
    virtual function void
        lookup_register_addresslist_by_name(
        output address_list_t list_of_addresses, input string name);

      if (nameSpace.exists(name)) begin
        //TODO: For a memory? Just return the first address?
        //      Or a randomly generated list?
        //      Or the complete range (start, end)?
        list_of_addresses = nameSpace[name].addresses;
      end
      else if (nameSpace_alias.exists(name)) begin
        list_of_addresses = nameSpace_alias[name].addresses;
      end
      else begin
        uvm_report_error("uvm_register_container", 
         $psprintf(
"lookup_register_addresslist_by_name(): Cannot find register '%s'", name));
      end
    endfunction


    // FUNCTION: lookup_register_address_by_name()
    //
    // Given a register name, provide a single
    // mapped address.
    virtual function address_t
        lookup_register_address_by_name(
          string name, 
          output bit valid_address);

      address_list_t list_of_addresses;
      address_t address;

      lookup_register_addresslist_by_name(list_of_addresses, name);

      if (list_of_addresses.size() == 0) begin
        // Name returned an empty list of addresses.
        // Not mapped.
        uvm_report_error("uvm_register_container", 
          $psprintf(
"lookup_register_address_by_name(): %s is not mapped to any address", name));
        valid_address = 0;
        address = 0;
       end
      else begin
         // Name returned a list of addresses.
          // Pick one of the items randomly.
        address = list_of_addresses[
            $urandom_range(list_of_addresses.size()-1)];
        valid_address = 1;
       end
      return address; 
    endfunction


    // FUNCTION: lookup_register_by_name()
    //
    // Given a register name, return the corresponding
    // register handle.
    virtual function uvm_register_base
        lookup_register_by_name(string name);

      if (nameSpace.exists(name))
        return nameSpace[name].register;

      if (nameSpace_alias.exists(name))
        return nameSpace_alias[name].register;

      uvm_report_error("uvm_register_container", 
        $psprintf(
"lookup_register_by_name(): Cannot find register '%s'", 
          name));
      return null; 
    endfunction

    // Given an offset, provide the mapped data
    //  structure. This is an "internal data structure"
    //  and may not be interesting for most users.
    local virtual function uvm_mapped_register
        m_lookup_mappedregister_by_address(offset_t offset);

      uvm_mapped_register mapped_register;
      address_t mapped_address;

      // In a regfile, an addr is really an offset.
      if (isMapped(offset, mapped_address))
        return addrSpace[mapped_address];
      else 
        return null;
    endfunction

    // FUNCTION: lookup_register_by_address()
    //
    // Given an offset, provide the register mapped there.
    virtual function uvm_register_base
        lookup_register_by_address(offset_t offset);

        uvm_mapped_register mr;
        mr = m_lookup_mappedregister_by_address(offset);
          if (mr == null) begin
            uvm_report_error("uvm_register_container", 
              $psprintf(
"lookup_register_by_address(): Offset/Address 0x%0x has not been mapped.", 
                 offset));
            return null;
          end 
          else begin
            return mr.register;
          end
    endfunction

    virtual function void bus_read(
        bytearray_t d, address_t address = 0);
      uvm_register_base r = 
        lookup_register_by_address(address);
      //TODO: Handle register reads that span multiple
      //      registers.
      if (r.isMemory())
        r.bus_read(d, address);
      else
        r.bus_read(d, address);
    endfunction

//TODO
`ifdef NOTDEF
    virtual function void bus_write(
        bytearray_t d, address_t address = 0);
      uvm_register_base r = 
        lookup_register_by_address(address);
      //TODO: Handle register reads that span multiple
      //      registers.
      if (r.isMemory())
        r.bus_write(d, address);
      else
        r.bus_write(d);
    endfunction
`endif

    virtual function void peek_bytes(
        output bytearray_t ba,
        input address_t address, int nbytes = 0);
      uvm_register_base r = 
        lookup_register_by_address(address);
      //TODO: Handle register reads that span multiple
      //      registers.
      r.peek_bytes(ba, address, nbytes);
    endfunction

    virtual function void poke_bytes(
        address_t address, bytearray_t new_data);
      uvm_register_base r = 
        lookup_register_by_address(address);
      //TODO: Handle register writes that span multiple
      //      registers.
      r.poke_bytes(address, new_data);
    endfunction
  endclass

  /*
   * CLASS: uvm_register_file
   *
   * A register file contains a list of registers.
   * Each register is associated with one or more offset.
   *
   * A register file is really just a register map 
   * with these special properties:
   *   1. A register file contains only registers. You can
   *      only add registers to it.
   *   2. A register file has no "base" address. The 
   *      addresses or registers in a regfile are really 
   *      "offsets".
   */
  class uvm_register_file extends uvm_register_container;

    `uvm_object_utils(uvm_register_file)

    function new(string name = "", uvm_named_object p = null);
      super.new(name, p);
    endfunction

    // DEPRECATED. Use get_register_array
    virtual function void get_registers(output register_list_t list);
      uvm_report_error("uvm_register_file", 
        { "get_registers() is DEPRECATED. ",
          "Please use get_register_array() instead." });
    endfunction

    virtual function void report_version_numbers();
      uvm_report_error("uvm_register_file", 
        "report_version_numbers() not implemented");
    endfunction
  endclass

  /*
   * CLASS: uvm_register_map
   *
   * A register map contains other register maps,
   * register files and registers. A register map
   * models a "global" discontiguous register space.
   *
   * A register map is used to model bus bridges.
   * Just an extended register file.
   */
  class uvm_register_map extends uvm_register_file;

    `uvm_object_utils(uvm_register_map)

    function new(string name = "", uvm_named_object p = null);
      super.new(name, p);
    endfunction

    // Function: get_register_map()
    //
    // Return the currently registered register map
    // from the configuration.
    //
    // Pass in a place to go find the config.
    // If the place (variable 'c') is NULL, then
    // use uvm_top.
    //
    // Example usages:
    //
    //   get_register_map()
    //    Looks for "register_map" in the top.
    //
    //   get_register_map(.c(my_component))
    //    Looks for "register_map" in my_component.
    //
    //   get_register_map("map", my_component);
    //    Looks for "map" in my_component.
    // 
    static function uvm_register_map 
      get_register_map(
        string config_name = "register_map",
        uvm_component c = null);

      uvm_object       o;
      uvm_register_map register_map;
    
      // If not "scope" (c) is passed in, then use
      // the top-level.
      if ( c == null )
        c = uvm_root::get();

      // Try to find an attribute in the config named
      //  'config_name' (for example, named "register_map")
      //
      if (! c.get_config_object(config_name, o, 0))
        c.uvm_report_error("RegisterMap", $psprintf(
          "Cannot find register map named '%s' in '%s'", 
            config_name, c.get_full_name()));
      else
        $cast(register_map, o);

      return register_map;
    endfunction

    // Function: uvm_register_get_register_map() (DEPRECATED)
    //
    // Return the currently registered register map
    // from the configuration.
    static function uvm_register_map 
      uvm_register_get_register_map(
        string config_name = "register_map",
        uvm_component c = null);
        return get_register_map(config_name, c);
    endfunction
  endclass

