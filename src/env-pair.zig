const EnvValue = @import("env-value.zig").EnvValue;
const EnvKey = @import("env-key.zig").EnvKey;

pub const EnvPair = struct {
    key: *EnvKey,
    value:*EnvValue
};