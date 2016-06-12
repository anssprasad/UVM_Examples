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

//
// CLASS: uvm_memory_ranges
// The class uvm_memory_ranges contains a list of ranges, sorted by
// starting address.
//
// Create N allocated blocks with each having a size in the 
// range [i,j] bytes.
// Create the N allocated blocks
//   - evenly over the range [A,B].
//   - using a distribution D.
//   - with average spacing between them in the range [k,l].
//   - with NO spacing between them for P percent of the time. 
//     Otherwise some other spacing.
//

class uvm_memory_ranges;
  rand uvm_memory_range ranges[];

  int number_added_by_hand = 0; // Keeps track of the number 
                                // of blocks created by hand 
                                // (not randomized)

  int max_memory_regions = 50;  // Used in a constraint in 
                                // order to limit the number 
                                // of blocks allocated.
                                // [Optional].

  int old_size = 0; // Used in a constraint in order 
                    //  to always get bigger.  [Optional].

  int quiet = 1; // Be quiet.
  int debug = 0; // No debug.

  local bit m_locked = 0; // Flag to skip out of 
                          //  pre_ and post_randomize().


  // Apparently there can only be one constraint used to 
  // control the size of the array. I haven't checked this 
  // completely, but it appears to be the case in at least 
  // 1 test.
  constraint size {
    // Always get bigger.
    //ranges.size() > old_size;   

    // Always create at least 5 random blocks.
    ranges.size() >= number_added_by_hand; 

    // You can't get smaller than the number of by-hand 
    // blocks. Don't turn this one off.
    ranges.size() >= number_added_by_hand; 

    // Don't go beyond the maximum # of pieces.
    ranges.size() < max_memory_regions; 
  }

  local function void m_add_r(uvm_memory_range r);
    $display("Adding (%0d, %0d)[%s]", 
      r.range_start, r.range_end, r.t);
	ranges = new[ranges.size()+1](ranges);
	ranges[ranges.size()-1] = r;
    //ranges.push_back(r);
  endfunction

  // Function: m_new_range_random
  // Create a new range, and mark it random.
  // It is important to call randomize here - it appears 
  // to make the array more "fair". Instead of calling 
  // randomize(), you can just set the range_start and end values 
  // to zero - or any other value. The real values will get 
  // set later (randomize() will be called later, whether 
  // or not you call randomize() now).
  local function uvm_memory_range m_new_range_random(
      string l_tag_name = "ranges");

    uvm_memory_range r = new();
    r.tag_name = l_tag_name;
    r.t = MEMORY_RAND;
    assert(r.randomize()); // Just stick something in there.
                           // Picking 0,0 is OK too, but 
                           // calling randomize() appears to 
                           // make the results more "fair".
    return r;
  endfunction

  // Function: add_range()
  // This is the "by-hand" access routine. Create a new 
  // range with the range_start and end values specifid, and give 
  // it a "tag".  The tag is used as a way to group ranges.
  virtual function uvm_memory_range add_range(
      address_t range_start, 
      address_t range_end, 
      string l_tag_name = "ranges");

    uvm_memory_range r = m_new_range_random(l_tag_name);
    r.t = MEMORY_SET_BY_HAND;

    r.range_start = range_start;
    r.range_end = range_end;

    r.rand_mode(0); // This one should NOT ever be randomized.
    m_add_r(r);
    number_added_by_hand++;

    // TODO: Actually add the range into the tagged lookup 
    // array

    // Keep the list sorted at all times.
    //  ranges.sort() with ( item.range_start );
    //     - Hmm. It appears we don't need this sort.
    //       post_randomize() will sort things later.
    //  m_check();
    return r;
  endfunction

  // Function: add_range_random_by_hand()
  // This is the "MEMORY_RAND_BY_HAND" access routine. Create a 
  // placeholder for some random range. We don't care a 
  // lick about the values, just that we need to have a 
  // block. It is tagged.
  // TODO: add a "size" parameter - create a block of at 
  // least size bytes.
  virtual function uvm_memory_range add_range_random_by_hand(
    string l_tag_name = "ranges");
    uvm_memory_range r = m_new_range_random(l_tag_name);
    r.t = MEMORY_RAND_BY_HAND;
    m_add_r(r);
    return r;
  endfunction

  // Function: m_unlock()
  // Internal use only, for turning constraints back on
  // after a previous call to lock().
  local function void m_unlock();
    foreach (ranges[i])
      if (ranges[i].t != MEMORY_SET_BY_HAND) begin
`ifdef NCV
		uvm_memory_range r;
		r = ranges[i];
        r.rand_mode(1);
`else
        ranges[i].rand_mode(1);
