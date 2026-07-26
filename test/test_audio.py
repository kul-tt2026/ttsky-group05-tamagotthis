import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def test_play_dead(dut):

    clock = Clock(dut.clk, 40, unit="ns")      # 25 MHz
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.state_sound.value = 0

    dut.rst_n.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)

    dut.rst_n.value = 1

    for _ in range(20):
        await RisingEdge(dut.clk)

    # play_dead
    dut.state_sound.value = 0b0000001

    f = open("pwm.txt", "w")

    # Record about 6 seconds
    dut._log.info("Starting recording")

    for i in range(150_000_000):
        if i % 25_000_000 == 0:
            dut._log.info(f"Recorded {i} samples")
        await RisingEdge(dut.clk)
        f.write(f"{int(dut.uio_out.value[7])}\n")

    dut._log.info("Finished recording")

    f.close()