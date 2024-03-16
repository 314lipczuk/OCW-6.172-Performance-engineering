const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const RandGen = std.rand.DefaultPrng;
const Random = std.rand.Random;
pub fn main() !void {
    const ally = std.heap.page_allocator;
    comptime var N = 1024;
    var a = try Matrix(u32, N).init_random(ally);
    var b = try Matrix(u32, N).init(ally, 0);
    var c = try Matrix(u32, N).init(ally, 0);
    for (0..N) |i| {
        b.data[i * N + i] = 2;
    }

    const t1 = try std.time.Instant.now();
    a.multiply_matrix(&b, &c);
    //Matrix.multiply_matrix(&a, &b, &c);
    const t2 = try std.time.Instant.now();
    const time_ns = std.time.Instant.since(t2, t1);
    const time_ms: f32 = @as(f32, @floatFromInt(time_ns)) / @as(f32, 1_000_000);
    const time_s: f32 = @as(f32, @floatFromInt(time_ns)) / @as(f32, 1_000_000_000);
    print("Timing for a {d}x{d} matrix multiply:\n{d:5.0001}ms\n{d:5.0001}s\n", .{ N, N, time_ms, time_s });
    a.deinit(ally);
    b.deinit(ally);
    c.deinit(ally);
}

test "Matrix row ordering " {
    // setup the matrices
    const ally = std.heap.page_allocator;
    comptime var N = 2048;
    var a = try Matrix(u32, N).init_random(ally);
    var b = try Matrix(u32, N).init(ally, 0);
    var c = try Matrix(u32, N).init(ally, 0);
    for (0..N) |i| {
        b.data[i * N + i] = 2;
    }

    // check each row ordering for performance and print results
    for (0..6) |ordering| {
        const t1 = try std.time.Instant.now();
        a.multiply_matrix_with_ordering(&b, &c, ordering);
        const t2 = try std.time.Instant.now();
        const time_ns = std.time.Instant.since(t2, t1);
        const time_ms: f32 = @as(f32, @floatFromInt(time_ns)) / @as(f32, 1_000_000);
        const time_s: f32 = @as(f32, @floatFromInt(time_ns)) / @as(f32, 1_000_000_000);
        print("\n--------------\nOrdering {d}:\n{d:5.0001}ms\n{d:5.0001}s\n--------------\n", .{ @as(u64, ordering), time_ms, time_s });
        c.multiply_scalar(0);
    }
    a.deinit(ally);
    b.deinit(ally);
    c.deinit(ally);
}

pub fn Matrix(comptime Contained: type, comptime N: comptime_int) type {
    return struct {
        const Self = @This();
        data: []Contained,

        pub fn init(comptime ally: Allocator, comptime default_value: comptime_int) !Self {
            var data: []Contained = try ally.alloc(Contained, N * N);
            for (0..data.len) |d| {
                data[d] = default_value;
            }
            return Self{ .data = data };
        }

        pub fn init_random(comptime ally: Allocator) !Self {
            var rand = RandGen.init(0);
            var data: []Contained = try ally.alloc(Contained, N * N);

            for (0..data.len) |d| {
                data[d] = Random.uintLessThan(rand.random(), Contained, 25);
            }
            return Self{ .data = data };
        }

        pub fn add_scalar(self: *Self, other: Contained) void {
            for (0..self.data.len) |s| {
                self.data[s] += other;
            }
        }

        pub fn show(self: *Self) void {
            std.debug.print("\nMatrix {d}x{d}\n", .{ N, N });
            for (0..N) |i| {
                std.debug.print("{any}\n", .{self.data[i * N .. i * N + N]});
            }
        }

        pub fn add_matrix(self: *Self, other: *Self) void {
            std.debug.assert(self.data.len == other.data.len);
            for (0..self.data.len, 0..other.data.len) |_, o| {
                self.data[o] += other.data[o];
            }
        }

        pub fn multiply_scalar(self: *Self, other: Contained) void {
            for (0..self.data.len) |i| {
                self.data[i] *= other;
            }
        }

        pub fn multiply_matrix(self: *Self, other: *Self, result: *Self) void {
            assert(self.data.len == other.data.len);
            const a = self;
            const b = other;
            for (0..N) |c_row| {
                for (0..N) |c_col| {
                    for (0..N) |i| {
                        result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                    }
                }
            }
        }

        pub fn multiply_matrix_with_ordering(self: *Self, other: *Self, result: *Self, ordering: u64) void {
            assert(self.data.len == other.data.len);
            const a = self;
            const b = other;
            switch (ordering) {
                0 => {
                    for (0..N) |c_row| { // A
                        for (0..N) |c_col| { // B
                            for (0..N) |i| { // C
                                result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                            }
                        }
                    }
                },
                1 => {
                    for (0..N) |c_row| { // A
                        for (0..N) |i| { // C
                            for (0..N) |c_col| { // B
                                result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                            }
                        }
                    }
                },
                2 => {
                    for (0..N) |c_col| { // B
                        for (0..N) |c_row| { // A
                            for (0..N) |i| { // C
                                result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                            }
                        }
                    }
                },
                3 => {
                    for (0..N) |c_col| { // B
                        for (0..N) |i| { // C
                            for (0..N) |c_row| { // A
                                result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                            }
                        }
                    }
                },
                4 => { // good one
                    for (0..N) |i| { // C
                        for (0..N) |c_row| { // A
                            for (0..N) |c_col| { // B
                                result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                            }
                        }
                    }
                },
                5 => {
                    for (0..N) |i| { // C
                        for (0..N) |c_col| { // B
                            for (0..N) |c_row| { // A
                                result.data.ptr[c_row * N + c_col] += a.data[c_row * N + i] * b.data[c_col + N * i];
                            }
                        }
                    }
                },
                else => unreachable,
            }
        }

        pub fn at(self: Self, row: usize, column: usize) Contained {
            return self.data[row * N + column];
        }

        pub fn deinit(self: *Self, comptime ally: Allocator) void {
            ally.free(self.data);
        }
    };
}
