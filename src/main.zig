const std = @import("std");
const expect = std.testing.expect;

const Instr = packed struct {
    // byte 1
    // does this instruction operate on words?
    word: bool,
    // direction:
    // if 0, source is REG
    // if 1, dest is REG
    d: bool,
    opcode: u6,

    // byte 2
    reg_mem: u3,
    reg: u3,
    mode: u2,
};

export fn decode_instr(inst: u8) i32 {
    return switch (inst & 0xfc) {
        0b0 => 4,
        else => 0,
    };
}

test "mov" {
    const input = [_]u8{ 0x89, 0xd9 };
    const inst: Instr = @bitCast(input);
    try expect(inst.opcode == 0b100010);
    try expect(inst.d == false); // source in reg
    try expect(inst.word == true); // 16 bits

    try expect(inst.reg == 0b011); // bx is source
    try expect(inst.reg_mem == 0b001); // cx is dest

    // const together: u16 = @as(u16, input[0]) << 1 | @as(u16, input[1]);
    //const inst: Instr = @bitCast(together);
    //std.log.err("{b}", .{inst.opcode});
    //std.log.err("{b} {b} -> {b}", .{ input[0], input[1], together });
}
