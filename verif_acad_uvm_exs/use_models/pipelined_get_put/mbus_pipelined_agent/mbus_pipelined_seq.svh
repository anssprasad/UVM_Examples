//
// This sequence shows how a series of unpipelined accesses to
// the bus would work. The sequence waits for each item to finish
// before starting the next.
//
class mbus_unpipelined_seq extends uvm_sequence #(mbus_seq_item);

`uvm_object_utils(mbus_unpipelined_seq)

logic[31:0] addr[10]; // To save addresses
logic[31:0] data[10]; // To save data for checking

int error_count;

function new(string name = "mbus_unpipelined_seq");
  super.new(name);
endfunction

task body;

  mbus_seq_item req = mbus_seq_item::type_id::create("req");

  error_count = 0;
  for(int i=0; i<10; i++) begin
    start_item(req);
    assert(req.randomize() with {MREAD == 0; MOPCODE == SINGLE; MADDR inside {[32'h0010_0000:32'h001F_FFFC]};});
    addr[i] = req.MADDR;
    data[i] = req.MWDATA;
    finish_item(req);
    get_response(req);
  end

  foreach (addr[i]) begin
    start_item(req);
    req.MADDR = addr[i];
    req.MREAD = 1;
    finish_item(req);
    get_response(req);
    if(data[i] != req.MRDATA) begin
      error_count++;
      `uvm_error("body", $sformatf("@%0h Expected data:%0h Actual data:%0h", addr[i], data[i], req.MRDATA))
    end
  end
endtask: body

endclass: mbus_unpipelined_seq

//
// This is a pipelined version of the previous sequence with no blocking
// call to get_response();
// There is no attempt to check the data, this would be carried out
// by a scoreboard
//
class mbus_pipelined_seq extends uvm_sequence #(mbus_seq_item);

`uvm_object_utils(mbus_pipelined_seq)

logic[31:0] addr[10]; // To save addresses
int count; // To ensure that the sequence does not complete too early

function new(string name = "mbus_pipelined_seq");
  super.new(name);
endfunction

task body;

  mbus_seq_item req = mbus_seq_item::type_id::create("req");
  use_response_handler(1);
  count = 0;

  for(int i=0; i<10; i++) begin
    start_item(req);
    assert(req.randomize() with {MREAD == 0; MOPCODE == SINGLE; MADDR inside {[32'h0010_0000:32'h001F_FFFC]};});
    addr[i] = req.MADDR;
    finish_item(req);
  end

  foreach (addr[i]) begin
    start_item(req);
    req.MADDR = addr[i];
    req.MREAD = 1;
    finish_item(req);
  end
  // Do not end the sequence until the last req item is complete
  wait(count == 20);
endtask: body

// This response_handler function is enabled to keep the sequence response
// FIFO empty
function void response_handler(uvm_sequence_item response);
  count++;
endfunction: response_handler

endclass: mbus_pipelined_seq

class mbus_pipelined_check_seq extends uvm_sequence #(mbus_seq_item);

`uvm_object_utils(mbus_pipelined_check_seq)

logic[31:0] base_address;

mbus_seq_item req_c[10];

int read_count;
int error_count;

function new(string name = "mbus_pipelined_check_seq");
  super.new(name);
endfunction

task body;

  mbus_seq_item req = mbus_seq_item::type_id::create("req");

  error_count = 0;
  // Fill up some memory
  for(int i=0; i<10; i++) begin
    assert($cast(req_c[i], req.clone()));
    start_item(req_c[i]);
    assert(req_c[i].randomize() with {MREAD == 0; MOPCODE == SINGLE; MADDR inside {[base_address:(base_address+32'h1000)]};});
    fork
      dummy_response;
    join_none
    finish_item(req_c[i]);
  end

  // Check the memory content
  read_count = 10;
  for(int i=0; i<10; i++) begin
    start_item(req_c[i]);
    req_c[i].MREAD = 1;
    fork
      check_data(i); // Spawned data check
    join_none
    finish_item(req_c[i]);
  end
  while(read_count > 0) begin
    $display("read_count = %0d", read_count);
    @(read_count);
  end
endtask: body

task automatic check_data(int i);
  mbus_seq_item req;
  // Wait for the data phase to complete
  get_response(req);
  if(req_c[i].MWDATA != req.MRDATA) begin
    `uvm_error("check_data", $sformatf("Data read error @%0h Data written: %0h, Data read back: %0h", req_c[i].MADDR, req_c[i].MWDATA, req.MRDATA))
    error_count++;
  end
  read_count--;
endtask: check_data

// Only to field the response for the write cycles
task automatic dummy_response;
  mbus_seq_item req;
  get_response(req);
endtask: dummy_response

endclass: mbus_pipelined_check_seq

class mbus_pipelined_check_rsp_handler_seq extends uvm_sequence #(mbus_seq_item);

`uvm_object_utils(mbus_pipelined_check_rsp_handler_seq)

logic[31:0] base_address;

mbus_seq_item req_c[10];

int read_count;
int error_count;

function new(string name = "mbus_pipelined_check_rsp_handler_seq");
  super.new(name);
endfunction

task body;

  mbus_seq_item req = mbus_seq_item::type_id::create("req");

  error_count = 0;

  // Enable the response handler
  use_response_handler(1);
  // Fill up some memory
  for(int i=0; i<10; i++) begin
    assert($cast(req_c[i], req.clone()));
    start_item(req_c[i]);
    assert(req_c[i].randomize() with {MREAD == 0; MOPCODE == SINGLE; MADDR inside {[base_address:(base_address+32'h1000)]};});
    finish_item(req_c[i]);
  end

  // Check the memory content
  read_count = 0;
  for(int i=0; i<10; i++) begin
    start_item(req_c[i]);
    req_c[i].MREAD = 1;
    finish_item(req_c[i]);
  end
  while(read_count < 0) begin
    $display("read_count = %0d", read_count);
    @(read_count);
  end
endtask: body

function void response_handler(uvm_sequence_item response);
  mbus_seq_item rsp;

  if(!$cast(rsp, response)) begin
    `uvm_error("response_handler", "Failed to cast response to mbus_seq_item rsp")
    return;
  end
  if(rsp.MREAD == 1) begin
    if(req_c[read_count].MWDATA != rsp.MRDATA) begin
      `uvm_error("check_data", $sformatf("Data read error @%0h Data written: %0h, Data read back: %0h", req_c[read_count].MADDR, req_c[read_count].MWDATA, rsp.MRDATA))
      error_count++;
    end
    read_count++;
  end

endfunction: response_handler

endclass: mbus_pipelined_check_rsp_handler_seq
