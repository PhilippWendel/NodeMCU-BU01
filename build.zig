const std = @import("std");
const microzig = @import("microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    const project_name: []const u8 = "NodeMCU-BU01";

    const nodeType = enum { tag, anchor };

    for ([_]nodeType{ .tag, .anchor }) |node| {
        var allocator = std.heap.page_allocator;
        const elf = try std.fmt.allocPrint(allocator, "{s}_{s}.elf", .{ project_name, @tagName(node) });
        defer allocator.free(elf);
        const bin = try std.fmt.allocPrint(allocator, "{s}_{s}.bin", .{ project_name, @tagName(node) });
        // defer allocator.free(bin); // Crashes program ???

        const build_options = b.addOptions();
        build_options.addOption(nodeType, "nodeType", node);

        var exe = microzig.addEmbeddedExecutable(
            b,
            elf,
            "src/main.zig",
            .{ .chip = microzig.chips.stm32f103x8 },
            .{},
        );
        exe.addOptions("build_options", build_options);
        exe.setBuildMode(.ReleaseSmall);
        exe.install();

        // Convert elf file to binary file
        const exe_bin = b.addInstallRaw(exe.inner, bin, .{});
        b.getInstallStep().dependOn(&exe_bin.step);
    }

    // Read unique id
    const read_unique_id_cmd = b.addSystemCommand(&[_][]const u8{
        "st-flash",
        "read",
        "id", // File to save unique id to
        "0x1FFFF7E8", // Base address of unique id
        "0xC", // Length of unique id
    });

    const upload_cmd = b.addSystemCommand(&[_][]const u8{ "st-flash", "--connect-under-reset", "write", b.getInstallPath(.bin, try getFile()), "0x08000000" });
    upload_cmd.step.dependOn(b.getInstallStep());

    const upload_step = b.step("upload", "Upload binary to microcontroller");
    upload_step.dependOn(&read_unique_id_cmd.step);
    upload_step.dependOn(&upload_cmd.step);
}

fn getFile() ![]const u8 {
    var file = try std.fs.cwd().openFile("id", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var c: u8 = try in_stream.readByte();
    std.debug.print("First value: {}\n", .{c});
    return if (c == 72) "NodeMCU-BU01_anchor.bin" else "NodeMCU-BU01_tag.bin";
}
