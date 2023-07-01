const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const Reader = std.fs.File.Reader;
const EnvKey = @import("env-key.zig").EnvKey;
const EnvValue = @import("env-value.zig").EnvValue;
const EnvGroup = @import("env-group.zig").EnvGroup;

pub const EnvReaderError = error{
    InvalidKeyCharacter,
    IsABlankLine,
    IsACommentLine,
    EndOfFile
};
/// Read an Env file in.
/// send an init'd env group and maxBufferSize (try to guess from file size -- usually a 1024 is good but w/e
/// if you run out of room it'll resize for you but to avoid that a little over is fine.
// You then send in a guess (You can pick 1 or 10, it'll resize based on this number when more are encountered. I suggest 16 as small projects < 10 and giga-large < 40-60 pairs) of how many pairs you think exist
pub fn readEnvFile(path : []u8, group: *EnvGroup, maxBufferSize: u32, countGuessOfEntities : u32) !void {
    const file =
        try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const reader = file.reader();
    var buffer = try group.allocator.alloc(u8, maxBufferSize);
    var maxEntities = countGuessOfEntities;
    defer group.allocator.free(buffer);
    try preInitPairs(&group, countGuessOfEntities, buffer);
    var tmp = 0;
    var fileEndReached = false;
    while(!fileEndReached){
        while(tmp < maxEntities) : (tmp = tmp + 1){
            nextPair(reader,&group.pairs[tmp]) catch |err| {
                switch (err){
                    EnvReaderError.IsABlankLine =>{
                        tmp = tmp - 1; // don't use the next space.
                    },
                    EnvReaderError.IsACommentLine=>{
                        tmp = tmp - 1; // don't use the next space.
                        const isMore = readUntilNewline(reader);
                        if(!isMore){
                            fileEndReached = true;
                            break;
                        }
                        continue;
                    },  
                    EnvReaderError.InvalidKeyCharacter =>{ //had a fault key so ignore the line
                          //this is a second case because later we might do something like emit a warning
                          tmp = tmp - 1; // don't use the next space.
                          continue;
                    },

                    else =>{ return err; }
                }
            };
        }
        if(fileEndReached){
           break;
       }
       //resize
        maxEntities = maxEntities + countGuessOfEntities;
        reInitPairs(&group,maxEntities,buffer); //grow the buffer cuz we exited the loop but didn't hit end of file.


    }
    group.len = tmp;
}
pub fn freePairs(self: *EnvGroup) void {
    self.allocator.free(self.keys);
    self.allocator.free(self.values);
    self.allocator.free(self.pairs);
}


pub fn reInitPairs(self: *EnvGroup, amount: usize,reusable_buffer: []u8) !void {
    const oldSize = self.pairs.len;
    const newSize = oldSize +  amount;
    try self.allocator.resize(self.pairs,newSize);
    try self.allocator.resize(EnvPair, newSize);
    try self.allocator.resize(EnvKey, newSize);

    var tmp: u32 = oldSize;
    while (tmp < newSize) : (tmp = tmp + 1) {
        self.pairs[tmp].key = &self.keys[tmp];
        std.debug.print("Placing  {}\n", .{  self.pairs[tmp].key.keyIndex});
        try self.pairs[tmp].key.init(self.allocator,reusable_buffer);
        self.pairs[tmp].value = &self.values[tmp];
        try self.pairs[tmp].value.init(self.allocator,reusable_buffer);
    }
}

pub fn preInitPairs(self: *EnvGroup, amount: usize,reusable_buffer: []u8) !void {
    self.pairs = try self.allocator.alloc(EnvPair, amount);
    self.keys = try self.allocator.alloc(EnvKey, amount);
    self.values = try self.allocator.alloc(EnvValue, amount);
    var tmp: u32 = 0;
    while (tmp < amount) : (tmp = tmp + 1) {
        self.pairs[tmp].key = &self.keys[tmp];
        std.debug.print("Placing  {}\n", .{  self.pairs[tmp].key.keyIndex});
        try self.pairs[tmp].key.init(self.allocator,reusable_buffer);
        self.pairs[tmp].value = &self.values[tmp];
        try self.pairs[tmp].value.init(self.allocator,reusable_buffer);
    }
}
pub fn nextPair(reader: Reader, pair: *EnvPair) !void {

    std.debug.print("Reading Key  \n", .{});
    try nextKey(reader, pair.key);
    if(pair.key.keyIndex != 0){
        //we read some sort of key.
        try pair.key.finalize_key();

    }else{
        //we didn't read any key info in
        //set the buffer to undefined
        pair.key.key = undefined;
    }

    std.debug.print("Reading Value  \n", .{});
    try nextValue(reader, pair.value);
    try pair.value.finalize_value();
    std.debug.print("Read   \n", .{});
}
pub fn nextValue(
    reader: Reader,
    value: *EnvValue,
) !void {
    var end = false;

    while (!end) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => return,
            else => |e| return e,
        };

        end = try value.processValueNextValue(byte);
    }
    std.debug.print("End of Value \n", .{});

}

///reads until a new line or end of stream, return true if there is more
pub fn readUntilNewline(
    reader: Reader,
) !bool {
    var end = false;

    while (!end) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => {
                std.debug.print("cleared to end of stream \n", .{});
                return false;
            },
            else => |e| return e,
        };
        if(byte == '\n'){
            return true;
        }

    }
    unreachable;
}

pub fn nextKey(
    reader: Reader,
    key: *EnvKey,
) !void {
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => return,
            else => |e| return e,
        };
        const isLastKeyValue =try key.processKeyNextValue(byte);

        std.debug.print("Is Last? :  {any}   \n", .{isLastKeyValue});
        if (isLastKeyValue) {
            break;
        }
    }

}