`endif
      end
    size.constraint_mode(0);
    //sort_order.constraint_mode(1);
    //no_overlap.constraint_mode(1);
    m_locked = 0;
  endfunction

  // Function: m_lock()
  // Internal use only, for turning constraints off.
  // The goal is to turn off ALL constraints NOT associated
  // with the size randomization.
  local function void m_lock();
    m_locked = 1;
    foreach (ranges[i])
      if (ranges[i].t != MEMORY_SET_BY_HAND) begin
`ifdef NCV
		uvm_memory_range r;
		r = ranges[i];
        r.rand_mode(0);
`else
        ranges[i].rand_mode(0);
`endif
        end
    size.constraint_mode(1);
    //sort_order.constraint_mode(0);
    //no_overlap.constraint_mode(0);
  endfunction

  // Function: pre_randomize()
  // Built-in function. In this case we're using
  // pre_randomize() as a way to randomize the size
  // of the array before randomizing the contents.
  //
  // Take care of expansion and contraction. 
  //
  function void pre_randomize();
    int new_size;
    uvm_memory_range old_ranges[];

    if ( m_locked )
      return;

    // Turn off certain constraints while
    // we calculate a new size.
    m_lock();

    old_size = ranges.size(); 

    // Save the old range, in case we are truncating,
    // and need to copy down.
    old_ranges = new[old_size] (ranges);

    // Calculate the new size, using the constraints
    //  for size.
    assert(this.randomize());
    new_size = ranges.size();

    $display("resize: old_size = %0d, new_size = %0d", 
      old_size, new_size);

    // Copy everything over.
    ranges = new[new_size] (ranges);

    if (new_size > old_size) begin
      // Expansion. We've allocated more blocks.
      // If we grew, then we'll need to fill in the empties.
      // Stuff in some allocated(!) empty stuff.
      for(int i = old_size; i < new_size; i++)
        if ( ranges[i] == null )
          ranges[i] = m_new_range_random();
    end // End of Expansion. Easy.

    if (old_size > new_size) begin
      // Truncation. We've allocated fewer blocks.
      // If we shrank, then we'll copy any by-hand items
      // from the part to be truncated into the part we
      // are keeping.

      // Check to make sure we have enough space.
      // Normally this should be handled by a constraint,
      // but it may get turned off or changed by the user.
      if (number_added_by_hand > new_size) begin
        // Error! We have more by-hand items than space....
        $display("Error: %0d by-hand items exist, ",
          number_added_by_hand);
        $display("but only %0d elements were created.", 
          new_size);
      end

      // OK. If there are any by-hand items in the area that
      // is shrinking to zero, copy them down low - anywhere.
      for(int i = new_size; i < old_size; i++)
        if (old_ranges[i].t == MEMORY_SET_BY_HAND) begin
          for(int j = 0; j < new_size; j++)
            if ( ranges[j].t != MEMORY_SET_BY_HAND ) begin
               ranges[j] = old_ranges[i]; // Copy down.
               break;
            end
        end


    end // end of Truncation. Whew.

    // Turn back ON the certain constraints.
    m_unlock();

`ifndef NCV
    ranges.sort() with ( item.range_start );
`endif // NOTDEF NCV
  endfunction

  local function void m_retry1(int i);
    if (i >= ranges.size()-1)
      return;
    if ( ranges[i].t == MEMORY_SET_BY_HAND ) 
      return;

    //if (ranges[i+1].range_start > ranges[i].range_end + 1)
      assert(ranges[i].randomize(range_end)
        with {   ranges[i].range_end < 
               ranges[i+1].range_start; });
    //else
      //assert(ranges[i].randomize());

  endfunction

  local function void m_retry2(int i);
    if ( i == 0 )
      return;

    if ( ranges[i].t == MEMORY_SET_BY_HAND ) 
      return;

    // Check to see if there is room to fit a new block 
    // in here.
    if (ranges[i].range_start > ranges[i-1].range_end + 1)
        assert(ranges[i].randomize()
          with {
            ranges[i].range_start > ranges[i-1].range_end;
            (i < ranges.size()-1) ->
               ranges[i].range_end < ranges[i+1].range_start;
            });
    else
      assert(ranges[i].randomize());
  endfunction

  // Function: post_randomize()
  // Built-in function. In this case we're using
  // post_randomize() as a way to randomize the value
  // of the range_end attribute.
  function void post_randomize();
    int count = 0;
    bit done;
    if ( m_locked )
      return;

    //
    // At this point all ranges have a 
    // (range_start, range_end) set, whether they were 
    // set by hand or filled in with random data.
    //
    // BUT the range_end value is "random" - it does NOT 
    // depend on the following range_start. (It's probably 
    // wrong. Too big).
    // 
    // First sort the list, and then randomize just the 
    // range_end, constraining to be less than the 
    // following range_start.
    //
