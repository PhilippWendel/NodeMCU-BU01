const std = @import("std");
const microzig = @import("microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    const project_name: []const u8 = "NodeMCU-BU01";

    const nodeType = enum { tag, anchor };

    const tag_options = b.addOptions();
    tag_options.addOption(nodeType, "nodeType", nodeType.tag);

    var tag = microzig.addEmbeddedExecutable(
        b,
        project_name ++ "_tag.elf",
        "src/main.zig",
        .{ .chip = microzig.chips.stm32f103x8 },
        .{},
    );
    tag.addOptions("build_options", tag_options);
    tag.setBuildMode(.ReleaseSmall);
    tag.install();

    // Convert elf file to binary file
    const tag_bin = b.addInstallRaw(tag.inner, project_name ++ "_tag.bin", .{});
    b.getInstallStep().dependOn(&tag_bin.step);

    const anchor_options = b.addOptions();
    anchor_options.addOption(nodeType, "nodeType", nodeType.anchor);

    var anchor = microzig.addEmbeddedExecutable(
        b,
        project_name ++ "_anchor.elf",
        "src/main.zig",
        .{ .chip = microzig.chips.stm32f103x8 },
        .{},
    );
    anchor.addOptions("build_options", anchor_options);
    anchor.setBuildMode(.ReleaseSmall);
    anchor.install();

    // Convert elf file to binary file
    const anchor_bin = b.addInstallRaw(anchor.inner, project_name ++ "_anchor.bin", .{});
    b.getInstallStep().dependOn(&anchor_bin.step);

    // Read unique id
    // const read_unique_id_cmd = b.addSystemCommand(&[_][]const u8{
    //     "st-flash",
    //     "read",
    //     "id", // File to save unique id to
    //     "0x1FFFF7E8", // Base address of unique id
    //     "0xC", // Length of unique id
    // });

    // const upload_cmd = b.addSystemCommand(&[_][]const u8{ "st-flash", "--reset", "write", b.getInstallPath(exe_bin.dest_dir, exe_bin.dest_filename), "0x08000000" });
    // upload_cmd.step.dependOn(b.getInstallStep());

    // const upload_step = b.step("upload", "Upload binary to microcontroller");
    // upload_step.dependOn(&read_unique_id_cmd.step);
    // upload_step.dependOn(&upload_cmd.step);
}
