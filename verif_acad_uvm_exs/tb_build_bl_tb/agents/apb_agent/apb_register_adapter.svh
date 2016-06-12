class apb_register_adapter extends register_adapter_base;

`uvm_object_utils(apb_register_adapter)

function new(string name = "apb_register_adapter");
  super.new(name);
endfunction

task read(inout register_seq_item req);
  apb_read_seq read_seq = apb_read_seq::type_id::create("read_seq");

  read_seq.addr = req.address;
  read_seq.start(m_bus_sequencer);
  req.data = read_seq.data;
endtask: read

task write(register_seq_item req);
  apb_write_seq write_seq = apb_write_seq::type_id::create("write_seq");

  write_seq.addr = req.address;
  write_seq.data = req.data;
  write_seq.start(m_bus_sequencer);
endtask: write

endclass: apb_register_adapter