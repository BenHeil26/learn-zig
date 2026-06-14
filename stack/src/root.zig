const std = @import("std");
const testing = std.testing;

const StackError = error{OperationExceedsCapacity};

pub fn FixedSizeStack(comptime T: type) type {
    return struct {
        _items: []T,
        _capacity: usize,
        _length: usize,

        pub fn init(allocator: std.mem.Allocator, capacity: usize) !FixedSizeStack(T) {
            var buf = try allocator.alloc(T, capacity);
            return .{ ._items = buf[0..], ._capacity = capacity, ._length = 0 };
        }

        pub fn push(self: *FixedSizeStack(T), item: T) !void {
            if (self._length == self._capacity) {
                return StackError.OperationExceedsCapacity;
            }
            self._length += 1;
            self._items[self._length - 1] = item;
        }

        pub fn peek(self: *FixedSizeStack(T)) ?T {
            if (self._length == 0) return null;
            return self._items[self._length - 1];
        }

        pub fn pop(self: *FixedSizeStack(T)) ?T {
            if (self._length == 0) return null;
            self._length -= 1;
            return self._items[self._length];
        }
    };
}

pub fn DynamicStack(comptime T: type) type {
    return struct {
        const Node = struct {
            value: T,
            next: ?*Node,
        };

        _top: ?*Node,
        _length: usize,
        _allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) DynamicStack(T) {
            return .{
                ._top = null,
                ._length = 0,
                ._allocator = allocator,
            };
        }

        pub fn push(self: *DynamicStack(T), item: T) !void {
            var node = try self._allocator.create(Node);
            node.value = item;
            // notice we don't need to check if self._top is not null
            node.next = self._top;
            self._top = node;
        }

        pub fn peek(self: *DynamicStack(T)) ?T {
            if (self._top == null) {
                return null;
            }
            return self._top.?.*.value;
        }

        pub fn pop(self: *DynamicStack(T)) ?T {
            if (self._top == null) {
                return null;
            }
            const node = self._top.?;
            const value = node.*.value;
            self._top = node.*.next;
            self._allocator.destroy(node);
            return value;
        }
    };
}

test "FixedSizeStack push" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = try FixedSizeStack(u8).init(allocator, 3);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectError(StackError.OperationExceedsCapacity, stack.push(1));
}

test "DynamicStack push" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = DynamicStack(u8).init(allocator);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expect(true);
}

test "FixedSizeStack peek" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = try FixedSizeStack(u8).init(allocator, 3);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectEqual(4, stack.peek());
    try testing.expectEqual(4, stack.peek());
}

test "DynamicStack peek" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = DynamicStack(u8).init(allocator);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectEqual(4, stack.peek().?);
    try testing.expectEqual(4, stack.peek().?);
}

test "FixedSizeStack peek null" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = try FixedSizeStack(u8).init(allocator, 3);

    try testing.expectEqual(null, stack.peek());
}

test "DynamicStack peek null" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = DynamicStack(u8).init(allocator);

    try testing.expectEqual(null, stack.peek());
}

test "FixedSizeStack pop" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = try FixedSizeStack(u8).init(allocator, 3);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectEqual(4, stack.pop());
    try testing.expectEqual(10, stack.pop());
}

test "DynamicStack pop" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = DynamicStack(u8).init(allocator);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectEqual(4, stack.pop().?);
    try testing.expectEqual(10, stack.pop().?);
}

test "FixedSizeStack pop null" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = try FixedSizeStack(u8).init(allocator, 3);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectEqual(4, stack.pop());
    try testing.expectEqual(10, stack.pop());
    try testing.expectEqual(8, stack.pop());
    try testing.expectEqual(null, stack.pop());
}

test "DynamicStack pop null" {
    const allocator = std.debug.getDebugInfoAllocator();
    var stack = DynamicStack(u8).init(allocator);

    try stack.push(8);
    try stack.push(10);
    try stack.push(4);

    try testing.expectEqual(4, stack.pop());
    try testing.expectEqual(10, stack.pop());
    try testing.expectEqual(8, stack.pop());
    try testing.expectEqual(null, stack.pop());
}
