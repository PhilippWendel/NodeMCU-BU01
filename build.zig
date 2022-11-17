const std = @import("std");
const microzig = @import("microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    const project_name: []const u8 = "NodeMCU-BU01";

    const backing = .{
        .chip = microzig.chips.stm32f103x8,
    };

    var exe = microzig.addEmbeddedExecutable(
        b,
        project_name ++ ".elf",
        "src/main.zig",
        backing,
        .{
            // optional slice of packages that can be imported into your app:
            // .packages = &my_packages,
        },
    );
    exe.setBuildMode(.ReleaseSmall);
    exe.install();

    const exe_bin = b.addInstallRaw(exe.inner, project_name ++ ".bin", .{});
    b.getInstallStep().dependOn(&exe_bin.step);
}
