/*****************************************************************************
 *
 * Copyright 2007-2011 Mentor Graphics Corporation
 * All Rights Reserved.
 *
 * THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE PROPERTY OF
 * MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.
 *
 *****************************************************************************/

// Package: dut_params_pkg
//
// Package containing the DUT parameters, for use throughout the testbench.

package dut_params_pkg;

  // Constant: AXI4_ADDRESS_WIDTH
  //
  // The AXI4 read and write address bus widths (see AMBA AXI and ACE Protocol Specification IHI0022D section A2.2)

  localparam AXI4_ADDRESS_WIDTH = 32;

  // Constant: AXI4_RDATA_WIDTH
  //
  // The width of the RDATA signal (see AMBA AXI and ACE Protocol Specification IHI0022D section A2.6)

  localparam AXI4_RDATA_WIDTH   = 32;

  // Constant: AXI4_WDATA_WIDTH
  // 
  // The width of the WDATA signal (see AMBA AXI and ACE Protocol Specification IHI0022D section A2.3)

  localparam AXI4_WDATA_WIDTH   = 32;

  // Constant: AXI4_ID_WIDTH
  //
  // The width of the AWID/ARID signals (see AMBA AXI and ACE Protocol Specification IHI0022D section A2.2).

  localparam AXI4_ID_WIDTH      = 4;

  // Constant: AXI4_USER_WIDTH
  //
  // The width of the AWUSER, ARUSER, WUSER, RUSER and BUSER signals (see AMBA AXI and ACE Protocol Specification IHI0022D section A8.3)

  localparam AXI4_USER_WIDTH    = 2;

  // Constant: AXI4_REGION_MAP_SIZE
  //
  // The number of address-decode entries in the region map (see AMBA AXI and ACE Protocol Specification IHI0022D section A8.2.1)
  //
  // The address-decode function is done by the interconnect, generating a value for <mgc_axi4::AWREGION> / <mgc_axi4::ARREGION> from the transaction address.
  // This parameter defines the size of the entries in the region map array, where each entry defines a mapping from address-range to region value.
  // See <mgc_axi4::config_region> for details of how it is used.

  localparam AXI4_REGION_MAP_SIZE = 16;
 
  // Constant: s_axi4_if_id 
  //
  // A string used in look-up of the <mgc_axi4> during testbench configuration.
 
  localparam string s_axi4_if_id = "axi4_IF";

endpackage