`ifndef NCV
    ranges.sort() with ( item.range_start );
`endif // NOTDEF NCV

    done = 0;
    count = 0;
    while(!done) begin
      count++;
      if (!quiet && ((count % 10000) == 0 )) begin
        $display("count = %5d", count);
        print();
      end
      done = 1;
      for(int i = 1; i < ranges.size(); i++) begin
        // Notice we range_start i=1. The i-1 takes care of item 
        // 0 below. 
        
        // Oh snap. There are two items that have 
        // the same range_start. Re-throw. Sort. Start over. 
        // Expensive, but shouldn't(?) happen very often. 
        // Likely there is some better coding to achieve 
        // this goal.
        if (ranges[i-1].range_start == ranges[i].range_start)
        begin
          if ( ranges[i-1].t != MEMORY_SET_BY_HAND )
            assert(ranges[i-1].randomize());
          if ( ranges[i].t != MEMORY_SET_BY_HAND )
            assert(ranges[i].randomize());
`ifndef NCV
          ranges.sort() with ( item.range_start );
`endif // NOTDEF NCV
          done = 0;
          break;
        end // == starts.

        // Overlap checker....
        // Is i contained in i-1?
        //if (ranges[i-1].range_end >= ranges[i].range_end) 
        //  begin
        // Always true: 
        //  if (ranges[i].range_start 
        //     >= ranges[i-1].range_start) begin
        if (ranges[i].range_start <= ranges[i-1].range_end) 
        begin
          if(debug) begin
            $display("SNAP: %0d: %0d >= %0d", i-1,
              ranges[i-1].range_end, ranges[i].range_start);
            $display("  OLD: (%4d, %4d) vs ( %4d, %4d)", 
              ranges[i-1].range_start, ranges[i-1].range_end,
              ranges[i].range_start, ranges[i].range_end);
          end

          m_retry1(i-1);
          m_retry2(i);

          if(debug)
            $display("  NEW: (%4d, %4d) vs ( %4d, %4d)", 
              ranges[i-1].range_start, ranges[i-1].range_end,
              ranges[i].range_start, ranges[i].range_end);

`ifndef NCV
          ranges.sort() with ( item.range_start );
`endif // NOTDEF NCV
          /* Trying again */
          done = 0;
          break;
        end 
      end // for loop
    end // not done

`ifndef NCV
    ranges.sort() with ( item.range_start );
`endif // NOTDEF NCV

    // Fix up the range_end on the random values. 
    // Notice we're going backwards through the list.
    for(int i = ranges.size()-1; i >= 0; i--) begin
      if (ranges[i].t != MEMORY_SET_BY_HAND) begin
        if ( i == ranges.size()-1 ) begin
          // Last range. 
          assert(ranges[i].randomize(range_end));
        end
        else begin
          assert(ranges[i].randomize(range_end) with {
            ranges[i].range_end < ranges[i+1].range_start;
          });
        end
      end
    end
    m_check();
  endfunction
  
  // Function: m_check
  // A utility function that call be called anytime.
  // It checks to make sure the list is "OK".
  // The list can get to be not OK if the constraints are not
  // correct or if other bad things happen. Under normal
  // circumstances, this function won't be neeed - the list
  // will be fine.
  //
  // TODO: Is this code needed anymore?
  //
  function void m_check();
    foreach (ranges[j])
      foreach (ranges[i]) begin
        if (ranges[i].range_start == ranges[j].range_start) 
        begin
          if ((ranges[i].t == MEMORY_SET_BY_HAND) &&
              (ranges[j].t == MEMORY_SET_BY_HAND)) begin
            // Both are MEMORY_SET_BY_HAND. Oops. User entered 
            // bad data.
            if ( i != j ) begin
              $display("Error: Conflict in range defintion:");
              $display("       (%5d, %5d)",
                ranges[i].range_start, ranges[i].range_end);
              $display("       (%5d, %5d)",
                ranges[j].range_start, ranges[j].range_end);
            end
          end
          else begin
           // Both are not MEMORY_SET_BY_HAND.
           // post_randomize() will take care of this.
          end
        end
      end
  endfunction

  virtual function bit is_bad_range(int i);
      if (i < ranges.size()-1)
        // If its a bad range, return 1. 
        if ( ranges[i].range_end > ranges[i+1].range_start )
          return 1;
      return 0;
  endfunction

  virtual function void print();
    if (quiet)
      return;
`ifndef NCV
    ranges.sort() with ( item.range_start );
`endif // NOTDEF NCV
    foreach (ranges[i])
      $display("Range[%2d] (%5d, %5d)%s(%s) (%s)", 
        i, ranges[i].range_start, 
           ranges[i].range_end, 
           is_bad_range(i)?"*":" ", // Print a "*" if the range is bad.
           ranges[i].tag_name,
           ranges[i].t);      
  endfunction
endclass
