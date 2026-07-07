module MlxtranTypst

using TreeSitter

export mlxtran_to_typst, equation_to_typst

const TS = TreeSitter

const GRAMMAR_DIR = normpath(joinpath(@__DIR__, "..", ".."))
const PARSER = Ref{TS.Parser}()

function parser()
    isassigned(PARSER) || (PARSER[] = TS.Parser(GRAMMAR_DIR))
    return PARSER[]
end

# --- Identifier / greek prettification -------------------------------------

const GREEK = Set([
    "alpha", "beta", "gamma", "delta", "epsilon", "zeta", "eta", "theta",
    "iota", "kappa", "lambda", "mu", "nu", "xi", "pi", "rho", "sigma", "tau",
    "upsilon", "phi", "chi", "psi", "omega",
])

const UPPER_GREEK = Set([
    "Gamma", "Delta", "Theta", "Lambda", "Xi", "Pi", "Sigma", "Upsilon",
    "Phi", "Psi", "Omega",
])

function greek_symbol(seg::AbstractString)
    seg in UPPER_GREEK && return seg
    lowercase(seg) in GREEK && return lowercase(seg)
    return nothing
end

# Split a name segment (no underscore) into a math symbol and any subscript
# tokens peeled from it. A whole greek name or single letter is the symbol as
# is. A greek name followed by a camelCase boundary (uppercase letter or digit)
# peels into greek + subscript, e.g. `alphaE` -> (alpha, ["E"]). Everything else
# is quoted, since typst treats an undefined multi-letter identifier as an error.
function peel_head(seg::AbstractString)
    sym = greek_symbol(seg)
    sym === nothing || return (sym, String[])
    for len in (length(seg) - 1):-1:1
        g = greek_symbol(seg[1:len])
        g === nothing && continue
        rest = seg[(len + 1):end]
        (isuppercase(rest[1]) || isdigit(rest[1])) && return (g, [rest])
    end
    length(seg) == 1 && return (seg, String[])
    return ("\"$seg\"", String[])
end

function subscript(sym::AbstractString, tail::AbstractVector)
    isempty(tail) && return sym
    if length(tail) == 1 && (all(isdigit, tail[1]) || length(tail[1]) == 1)
        return "$(sym)_$(tail[1])"
    end
    return "$(sym)_(\"$(join(tail, ","))\")"
end

"""Render an mlxtran identifier as typst math, mapping greek names (including
camelCase prefixes) and turning trailing segments into subscripts."""
function prettify(name::AbstractString)
    parts = split(name, "_")
    sym, peeled = peel_head(parts[1])
    return subscript(sym, vcat(peeled, parts[2:end]))
end

# --- Precedence -------------------------------------------------------------

function op_prec(op::AbstractString)
    op in ("||", "|") && return 1
    op in ("&&", "&") && return 2
    op in ("+", "-") && return 4
    op in ("*", "/") && return 5
    op == "^" && return 7
    return 100
end

op_text(node, src) = TS.slice(src, TS.child(node, "operator"))

"""The inner expression of a parenthesized wrapper, transparently."""
function unwrap(node)
    TS.node_type(node) == "parenthesized_expression" || return node
    return unwrap(TS.named_child(node, 1))
end

function node_prec(node, src)
    n = unwrap(node)
    t = TS.node_type(n)
    t == "binary_expression" && return op_prec(op_text(n, src))
    t == "unary_expression" && return 6
    t == "comparison" && return 0
    return 100
end

"""Convert `child`, wrapping in parens when its precedence loses against the
parent operator. `losing` marks the associativity-losing side."""
function operand(child, parent_prec, losing, src)
    s = to_typst(child, src)
    p = node_prec(child, src)
    (p < parent_prec || (p == parent_prec && losing)) && return "($s)"
    return s
end

# --- Function names ---------------------------------------------------------

const FUNCTIONS = Set([
    "exp", "log", "ln", "sin", "cos", "tan", "sqrt", "abs",
    "floor", "ceil", "min", "max",
])

function func_name(name::AbstractString)
    name in FUNCTIONS && return name
    name == "log10" && return "log_10"
    name == "log2" && return "log_2"
    return "\"$name\""
end

# --- Node conversion --------------------------------------------------------

function binary(node, src)
    op = op_text(node, src)
    left = TS.child(node, "left")
    right = TS.child(node, "right")
    if op == "/"
        return "($(to_typst(left, src)))/($(to_typst(right, src)))"
    elseif op == "^"
        return "$(operand(left, 7, true, src))^($(to_typst(right, src)))"
    end
    sym = op == "*" ? "dot" :
          op in ("||", "|") ? "or" :
          op in ("&&", "&") ? "and" : op
    p = op_prec(op)
    return "$(operand(left, p, false, src)) $sym $(operand(right, p, true, src))"
end

function unary(node, src)
    op = op_text(node, src)
    sym = op in ("!", "~") ? "not " : op
    return sym * operand(TS.child(node, "operand"), 6, false, src)
end

function comparison(node, src)
    op = op_text(node, src)
    sym = op == "==" ? "=" : op in ("!=", "~=") ? "eq.not" : op
    return "$(to_typst(TS.child(node, "left"), src)) $sym $(to_typst(TS.child(node, "right"), src))"
end

function call(node, src)
    fname = func_name(TS.slice(src, TS.child(node, "function")))
    args = TS.child(node, "arguments")
    parts = [to_typst(c, src) for c in named_children(args)]
    return "$fname($(join(parts, ", ")))"
end

