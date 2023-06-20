const EnvValue = @import("env-value.zig").EnvValue;
const EnvPair = @import("env-pair.zig").EnvPair;
const VariablePosition = @import("variable-position.zig").VariablePosition;
const std = @import("std");

pub fn free_interpolation_array(self: *EnvValue) void {
    std.debug.print("freeing interpolation array   \n", .{});
    self.allocator.free(self.interpolations);
    std.debug.print("freed interpolation array   \n", .{});
}
pub fn resizeInterpolationArray(self: *EnvValue) !void {
    std.debug.print("resizing ", .{});
    var tmp = try self.allocator.alloc(VariablePosition, self.interpolations.len + 1000);
    std.mem.copy(VariablePosition, tmp, self.interpolations);
    self.allocator.free(self.interpolations);
    self.interpolations = tmp;
}
fn get_size_for_interpolation(self: *EnvValue, pairs: []EnvPair) i8 {
    var tmp = self.interpolationIndex;

    std.debug.print("We have {} variables\n", .{tmp});
    var resizeNeeded: i8 = 0;
    while (tmp > 0) : (tmp = tmp - 1) {
        const item = self.interpolations[tmp - 1];
        const start = item.variableStart;
        const end = item.variableEnd;

        const length: i8 = @intCast(i8, item.endBrace - item.dollarSign);
        const variableLength = end - start;
        std.debug.print("Pol {} start : {} end: {} length {} , variable name length {}  \n", .{ tmp, start, end, length, variableLength });
        const targetKey = self.value[start .. end];
        std.debug.print("looking for {s}\n", .{targetKey});
        for (pairs) |pair| {
            std.debug.print("looking at {s}    \n", .{pair.key.key});
            if (std.mem.eql(u8, pair.key.key, targetKey)) {
                //this is the one
                const pairValueLen = @intCast(i8, pair.value.value.len);
                std.debug.print("found {s}  at {} with length {} to replace old length {} \n", .{ targetKey, pair.value.value.len, pairValueLen, length });

                if (pair.value.value.len > length) {
                    resizeNeeded += @intCast(i8, pairValueLen - length);
                } else if (pair.value.value.len < length) {
                    resizeNeeded -= @intCast(i8, pairValueLen - length);
                }
                std.debug.print("Current Diff in string size {}    \n", .{resizeNeeded});
            }
        }
    }

    return resizeNeeded; //return it because for smaller you resize after
}
pub fn interpolate_value(self: *EnvValue, pairs: []EnvPair) !void {
    if (self.interpolationIndex < 1) {
        //it had none or one with a hanging chad
        return;
    }

    //get the difference in interpolation size and current size
    const resizeNeeded = get_size_for_interpolation(self, pairs);
    std.debug.print("Need to resize buffer {} for value size change    \n", .{resizeNeeded});
    if (resizeNeeded == 0) {
        //weird edge case for later, otherwise we'll optimize for the normal cases where the size is either smaller or larger
    }
    //create a tmp amount for the exact size
    var tmp = try self.allocator.alloc(u8, @intCast(usize, @intCast(i8, self.valueIndex) + resizeNeeded));

    try copy_interpolation_values(self, tmp, pairs);
}
fn copy_interpolation_values(self: *EnvValue, new_buffer: []u8, pairs: []EnvPair) !void {
    var tmp = self.interpolationIndex ;
    var copy_index: u8 = 0;
    var buffer_index: u8 = 0;

    while (tmp > 0) : (tmp = tmp - 1) {
        const item = self.interpolations[tmp - 1];
        const start = item.variableStart;
        const end = item.variableEnd;
        //catch up the new buffer to where we are about to interpol
        // const length = end - start;
        if (start > buffer_index) {
            const amount = start - buffer_index;
            //copy the constant text between variables in
            const copy_end = copy_index + amount;
            const buffer_end = buffer_index + amount;
            var newBufferSlice = new_buffer[copy_index..copy_end];
            const oldBufferSlice = self.value[buffer_index..buffer_end];
            std.mem.copy(u8, newBufferSlice, oldBufferSlice);
            buffer_index = end; // now from the source array we are caught up to where the variable ended
            copy_index = copy_end;
        }
        //copy the variable value in
        const valueSlice = self.value[start..end];
        const envpair = find_pair(pairs, valueSlice) catch |x| switch (x) {
            error.PairNotFound => continue, //todo: catch up buffer_start (we'll fix this in a test csae)
            else => |e| return e,
        };

        const copy_end: u8 = copy_index + @intCast(u8, envpair.value.value.len);
        std.mem.copy(u8, new_buffer[copy_index..copy_end], envpair.value.value);
        copy_index = copy_end;
        //zig, because for loops are while

    }
}
pub fn incrementInterpolDepth(self: *EnvValue, count: u8) !void {
    if (self.interpolationIndex >= self.interpolations.len) {
        std.debug.print("resizing variable array \n", .{});
        try resizeInterpolationArray(self);
    }
    self.isParsingVariable = true;
    self.interpolations[self.interpolationIndex] = VariablePosition{
        .variableStart = self.valueIndex + 1,

        .dollarSign = self.valueIndex - count,
    }; // self.valueIndex + 1;
    std.debug.print("interpolation starts at {}, dollar sign at {} :{}\n", .{ self.valueIndex + 1, self.valueIndex - count, self.interpolationIndex });
}
pub fn decrementInterpolDepth(self: *EnvValue) void {
    self.isParsingVariable = false;
    std.debug.print("interpolation ends at {} :{}\n", .{ self.valueIndex, self.interpolationIndex });
    self.interpolations[self.interpolationIndex].endBrace = self.valueIndex + 1;
    self.interpolations[self.interpolationIndex].variableEnd = self.valueIndex;

    self.interpolationIndex = self.interpolationIndex + 1;
    //todo: clean whitespace out of variable start and end so we can do $ { varName }
}
pub fn find_pair(pairs: []EnvPair, inter_value: []u8) !EnvPair {
    for (pairs) |pair| {
        if (std.mem.eql(u8, pair.value.value, inter_value)) {
            return pair;
        }
    }
    return error.PairNotFound;
}
