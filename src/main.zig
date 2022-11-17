// https://embetronicx.com/tutorials/microcontrollers/stm32/stm32-gpio-tutorial/#STM32_GPIO_Tutorial_-_Registers_used_in_STM32_GPIO

const micro = @import("microzig");

const regs = micro.chip.registers;

pub fn main() void {
    // Enable AHB clock
    regs.RCC.APB2ENR.modify(.{.IOPAEN=1});

    // GPIO port mode register
    regs.GPIOA.CRL.modify(.{.MODE0=0b01,.MODE1=0b01});
    regs.GPIOA.BSRR.modify(.{.BS1 = 1, .BR2 = 1});

    while (true) {
    }
}