export AbstractNLPModelMeta, NLPModelMeta, reset_data!

"""
    AbstractNLPModelMeta

Base type for metadata related to an optimization model.
"""
abstract type AbstractNLPModelMeta{T, S} end

"""
    NLPModelMeta <: AbstractNLPModelMeta

A composite type that represents the main features of the optimization problem

    optimize    obj(x)
    subject to  lvar ≤    x    ≤ uvar
                lcon ≤ cons(x) ≤ ucon

where `x`        is an `nvar`-dimensional vector,
      `obj`      is the real-valued objective function,
      `cons`     is the vector-valued constraint function,
      `optimize` is either "minimize" or "maximize".

Here, `lvar`, `uvar`, `lcon` and `ucon` are vectors.
Some of their components may be infinite to indicate that the corresponding bound or general constraint is not present.

---

    NLPModelMeta(nvar; kwargs...)

Create an `NLPModelMeta` with `nvar` variables.
The following keyword arguments are accepted:
- `x0`: initial guess
- `lvar`: vector of lower bounds
- `uvar`: vector of upper bounds
- `nlvb`: number of nonlinear variables in both objectives and constraints
- `nlvo`: number of nonlinear variables in objectives (includes nlvb)
- `nlvc`: number of nonlinear variables in constraints (includes nlvb)
- `ncon`: number of general constraints
- `y0`: initial Lagrange multipliers
- `lcon`: vector of constraint lower bounds
- `ucon`: vector of constraint upper bounds
- `nnzo`: number of nonzeros in the gradient
- `nnzj`: number of elements needed to store the nonzeros in the sparse Jacobian
- `nnzh`: number of elements needed to store the nonzeros in the sparse Hessian
- `nlin`: number of linear constraints
- `nnln`: number of nonlinear general constraints
- `lin`: indices of linear constraints
- `nln`: indices of nonlinear constraints
- `minimize`: true if optimize == minimize
- `islp`: true if the problem is a linear program
- `name`: problem name
"""
struct NLPModelMeta{T, S} <: AbstractNLPModelMeta{T, S}
  nvar::Int
  x0::S
  lvar::S
  uvar::S

  ifix::Vector{Int}
  ilow::Vector{Int}
  iupp::Vector{Int}
  irng::Vector{Int}
  ifree::Vector{Int}
  iinf::Vector{Int}

  nlvb::Int
  nlvo::Int
  nlvc::Int

  ncon::Int
  y0::S
  lcon::S
  ucon::S

  jfix::Vector{Int}
  jlow::Vector{Int}
  jupp::Vector{Int}
  jrng::Vector{Int}
  jfree::Vector{Int}
  jinf::Vector{Int}

  nnzo::Int
  nnzj::Int
  nnzh::Int

  nlin::Int
  nnln::Int

  lin::Vector{Int}
  nln::Vector{Int}

  minimize::Bool
  islp::Bool
  name::String

  function NLPModelMeta{T, S}(
    nvar::Int;
    x0::S = fill!(S(undef, nvar), zero(T)),
    lvar::S = fill!(S(undef, nvar), T(-Inf)),
    uvar::S = fill!(S(undef, nvar), T(Inf)),
    nlvb = nvar,
    nlvo = nvar,
    nlvc = nvar,
    ncon = 0,
    y0::S = fill!(S(undef, ncon), zero(T)),
    lcon::S = fill!(S(undef, ncon), T(-Inf)),
    ucon::S = fill!(S(undef, ncon), T(Inf)),
    nnzo = nvar,
    nnzj = nvar * ncon,
    nnzh = nvar * (nvar + 1) / 2,
    lin = Int[],
    nln = 1:ncon,
    nlin = length(lin),
    nnln = length(nln),
    minimize = true,
    islp = false,
    name = "Generic",
  ) where {T, S}
    if (nvar < 1) || (ncon < 0)
      error("Nonsensical dimensions")
    end

    @lencheck nvar x0 lvar uvar
    @lencheck ncon y0 lcon ucon
    @lencheck nlin lin
    @lencheck nnln nln
    @rangecheck 1 ncon lin nln
    # T = eltype(x0)

    ifix = findall(lvar .== uvar)
    ilow = findall((lvar .> T(-Inf)) .& (uvar .== T(Inf)))
    iupp = findall((lvar .== T(-Inf)) .& (uvar .< T(Inf)))
    irng = findall((lvar .> T(-Inf)) .& (uvar .< T(Inf)) .& (lvar .< uvar))
    ifree = findall((lvar .== T(-Inf)) .& (uvar .== T(Inf)))
    iinf = findall(lvar .> uvar)

    jfix = findall(lcon .== ucon)
    jlow = findall((lcon .> T(-Inf)) .& (ucon .== T(Inf)))
    jupp = findall((lcon .== T(-Inf)) .& (ucon .< T(Inf)))
    jrng = findall((lcon .> T(-Inf)) .& (ucon .< T(Inf)) .& (lcon .< ucon))
    jfree = findall((lcon .== T(-Inf)) .& (ucon .== T(Inf)))
    jinf = findall(lcon .> ucon)

    nnzj = max(0, nnzj)
    nnzh = max(0, nnzh)

    new{T, S}(
      nvar,
      x0,
      lvar,
      uvar,
      ifix,
      ilow,
      iupp,
      irng,
      ifree,
      iinf,
      nlvb,
      nlvo,
      nlvc,
      ncon,
      y0,
      lcon,
      ucon,
      jfix,
      jlow,
      jupp,
      jrng,
      jfree,
      jinf,
      nnzo,
      nnzj,
      nnzh,
      nlin,
      nnln,
      lin,
      nln,
      minimize,
      islp,
      name,
    )
  end
end

NLPModelMeta(nvar; x0::S = zeros(nvar), kwargs...) where {S} =
  NLPModelMeta{eltype(S), S}(nvar, x0 = x0; kwargs...)

"""
    reset_data!(nlp)

Reset model data if appropriate.
This method should be overloaded if a subtype of `AbstractNLPModel`
contains data that should be reset, such as a quasi-Newton linear
operator.
"""
function reset_data!(nlp::AbstractNLPModel)
  return nlp
end
