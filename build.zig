const std = @import("std");
const microzig = @import("lib/microzig/src/main.zig");

const project_name: []const u8 = "NodeMCU-BU01";

pub fn build(b: *std.build.Builder) !void {
    const deviceType = enum { tag, anchor };

    for ([_]deviceType{ .tag, .anchor }) |device| {
        const bin = b.fmt("{s}_{s}.bin", .{ project_name, @tagName(device) });
        const build_options = b.addOptions();
        build_options.addOption(deviceType, "deviceType", device);

        var exe = microzig.addEmbeddedExecutable(
            b,
            bin,
            "src/main.zig",
            .{ .chip = microzig.chips.stm32f103x8 },
            .{},
        );
        exe.addOptions("build_options", build_options);
        exe.addIncludePath("C:/Users/philippwendel/source/zig/NodeMCU-BU01/lib/decadriver");
        //exe.addIncludePath(b.pathFromRoot("/lib/decadriver/"));
        exe.setBuildMode(.ReleaseSmall);
        _ = exe.installRaw(bin, .{});

    }

    const upload_step = b.step("upload", "Upload binary to microcontroller");
    upload_step.makeFn = upload;
    upload_step.dependOn(b.default_step);
}

fn upload(self: *std.build.Step) !void {
    _ = self;
    const tag = [_]u8{ 0x54, 0xFF, 0x6B, 0x06, 0x48, 0x49, 0x71, 0x50, 0x35, 0x54, 0x02, 0x67 };
    // const anchor = [_]u8{0x48, 0xFF, 0x6B, 0x06, 0x86, 0x66, 0x50, 0x56, 0x32, 0x59, 0x09, 0x67};
    const unique_id_file_name = "unique_id";
    const allocator = std.heap.page_allocator;
    // Get chip unique id
    _ = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &[_][]const u8{ "st-flash", "read", unique_id_file_name, "0x1FFFF7E8", "0xC" } });
    const unique_id_file = try std.fs.cwd().openFile(unique_id_file_name, .{ .mode = .read_only });
    var unique_id: [12]u8 = undefined;
    _ = try unique_id_file.read(&unique_id);
    // Get binary to upload
    const path = "zig-out/bin/" ++  project_name;
    const binary_file = for (unique_id) |byte, i| {
        if (!(byte == tag[i])) break path ++ "_anchor.bin";
    } else path ++ "_tag.bin";
    // Upload
    std.debug.print("Uploading {s}\n", .{binary_file});
    _ = try std.ChildProcess.exec(.{ .allocator = allocator, .argv = &[_][]const u8{ "st-flash", "--connect-under-reset", "write", binary_file, "0x08000000" } });
}
