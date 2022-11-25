// https://embetronicx.com/tutorials/microcontrollers/stm32/stm32-gpio-tutorial/#STM32_GPIO_Tutorial_-_Registers_used_in_STM32_GPIO

const micro = @import("microzig");
const regs = micro.chip.registers;

const build_options = @import("build_options");

const led_pin = switch (build_options.deviceType) {
    .tag => micro.Pin("PA1"),
    .anchor => micro.Pin("PA2")
};

//const dw = @cImport({
//  @cInclude("deca_device_api.h");
//});

// var version = dw.dwt_apiversion();

const delay_time = 1000000;

pub fn main() void {
    const button = micro.Gpio(micro.Pin("PA0"), .{.mode = .input});
    button.init();
    const led = micro.Gpio(led_pin, .{
        .mode = .output,
        .initial_state = .high,
    });
    led.init();

    while (true) {
        if(button.read() == .high) micro.debug.busySleep(delay_time);
        led.toggle();
    }
}