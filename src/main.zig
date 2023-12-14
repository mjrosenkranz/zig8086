const std = @import("std");
const expect = std.testing.expect;

const Mode = enum(u2) {
    no_disp = 0b00,
    byte = 0b01,
    word = 0b10,
    reg = 0b11,
};

const Dir = enum(u1) {
    source = 0,
    dest = 1,
};

const Instr = packed struct {
    // byte 1
    // does this instruction operate on words?
    word: bool,
    // direction:
    // if 0, source is REG
    // if 1, dest is REG
    dir: Dir,
    opcode: u6,

    // byte 2
    r_m: u3,
    reg: u3,
    mode: Mode,

    //    pub fn from_bytes(bytes: [2]u8) Instr {
    //        return Instr{
    //            .opcode = @truncate(bytes[0] >> 2),
    //            .dir = @as(bytes[0], bool),
    //            .word = @as(bytes[0] >> 1, bool),
    //            .mode = @truncate(bytes[2] >> 6),
    //            .reg = @truncate(bytes[2] >> 3),
    //            .r_m = @truncate(bytes[2]),
    //        };
    //    }
};

export fn decode_instr(inst: u8) i32 {
    return switch (inst & 0xfc) {
        0b0 => 4,
        else => 0,
    };
}

test "inst bitcast" {
    const input = [_]u8{ 0x89, 0xd9 };
    const inst: Instr = @bitCast(input);

    try expect(inst.opcode == 0b100010);
    // source in reg
    try expect(@intFromEnum(inst.dir) == 0);
    try expect(inst.dir == Dir.source);
    // 16 bits
    try expect(inst.word == true);

    // reg to reg
    try expect(@intFromEnum(inst.mode) == 0b11);
    try expect(inst.mode == Mode.reg);

    // bx is source
    try expect(inst.reg == 0b011);

    // cx is dest
    try expect(inst.r_m == 0b001);
}

// test "inst new" {
//     const input = [_]u8{ 0x89, 0xd9 };
//     const inst = Instr.from_bytes(input);
//
//     try expect(inst.opcode == 0b100010);
//     try expect(inst.dir == false); // source in reg
//     try expect(inst.word == true); // 16 bits
//
//     try expect(inst.mode == 0b11); // bx is source
//     try expect(inst.reg == 0b011); // bx is source
//     try expect(inst.r_m == 0b001); // cx is dest
// }
