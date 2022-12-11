import schlib.strawman;
struct InputRangeModel {
    Any!"Element" front();
    void popFront();
    bool empty();
}

struct ForwardRangeModel {
    Self save();
    mixin isAlso!InputRangeModel;
}

struct BidirectionalRangeModel {
    Any!"Element" back();
    void popBack();
    mixin isAlso!ForwardRangeModel;
}

struct RandomAccessRangeModel {
    Any!"Element" opIndex(size_t idx);
    size_t length();
    mixin isAlso!BidirectionalRangeModel;
}

struct DummyRange {
    int front;
    void popFront() {}
    bool empty() { return false; }
    int opIndex(size_t idx) { return 0; }
    int back;
    void popBack() {}
    size_t length;
    DummyRange save() { return this; }
}

pragma(msg, isStrawman!(DummyRange, RandomAccessRangeModel));

void test() {
    import std.traits;
    import std.meta;
    alias Target = DummyRange;
    alias Strawman = RandomAccessRangeModel;
    mixin(mixinForStrawman!Strawman);
}

void main() {}
