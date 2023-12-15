const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;
const expectEqualSlices = std.testing.expectEqualSlices;

const Instr = @import("instr.zig").Instr;

const prelude =
    \\bits 16
    \\
;

pub fn decompile(
    input: []const u8,
    alloc: Allocator,
    writer: std.fs.File.Writer,
) !void {
    try writer.writeAll(prelude);

    for (0..input.len / 2) |i| {
        const idx = i * 2;
        const inst = Instr.new(input[idx .. idx + 2]);
        const string = try inst.to_string(alloc);
        defer alloc.free(string);
        try writer.writeAll(string);
    }
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const input_path = args.next() orelse {
        std.log.err("zig8086 needs an input file :(", .{});
        return;
    };

    const output_path = args.next() orelse "output.asm";

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    std.log.info("reading: {s}", .{input_path});

    const input_file = try std.fs.cwd().openFile(input_path, .{});
    const size = (try input_file.stat()).size;
    const input = try alloc.alloc(u8, size);
    defer alloc.free(input);
    _ = try input_file.readAll(input);

    const output_file = try std.fs.cwd().createFile(output_path, .{ .read = true });
    defer output_file.close();

    try decompile(input, alloc, output_file.writer());
}
