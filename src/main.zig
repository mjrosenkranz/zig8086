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

const Reg = enum(u4) {
    // 8bit
    al,
    cl,
    dl,
    bl,
    ah,
    ch,
    dh,
    bh,

    // 16bit
    ax,
    cx,
    dx,
    bx,
    sp,
    bp,
    si,
    di,
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

    fn as_reg(self: Instr, reg: u3) Reg {
        var val: u4 = reg;
        if (self.word) {
            val += 8;
        }

        return @enumFromInt(val);
    }

    /// returns the regist in the reg field
    pub fn get_reg(self: Instr) Reg {
        return self.as_reg(self.reg);
    }

    pub fn r_m_as_reg(self: Instr) Reg {
        return self.as_reg(self.r_m);
    }
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
    try expect(inst.get_reg() == Reg.bx);

    // cx is dest
    try expect(inst.r_m == 0b001);
    try expect(inst.r_m_as_reg() == Reg.cx);
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
