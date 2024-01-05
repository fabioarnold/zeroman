const std = @import("std");

const ProcessAssetsStep = @This();

const Stage = struct {
    path: []const u8,
    name: []const u8,
};

const WorldJson = struct {
    maps: []const struct {
        fileName: []const u8,
        height: i32,
        width: i32,
        x: i32,
        y: i32,
    },
};

const MapJson = struct {
    height: i32,
    width: i32,
    layers: []const LayerJson,

    const LayerJson = struct {
        data: ?[]const u8 = null,
        objects: ?[]const ObjectJson = null,
        type: []const u8,

        const ObjectJson = struct {
            class: ?[]const u8 = null,
            template: ?[]const u8 = null,
            x: i32,
            y: i32,
        };
    };
};

const TilesetJson = struct {
    tilecount: usize,
    columns: usize,
    image: []const u8,
    tiles: []const TileJson,

    const TileJson = struct {
        id: usize,
        class: []const u8,
    };
};

step: std.Build.Step,
builder: *std.Build,

stages: std.ArrayList(Stage),

pub fn create(b: *std.Build) *ProcessAssetsStep {
    const result = b.allocator.create(ProcessAssetsStep) catch @panic("memory");
    result.* = ProcessAssetsStep{
        .step = std.Build.Step.init(.{
            .id = .custom,
            .name = "process assets",
            .owner = b,
            .makeFn = make,
        }),
        .builder = b,
        .stages = std.ArrayList(Stage).init(b.allocator),
    };
    return result;
}

pub fn addStage(self: *ProcessAssetsStep, world_path: []const u8) void {
    self.stages.append(Stage{
        .path = world_path,
        .name = std.fs.path.stem(world_path),
    }) catch @panic("Could not add stage");
}

fn loadJson(comptime T: type, path: []const u8, allocator: std.mem.Allocator) !T {
    const max_file_size = 1_000_000;
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const file_contents = try file.readToEndAlloc(allocator, max_file_size);
    return (try std.json.parseFromSlice(T, allocator, file_contents, .{
        .ignore_unknown_fields = true,
    })).value;
}

fn make(step: *std.Build.Step, prog_node: *std.Progress.Node) !void {
    _ = prog_node;

    const self = @fieldParentPtr(ProcessAssetsStep, "step", step);
    const allocator = self.builder.allocator;

    for (self.stages.items) |stage| {
        const out_filename = try std.mem.concat(allocator, u8, &.{ stage.name, ".zig" });
        const out_path = try std.fs.path.join(allocator, &.{ "src/stages", out_filename });
        const out_file = try std.fs.cwd().createFile(out_path, .{});
        defer out_file.close();

        var buf = std.io.bufferedWriter(out_file.writer());
        var writer = buf.writer();

        try writer.writeAll("const Box = @import(\"../Box.zig\");\n");
        try writer.writeAll("const Tile = @import(\"../Tile.zig\");\n");
        try writer.writeAll("const Entity = @import(\"../Entity.zig\");\n");
        try writer.writeAll("const Room = @import(\"../Room.zig\");\n");
        try writer.writeAll("const Stage = @import(\"../Stage.zig\");\n\n");

        try writer.print("pub const {s} = Stage{{\n", .{stage.name});
        try writer.writeAll("  .rooms = &[_]Room{\n");

        std.debug.print("Processing stage {s}\n", .{stage.path});
        const world = try loadJson(WorldJson, stage.path, allocator);
        for (world.maps) |world_map| {
            const map_path = if (std.fs.path.dirname(stage.path)) |path|
                try std.fs.path.join(allocator, &.{ path, world_map.fileName })
            else
                world_map.fileName;
            std.debug.print("Processing map {s}\n", .{map_path});
            const map = try loadJson(MapJson, map_path, allocator);

            try writer.writeAll("    Room{\n");
            try writer.print("      .width = {},\n", .{map.width});
            try writer.print("      .height = {},\n", .{map.height});
            try writer.print("      .bounds = Box{{ .x = {}, .y = {}, .w = {}, .h = {} }},\n", .{
                world_map.x,
                world_map.y,
                world_map.width,
                world_map.height,
            });
            for (map.layers) |layer| {
                if (layer.data) |data| {
                    try writer.writeAll("      .data = &[_]u8{");
                    for (data, 0..) |d, i| {
                        if (i % @as(usize, @intCast(map.width)) == 0) {
                            try writer.writeAll("\n        ");
                        }
                        try writer.print("{d}, ", .{d - 1});
                    }
                    try writer.writeAll("\n      },\n");
                } else if (layer.objects) |objects| {
                    try writer.writeAll("      .entities = &[_]Entity{\n");
                    for (objects) |object| {
                        const template = object.template orelse continue;
                        if (std.mem.endsWith(u8, template, "zero.tj")) {
                            try writer.writeAll("Entity{.class = .player,");
                            try writer.print(".box = Box{{ .x = {}, .y = {}, .w = {}, .h = {} }},}},", .{ object.x + 8, object.y - 24, 16, 24 });
                        } else if (std.mem.endsWith(u8, template, "gopher.tj")) {
                            try writer.writeAll("Entity{.class = .gopher,");
                            try writer.print(".box = Box{{ .x = {}, .y = {}, .w = {}, .h = {} }},}},", .{ object.x + 4, object.y - 24, 16, 24 });
                        } else if (std.mem.endsWith(u8, template, "spike.tj")) {
                            try writer.writeAll("Entity{.class = .spike,");
                            try writer.print(".box = Box{{ .x = {}, .y = {}, .w = {}, .h = {} }},}},", .{ object.x, object.y - 24, 16, 24 });
                        }
                    }
                    try writer.writeAll("},\n");

                    // doors
                    for (objects) |object| {
                        const class = object.class orelse continue;
                        if (std.mem.eql(u8, class, "door")) {
                            const door_num: i32 = if (object.x == 0) 1 else 2;
                            const door_y = @divFloor(object.y - 16, 16);
                            try writer.print("      .door{}_y = {},\n", .{ door_num, door_y });
                        }
                    }
                }
            }
            try writer.writeAll("    },\n");
        }
        try writer.writeAll("  },\n");

        const tileset_path = try std.mem.concat(allocator, u8, &.{ "maps/tilesets/", stage.name, ".tsj" });
        const tileset = try loadJson(TilesetJson, tileset_path, allocator);
        const attribs = try allocator.alloc([]const u8, tileset.tilecount);
        @memset(attribs, "none");
        defer allocator.free(attribs);
        for (tileset.tiles) |tile| {
            attribs[tile.id] = tile.class;
        }
        try writer.writeAll("  .attribs = &[_]Tile.Attrib{");
        for (attribs, 0..) |a, i| {
            if (i % @as(usize, @intCast(tileset.columns)) == 0) {
                try writer.writeAll("\n    ");
            }
            try writer.print(".{s}, ", .{a});
        }
        try writer.writeAll("\n  },\n");

        try writer.writeAll("};\n");
        try buf.flush();
    }
}
