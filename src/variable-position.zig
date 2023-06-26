pub const VariablePosition = struct {
    variableStart: u32,
    variableEnd:u32=undefined,
    dollarSign:u32,
    endBrace: u32 = undefined,
    startBrace: u32 = undefined,
};