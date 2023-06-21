const std = @import("std");
pub const MAX_ENV_VALUE_LENGTH = 32768;
const EnvPair = @import("env-pair.zig").EnvPair;
const VariablePosition = @import("variable-position.zig").VariablePosition;
const InterpolationHelper = @import("interpolation-helper.zig");
const processValueInsideQuoted = @import("quote-helper.zig").processValueInsideQuoted;
const incrementInterpolDepth= InterpolationHelper.incrementInterpolDepth;
const decrementInterpolDepth= InterpolationHelper.decrementInterpolDepth;


pub const EnvValue = struct {
    const Self = @This();
    value: []u8 = undefined, //reuse stack buffer for speed
    isParsingVariable: bool = false,
    interpolations: []VariablePosition = undefined,
    interpolationIndex: u8 = 0,
    quoted: bool = false,
    tripleQuoted: bool = false,
    doubleQuoted: bool = false,
    tripleDoubleQuoted: bool = false,
    valueIndex: u8 = 0,
    allocator: *std.mem.Allocator = undefined,
    isAlreadyInterpolated : bool = false,
    isBeingInterpolated : bool = false,
    didOverFlow :bool = false,

    pub fn free_value(self: *EnvValue) void {
        self.allocator.free(self.value);
    }
    pub fn init(self: *Self, allocator: *std.mem.Allocator, tmp_buffer: []u8) !void {
        std.debug.print("creating intOp array   \n",.{ });
        self.valueIndex = 0;
        self.interpolationIndex = 0;
        var tmp = try allocator.alloc(VariablePosition, 8);
        self.interpolations = tmp;
        self.value = tmp_buffer;
        self.allocator = allocator;
        self.isAlreadyInterpolated= false;
        self.tripleQuoted = false;
        self.didOverFlow = false;
        self.doubleQuoted = false;
        self.quoted= false;
        self.isBeingInterpolated = false;
    }

    pub fn hadInterpolation(self: *Self) bool {
        return self.interpolationIndex  > 0;
    }



    pub fn finalize_value(self: *Self) !void {
        if (self.valueIndex <= 0) {
            return error.ValueWouldBeEmpty;
        }
        std.debug.print("Finalizing Value of length {} \n", .{self.valueIndex});
        var tmp = try self.allocator.alloc(u8, self.valueIndex);
        const bufferSlice = self.value[0..self.valueIndex];
        std.mem.copy(u8, tmp, bufferSlice);
        self.value = tmp;
    }


   pub fn placeValueCharacter(self: *Self, value: u8) !void {
        if (self.valueIndex >= MAX_ENV_VALUE_LENGTH) {
            //emit warning we are over allowed buffer length
            std.debug.print("Value {c} can not be stored. ENV has a max size. \n", .{value});
            self.didOverFlow = true;
            return;
            //todo: handle overflow -- probably will just ignore. ENV can't hold more than 32k on linux.
            //return;
        }
        std.debug.print("Adding character {c} \n", .{value});
        self.value[self.valueIndex] = value;
        self.valueIndex = self.valueIndex + 1;
        std.debug.print(" {s} \n", .{self.value[0..20]});
    }
    pub fn processValueNextValue(self: *Self, value: u8) !bool {

        if (self.didOverFlow) {
            //we've told the user they overflowed. Just return; Nothing else can be processed.
            return true;
        }
        if (self.quoted) { // process value if we have detected this is a single quoted value
            return processValueInsideQuoted(self,value);
        }
        if (value == '\'') { //single quote
            if (self.isAtStart()) { //at the start
                self.quoted = true;
                return false;
            }
        }

        if (value == '\n') {
            std.debug.print("Newline hit on double/no quote\n", .{});
            return true;
        }
        if (value == '\r') {
            return false;
        }
        switch(value) {
            't'=>{

            },
            'n'=>{

            },
            'r'=>{

            },
            'f'=>{

            },
            'b'=>{

            },
            '"'=>{

            },
            '\''=>{

            },
            'u'=>{

            },
            else =>{

            }
        }


        if (!self.isParsingVariable) {
            if (value == '{') { //ok we have either no double quote or are double quoted, process if we find ${}
                const count = self.previousIsDollarSign();
                if (count != 0) {
                    try incrementInterpolDepth(self,count);
                }
            }
        }else {
            std.debug.print("scanning variable name: {c}\n", .{value});
            if (value == '}') {
                decrementInterpolDepth(self);
            }
        }

        try self.placeValueCharacter(value);
        return false;
    }


    pub fn fourCharactersAgoNewline(self: *Self) bool {
        if (self.valueIndex < 4) {
            return false;
        }
        return self.value[self.valueIndex - 4] == '\n';
    }
    pub fn previousSingleQuoteCount(self: *Self) u8 {
        var tmp = self.valueIndex;
        var count: u8 = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '\'') {
                count = count + 1;
            }
            if (count >= 3) {
                //avoid """"""""""""""""""""""""
                break;
            }
            tmp = tmp - 1;
        }
        return count;
    }
    pub fn previousDoubleQuoteCount(self: *Self) u8 {
        var tmp = self.valueIndex;
        var count: u8 = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '"') {
                count = count + 1;
            }
            if (count >= 3) {
                //avoid """"""""""""""""""""""""
                break;
            }
            tmp = tmp - 1;
        }
        return count;
    }
    pub fn isAtStart(self: *Self) bool {
        return self.valueIndex == 0;
    }
    pub fn fourCharactersAgoStart(self: *Self) bool {
        return self.valueIndex == 3;
    }
    // checks for $ being behind the { and ignoring whitespace
    pub fn previousIsDollarSign(self: *Self) u8 {
        if (self.valueIndex == 0) {
            return 0;
        }
        var tmp = self.valueIndex - 1;
        var count : u8 = 0;
        while(tmp >= 0 ): (tmp = tmp - 1 ){
              count = count  + 1;

              if(self.value[tmp] == '$'){
                return count;
              }
              if(self.value[tmp] == ' '){
                  continue;
              }
              return 0;
        }
        return count;

    }
};

