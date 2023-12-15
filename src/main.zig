const std = @import("std");
const expect = std.testing.expect;
const expectEqualSlices = std.testing.expectEqualSlices;

const prelude =
    \\ bits 16
    \\
;

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

    pub fn to_string(self: Reg) *const [2]u8 {
        return switch (self) {
            .al => "al",
            .cl => "cl",
            .dl => "dl",
            .bl => "bl",
            .ah => "ah",
            .ch => "ch",
            .dh => "dh",
            .bh => "bh",
            .ax => "ax",
            .cx => "cx",
            .dx => "dx",
            .bx => "bx",
            .sp => "sp",
            .bp => "bp",
            .si => "si",
            .di => "di",
        };
    }
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

    pub fn new(bytes: []const u8) Instr {
        return @bitCast(bytes[0..2].*);
    }

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

    pub fn to_string(self: Instr, alloc: std.mem.Allocator) ![]u8 {
        const src = self.get_reg().to_string();
        const dest = self.r_m_as_reg().to_string();
        return std.fmt.allocPrint(alloc, "mov {s}, {s}", .{ dest, src });
    }
};

export fn decode_instr(inst: u8) i32 {
    return switch (inst & 0xfc) {
        0b0 => 4,
        else => 0,
    };
}

test "inst word" {
    const input = [_]u8{ 0x89, 0xd9 };
    const inst = Instr.new(&input);

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

test "inst high" {
    const input = [_]u8{ 0x88, 0xe5 };
    const inst = Instr.new(&input);

    try expect(inst.opcode == 0b100010);
    // source in reg
    try expect(@intFromEnum(inst.dir) == 0);
    try expect(inst.dir == Dir.source);
    // 16 bits
    try expect(inst.word == false);

    // reg to reg
    try expect(@intFromEnum(inst.mode) == 0b11);
    try expect(inst.mode == Mode.reg);

    // ah is source
    // try expect(inst.reg == 0b011);
    try expect(inst.get_reg() == Reg.ah);

    // ch is dest
    // try expect(inst.r_m == 0b001);
    try expect(inst.r_m_as_reg() == Reg.ch);

    const expected = "mov ch, ah";
    const actual = try inst.to_string(std.testing.allocator);
    defer std.testing.allocator.free(actual);
    try expectEqualSlices(u8, expected, actual);
}

test "to string" {
    // const expected = prelude ++ "mov cx, bx";
    const expected = "mov cx, bx";
    const input = [_]u8{ 0x89, 0xd9 };
    const inst = Instr.new(&input);
    const actual = try inst.to_string(std.testing.allocator);
    defer std.testing.allocator.free(actual);
    try expectEqualSlices(u8, expected, actual);
}

test "complex" {
    const input = [_]u8{
        0x89, 0xd9,
        0x88, 0xe5,
        0x89, 0xda,
        0x89, 0xde,
        0x89, 0xfb,
        0x88, 0xc8,
        0x88, 0xed,
        0x89, 0xc3,
        0x89, 0xf3,
        0x89, 0xfc,
        0x89, 0xc5,
    };

    const expected = [_][]const u8{
        "mov cx, bx",
        "mov ch, ah",
        "mov dx, bx",
        "mov si, bx",
        "mov bx, di",
        "mov al, cl",
        "mov ch, ch",
        "mov bx, ax",
        "mov bx, si",
        "mov sp, di",
        "mov bp, ax",
    };
    for (0..input.len / 2) |i| {
        const idx = i * 2;
        const inst = Instr.new(input[idx .. idx + 2]);
        const actual = try inst.to_string(std.testing.allocator);
        defer std.testing.allocator.free(actual);
        try expectEqualSlices(u8, expected[i], actual);
    }
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
