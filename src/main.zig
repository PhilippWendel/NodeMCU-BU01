// https://embetronicx.com/tutorials/microcontrollers/stm32/stm32-gpio-tutorial/#STM32_GPIO_Tutorial_-_Registers_used_in_STM32_GPIO

const micro = @import("microzig");
const regs = micro.chip.registers;

const build_options = @import("build_options");

pub fn delay(ticks: i32) void {
    var i = @divExact(ticks, 5);
    while (i > 0) : (i -= 1) {
        asm volatile ("nop");
    }
}

const delay_time = 10000000;

pub fn main() void {
    // Enable AHB clock
    regs.RCC.APB2ENR.modify(.{ .IOPAEN = 1 });

    // GPIO port mode

    regs.GPIOA.CRL.modify(switch (build_options.nodeType) {
        .tag => .{ .MODE1 = 0b01, .CNF1 = 0b00 },
        .anchor => .{ .MODE2 = 0b01, .CNF2 = 0b00 },
    });

    while (true) {
        delay(delay_time);
        regs.GPIOA.BSRR.modify(switch (build_options.nodeType) {
            .tag => .{ .BS1 = 1 },
            .anchor => .{ .BS2 = 1 },
        });
        delay(delay_time);
        regs.GPIOA.BSRR.modify(switch (build_options.nodeType) {
            .tag => .{ .BR1 = 1 },
            .anchor => .{ .BR2 = 1 },
        });
    }
}
