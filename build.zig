const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const wasm = b.addSharedLibrary("main", "src/main.zig", .unversioned);
    wasm.setBuildMode(mode);
    wasm.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    wasm.install();
}
