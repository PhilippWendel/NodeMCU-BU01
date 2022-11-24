const std = @import("std");
const microzig = @import("lib/microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    const project_name: []const u8 = "NodeMCU-BU01";

    const nodeType = enum { tag, anchor };

    for ([_]nodeType{ .tag, .anchor }) |node| {
        const allocator = std.heap.page_allocator;

        // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        // const allocator = gpa.allocator();
        // defer _ = gpa.deinit();

        const elf = try std.fmt.allocPrint(allocator, "{s}_{s}.elf", .{ project_name, @tagName(node) });
        defer allocator.free(elf);
        const bin = try std.fmt.allocPrint(allocator, "{s}_{s}.bin", .{ project_name, @tagName(node) });
        // defer allocator.free(bin); // Crashes program ???

        std.debug.print("{s}\n{s}\n", .{ elf, bin });

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

    const upload_step = b.step("upload", "Upload binary to microcontroller");
    upload_step.makeFn = upload;
}

fn upload(self: *std.build.Step) !void {
    const tag = [_]u8{ 0x54, 0xFF, 0x6B, 0x06, 0x48, 0x49, 0x71, 0x50, 0x35, 0x54, 0x02, 0x67 };
    // const anchor = [_]u8{0x48, 0xFF, 0x6B, 0x06, 0x86, 0x66, 0x50, 0x56, 0x32, 0x59, 0x09, 0x67};
    _ = self;
    const unique_id_file_name = "unique_id";
    const allocator = std.heap.page_allocator;
    // Get chip unique id
    _ = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &[_][]const u8{ "st-flash", "read", unique_id_file_name, "0x1FFFF7E8", "0xC" } });
    const unique_id_file = try std.fs.cwd().openFile(unique_id_file_name, .{ .mode = .read_only });
    var unique_id: [12]u8 = undefined;
    _ = try unique_id_file.read(&unique_id);
    // Get binary to upload
    const binary_file = for (unique_id) |byte, i| {
        if (!(byte == tag[i])) break "zig-out/bin/NodeMCU-BU01_anchor.bin";
    } else "zig-out/bin/NodeMCU-BU01_tag.bin";
    // Upload
    std.debug.print("Uploading: {s}\n", .{binary_file});
    _ = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &[_][]const u8{ "st-flash", "--connect-under-reset", "write", binary_file, "0x08000000" } });
}
