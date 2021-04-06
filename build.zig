const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = std.zig.CrossTarget{ .cpu_arch = .wasm32, .os_tag = .freestanding };
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("main", "src/main.zig");
    lib.addPackagePath("zalgebra", "deps/zalgebra/src/main.zig");
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.override_dest_dir = std.build.InstallDir{ .Custom = "." };
    lib.install();
}
