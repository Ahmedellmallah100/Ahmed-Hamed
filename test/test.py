# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):

    dut._log.info("Start")

    # Clock: 10 us period
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # -------------------------
    # Reset
    # -------------------------
    dut._log.info("Reset")

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    # -------------------------
    # Test all 16 input cases
    # -------------------------

    for inputs in range(16):

        dut.ui_in.value = inputs
        dut.uio_in.value = 0

        await ClockCycles(dut.clk, 1)

        # Extract x1..x4
        x1 = (inputs >> 0) & 1
        x2 = (inputs >> 1) & 1
        x3 = (inputs >> 2) & 1
        x4 = (inputs >> 3) & 1

        # Perceptron:
        # z = x1 + x2 + x3 + x4 - 2
        z = x1 + x2 + x3 + x4 - 2

        # Step activation
        prediction = 1 if z >= 0 else 0

        # Encode expected output:
        #
        # uo_out[7]   = 0
        # uo_out[6:1] = z[5:0]
        # uo_out[0]   = prediction
        #
        # Convert signed 6-bit z to 6-bit unsigned representation
        z_6bit = z & 0x3F

        expected = (z_6bit << 1) | prediction

        dut._log.info(
            f"Input={inputs:04b} "
            f"x=({x1},{x2},{x3},{x4}) "
            f"z={z} "
            f"prediction={prediction} "
            f"expected={expected}"
        )

        assert dut.uo_out.value.integer == expected, (
            f"Input={inputs:04b}: "
            f"expected {expected:08b}, "
            f"got {dut.uo_out.value.integer:08b}"
        )

    dut._log.info("All Perceptron tests passed!")
