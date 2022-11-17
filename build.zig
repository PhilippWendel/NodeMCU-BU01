const std = @import("std");
const microzig = @import("microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    const backing = .{
        .chip = microzig.chips.stm32f103x8,
    };

    var exe = microzig.addEmbeddedExecutable(
        b,
        "my-executable.bin",
        "src/main.zig",
        backing,
        .{
          // optional slice of packages that can be imported into your app:
          // .packages = &my_packages,
        },
    );
    exe.setBuildMode(.ReleaseSmall);
    exe.install();
}