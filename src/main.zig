// https://embetronicx.com/tutorials/microcontrollers/stm32/stm32-gpio-tutorial/#STM32_GPIO_Tutorial_-_Registers_used_in_STM32_GPIO

const micro = @import("microzig");
const regs = micro.chip.registers;

const build_options = @import("build_options");

const led_pin = micro.Pin(switch (build_options.deviceType) {
    .tag => "PA1",
    .anchor => "PA2"
});

const dw = @cImport({
    @cInclude("deca_device_api.h");
});

var version = dw.dwt_apiversion();

const delay_time = 1000000;

pub fn main() void {
    const led = micro.Gpio(led_pin, .{
        .mode = .output,
        .initial_state = .low,
    });
    led.init();

    while (true) {
        micro.debug.busySleep(delay_time);
        led.write(.low);
        micro.debug.busySleep(delay_time);
        led.write(.high);
    }
}