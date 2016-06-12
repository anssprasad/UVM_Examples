//----------------------------------------------------------------------
//   Copyright 2007-2008 Cadence Design Systems, Inc.
//   Copyright 2009      Mentor Graphics, Inc.
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
//----------------------------------------------------------------------

#include "vpi_user.h"
#include "veriuser.h"
#include "svdpi.h"
#include <malloc.h>

/* 
 * TITLE: UVM Register Backdoor C code.
 *
 * This code is not strictly associated with the
 * UVM register library. It is used by the UVM register
 * library to gain access to internal simulator variables.
 *
 * This code makes certain assumptions about maximum bit size,
 * and how to work around this. These assumptions are likely
 * be changed.
 *
 */

/*
 * FUNCTION: uvm_register_get_max_size()
 *
 * This C code checks to see if there is PLI handle
 * with a value set to define the maximum bit width.
 *
 * If no such variable is found, then the default 
 * width of 1024 is used.
 *
 * This function should only get called once or twice,
 * its return value is cached in the caller.
 *
 */
static int uvm_register_get_max_size()
{
  vpiHandle ms;
  s_vpi_value value_s = { vpiIntVal };
  ms = vpi_handle_by_name("uvm_register_pkg::UVM_REGISTER_MAX_WIDTH", 0);
  if(ms == 0) 
    return 1024;  /* If nothing else is defined, this is the DEFAULT */
  vpi_get_value(ms, &value_s);
  vpi_printf("UVM_Register DPI-C : Lookup of 'uvm_register_pkg::UVM_REGISTER_MAX_WIDTH' successful. ");
  vpi_printf("Setting new maximum width to %0d\n", value_s.value.integer);
  return value_s.value.integer;
}

/*
 * FUNCTION: uvm_register_check_hdl
 *
 * Given a path, look the path name up using the PLI,
 * but don't set or get. Just check.
 *
 * Return 0 if NOT found.
 * Return 1 if found.
 */
int uvm_register_check_hdl(char *path)
{
  vpiHandle r = vpi_handle_by_name(path, 0);
  if(r == 0)
    return 0;
  else 
    return 1;
}


/*
 * FUNCTION: uvm_register_set_hdl
 *
 * Given a path, look the path name up using the PLI,
 * and set it to 'value'.
 */
void uvm_register_set_hdl(char *path, p_vpi_vecval value)
{
  static int maxsize = -1;
  int i, size, chunks;
  vpiHandle r;
  s_vpi_value value_s;
  p_vpi_vecval value_p;
  s_vpi_time  time_s = { vpiSimTime, 0, 0 };
  r = vpi_handle_by_name(path, 0);
  if(r == 0)
  {
    vpi_printf("FATAL uvm_register : unable to locate hdl path (%s)\n", path);
    vpi_printf(" Either the name is incorrect, or you may not have PLI visibility to that name");
    vpi_printf(" To gain PLI visibility, make sure you use +acc=rmb when you invoke vlog");
    vpi_printf("   vlog +acc=rmb ....");
    tf_dofinish();
  }
  else
  {
    if(maxsize == -1) 
        maxsize = uvm_register_get_max_size();

#ifdef NCSIM
    // Code for NC
    size = vpi_get(vpiSize, r);
    if(size > maxsize)
    {
      vpi_printf("FATAL uvm_register : hdl path '%s' is %0d bits,\n", path, size);
      vpi_printf(" but the maximum size is %0d, redefine using a compile\n", maxsize);
      vpi_printf(" flag. i.e. %s\n", "vlog ... +define+UVM_REGISTER_MAX_WIDTH=<value>");
      tf_dofinish();
    }
    chunks = (size-1)/32 + 1;
    // Probably should be:
    //   value_p = (p_vpi_vecval)(calloc(1, chunks*8*sizeof(s_vpi_vecval)));
    value_p = (p_vpi_vecval)(malloc(chunks*8*sizeof(s_vpi_vecval)));
    value_s.format = vpiVectorVal;
    value_s.value.vector = value_p;
    /* Copy a/b, reversing on NC. */
    /*dpi and vpi are reversed*/
    /*  - only in NC. In ModelSim they are the same. */
    for(i=0;i<chunks; ++i)
    {
      // Reverse a/b on NC.
      value_p[i].aval = value[i].bval;
      value_p[i].bval = value[i].aval;
    }
    vpi_put_value(r, &value_s, &time_s, vpiNoDelay);  
    free (value_p);
#else
    // Code for Questa
    value_s.format = vpiVectorVal;
    value_s.value.vector = value;
    vpi_put_value(r, &value_s, &time_s, vpiNoDelay);  
#endif
  }
  return;
}

/*
 * FUNCTION: uvm_register_set_hdl
 *
 * Given a path, look the path name up using the PLI,
 * and return its 'value'.
 */
void uvm_register_get_hdl(char *path, p_vpi_vecval value)
{
  static int maxsize = -1;
  int i, size, chunks;
  vpiHandle r;
  s_vpi_value value_s;
  r = vpi_handle_by_name(path, 0);
  if(r == 0)
  {
    vpi_printf("FATAL uvm_register : unable to locate hdl path %s\n", path);
    vpi_printf(" Either the name is incorrect, or you may not have PLI visibility to that name");
    vpi_printf(" To gain PLI visibility, make sure you use +acc=rmb when you invoke vlog");
    vpi_printf("   vlog +acc=rmb ....");
    tf_dofinish();
  }
  else
  {
    if(maxsize == -1) 
        maxsize = uvm_register_get_max_size();

    size = vpi_get(vpiSize, r);
    if(size > maxsize)
    {
      vpi_printf("FATAL uvm_register : hdl path '%s' is %0d bits,\n", path, size);
      vpi_printf(" but the maximum size is %0d, redefine using a compile\n", maxsize);
      vpi_printf(" flag. i.e. %s\n", "vlog ... +define+UVM_REGISTER_MAX_WIDTH=<value>");
      tf_dofinish();
    }
    chunks = (size-1)/32 + 1;

    value_s.format = vpiVectorVal;
    vpi_get_value(r, &value_s);
    /*dpi and vpi are reversed*/
    /* -> Not on Questa, and not in the LRM */
    for(i=0;i<chunks; ++i)
    {
#ifdef NCSIM
      // Code for NC.
      // Reverse a/b on NC.
      value[i].aval = value_s.value.vector[i].bval;
      value[i].bval = value_s.value.vector[i].aval;
#else
      // Code for Questa
      value[i].aval = value_s.value.vector[i].aval;
      value[i].bval = value_s.value.vector[i].bval;
#endif
    }
  }
}

