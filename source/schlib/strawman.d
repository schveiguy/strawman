module schlib.strawman;
import std.meta;
import std.traits;

struct Any(string t, Types...) {
    enum tag = t;
    alias types = Types;
}

struct Self {}

mixin template isAlso(T...) {
    alias _alsoLike = T;
}

template isOneOf(T, Types...)
{
    enum isType(A) = is(A == T);
    enum isOneOf = Filter!(isType, Types).length > 0;
}

template ExprType(alias a)
{
    static if(is(ReturnType!(typeof(a)) T) || is(typeof(a) T))
        alias ExprType = T;
}

template ReplaceAny(NS, P...)
{
    static if(P.length == 0)
        alias ReplaceAny = P;
    else static if(is(P[0] == Any!T, T...))
        alias ReplaceAny = mixin("AliasSeq!(NS." ~ T[0] ~ ", .ReplaceAny!(NS, P[1 .. $]))");
    else
        alias ReplaceAny = AliasSeq!(P[0], ReplaceAny!(NS, P[1 .. $]));
}

private void generateStatements(alias T)(string container, string identifier,
                                ref string[] statements,
                                ref string[] declarations,
                                ref string[string] tags)
{
    // for a struct type, recurse on all the members.
    static if(is(T == struct)) {
        static foreach(mem; __traits(allMembers, T)) {{
            alias m = __traits(getMember, T, mem);
            static if(mem == "_alsoLike") {
                // recurse on the types in there
                static foreach(i, subT; __traits(getMember, T, mem)) {
                    generateStatements!subT(container ~ "._alsoLike[" ~ i.stringof ~ "]", identifier, statements, declarations, tags);
                }
            } else static if(is(m)) {
                // TODO: how to handle types?
            } else {
                // recurse
                generateStatements!m(container, identifier ~ "." ~ mem, statements, declarations, tags);
            }
        }}
    } else if(is(typeof(T) == function)) {
        // it's a function, put in tests for it.
        alias RT = ReturnType!T;
        string newStatement = "{";
        static if(is(RT == Any!P, P...))
        {
            // this is a wild type, handle it
            if(!(P[0] in tags))
            {
                tags[P[0]] = "alias " ~ P[0] ~ " = ExprType!(Target" ~ identifier ~ ");";
                static if(P.length > 1) { // must be one of a set of types
                    declarations ~= "static assert(isOneOf!(_AnyTypes." ~ P[0] ~ ", ReturnType!(" ~ container ~ identifier ~ ").types));";
                }
            }
            newStatement ~= "alias RT = _AnyTypes." ~ P[0] ~ ";";
        } else static if(is(RT == Self)) {
            newStatement ~= "alias RT = Target;";
        } else static if(is(RT == Self*)) {
            newStatement ~= "alias RT = Target*;";
        } else {
            newStatement ~= "alias RT = ReturnType!(" ~ container ~ identifier ~ ");";
        }

        static if(Parameters!T.length > 0) {
            newStatement ~= "auto params = ReplaceAny!(_AnyTypes, Parameters!(" ~ container ~ identifier ~ ")).init; " ~ (is(RT == void) ? "tgt" : "RT _res = tgt") ~ identifier ~ "(params);";
        } else {
            newStatement ~= (is(RT == void) ? "tgt" : "RT _res = tgt") ~ identifier ~ ";";
        }
        statements ~= newStatement ~ "}";
    } else {
        // field?
        string newStatement = "{";
        static if(is(typeof(T) == Any!P, P...))
        {
            // handle the wild type.
            if(!(P[0] in tags))
            {
                tags[P[0]] = "alias " ~ P[0] ~ " = ExprType!(Target" ~ identifier ~ ");";
                static if(P.length > 1) { // must be one of a set of types
                    declarations ~= "static assert(isOneOf!(_AnyTypes." ~ P[0] ~ ", " ~ container ~ identifier ~ ".types));";
                }
            }
            newStatement ~= "_AnyTypes." ~ P[0] ~ " _res;";
        } else static if(is(typeof(T) == Self)) {
            newStatement ~= "Target _res;";
        } else static if(is(typeof(T) == Self*)) {
            newStatement ~= "Target* _res;";
        } else {
            newStatement ~= "typeof(" ~ container ~ identifier ~ ") _res;";
        }

        statements ~= newStatement ~
            "_res = tgt" ~ identifier ~ ";" ~
            "tgt" ~ identifier ~ " = _res;}";
    }
}

string generateStatements(T)()
{
    string[] statements = ["Target tgt = Target.init;"];
    string[] declarations;
    string[string] tags;
    generateStatements!T("Strawman", "", statements, declarations, tags);

    // now, create a string that can be mixed in for testing
    string result;
    result ~= "static struct _AnyTypes {\n";
    foreach(s; tags) {
        result ~= s;
        result ~= "\n";
    }
    result ~= "}\n";
    foreach(s; declarations) {
        result ~= s;
        result ~= "\n";
    }
    foreach(s; statements) {
        result ~= s;
        result ~= "\n";
    }
    return result;
}

enum mixinForStrawman(Strawman) = generateStatements!Strawman();

template isStrawman(Target, Strawman)
{
    pragma(msg, mixinForStrawman!Strawman);
    enum isStrawman = __traits(compiles, {
       mixin(mixinForStrawman!Strawman);
    });
}