"""Render a number, turning E-notation into `mantissa times 10^(exp)` so typst
does not treat the `e` as a variable."""
function number(text::AbstractString)
    m = match(r"^([0-9]*\.?[0-9]+)[eE]([+-]?[0-9]+)$", text)
    m === nothing && return String(text)
    mantissa, exponent = m.captures
    exponent = replace(exponent, r"^\+" => "")
    return mantissa == "1" ? "10^($exponent)" : "$mantissa times 10^($exponent)"
end

"""State name of a `ddt_<state>` derivative token as a d/dt fraction."""
function derivative(node, src)
    state = replace(TS.slice(src, node), r"^ddt_" => "")
    return "(dif $(prettify(state)))/(dif t)"
end

function assignment(node, src)
    return "$(target_typst(node, src)) = $(to_typst(TS.child(node, "value"), src))"
end

function to_typst(node, src)
    t = TS.node_type(node)
    t == "assignment" && return assignment(node, src)
    t == "expression_statement" && return to_typst(TS.named_child(node, 1), src)
    t == "binary_expression" && return binary(node, src)
    t == "unary_expression" && return unary(node, src)
    t == "comparison" && return comparison(node, src)
    t == "parenthesized_expression" && return to_typst(TS.named_child(node, 1), src)
    t == "call" && return call(node, src)
    t == "pair" && return "$(to_typst(TS.child(node, "key"), src)) = $(to_typst(TS.child(node, "value"), src))"
    t == "identifier" && return prettify(TS.slice(src, node))
    t == "derivative" && return derivative(node, src)
    t == "number" && return number(TS.slice(src, node))
    t == "string" && return "\"$(strip(TS.slice(src, node), '\''))\""
    return String(TS.slice(src, node))
end

# --- Traversal --------------------------------------------------------------

const SECTIONS = Set(["source_file", "angle_section", "square_section"])

# Model equations live in these blocks; other blocks (DEFINITION, OBSERVATION)
# and bare section statements (FILEINFO, SETTINGS, TASKS) are configuration.
const EQUATION_BLOCKS = Set(["EQUATION:", "PK:", "ODE:"])

is_equation(node) =
    TS.node_type(node) == "expression_statement" ||
    (TS.node_type(node) == "assignment" &&
     TS.node_type(TS.child(node, "value")) != "list")

function target_typst(assign, src)
    target = TS.child(assign, "target")
    TS.node_type(target) == "derivative" && return derivative(target, src)
    return prettify(TS.slice(src, target))
end

# Branches of an `if_statement` as (condition-or-nothing, body-statements). The
# condition is the first named child of the `if`/`elseif`; `else` has none.
function if_branches(node)
    kids = collect(named_children(node))
    branches = Any[]
    body = filter(k -> !(TS.node_type(k) in ("elseif_clause", "else_clause")), kids[2:end])
    push!(branches, (kids[1], body))
    for k in kids
        t = TS.node_type(k)
        if t == "elseif_clause"
            ck = collect(named_children(k))
            push!(branches, (ck[1], ck[2:end]))
        elseif t == "else_clause"
            push!(branches, (nothing, collect(named_children(k))))
        end
    end
    return branches
end

# `nothing` in a guard marks an `else` branch.
function guard_label(parts)
    length(parts) == 1 && parts[1] === nothing && return "\"otherwise\""
    rendered = [p === nothing ? "\"otherwise\"" : p for p in parts]
    return "\"if\" " * join(rendered, " \"and\" ")
end

# Flatten a (possibly nested) `if_statement` into (target, guard-label, value)
# triples, conjoining branch conditions along the path.
function flatten_if!(triples, node, guard, src)
    for (cond, body) in if_branches(node)
        parts = vcat(guard, Any[cond === nothing ? nothing : to_typst(cond, src)])
        for stmt in body
            t = TS.node_type(stmt)
            if t == "assignment"
                push!(triples, (target_typst(stmt, src), guard_label(parts),
                                to_typst(TS.child(stmt, "value"), src)))
            elseif t == "if_statement"
                flatten_if!(triples, stmt, parts, src)
            end
        end
    end
    return triples
end

"""Render an `if_statement` as one typst `cases` equation per assigned target,
preserving first-appearance order."""
function cases_equations(node, src)
    triples = flatten_if!(Tuple{String,String,String}[], node, Any[], src)
    order = String[]
    rows = Dict{String,Vector{String}}()
    for (target, label, value) in triples
        haskey(rows, target) || (push!(order, target); rows[target] = String[])
        push!(rows[target], "$value & $label")
    end
    return ["$target = cases($(join(rows[target], ", ")))" for target in order]
end

function collect_equations!(out, node, src, in_block)
    t = TS.node_type(node)
    if t == "label_block"
        inner = TS.slice(src, TS.child(node, "name")) in EQUATION_BLOCKS
        for c in named_children(node)
            collect_equations!(out, c, src, inner)
        end
    elseif t in SECTIONS
        for c in named_children(node)
            collect_equations!(out, c, src, in_block)
        end
    elseif in_block && is_equation(node)
        push!(out, to_typst(node, src))
    elseif in_block && t == "if_statement"
        append!(out, cases_equations(node, src))
    end
    return out
end

# --- Public API -------------------------------------------------------------

"""
    equation_to_typst(node, source) -> String

Convert a single `assignment` or `expression_statement` subtree to typst math
source (without the surrounding `\$...\$`).
"""
equation_to_typst(node, source::AbstractString) = to_typst(node, source)

"""
    mlxtran_to_typst(source) -> String

Parse mlxtran `source` and render each equation (assignment or bare expression)
as a typst math block, one per line.
"""
function mlxtran_to_typst(source::AbstractString)
    tree = parse(parser(), source)
    out = String[]
    collect_equations!(out, TS.root(tree), source, false)
    return join(("\$$e\$" for e in out), "\n")
end

end # module
