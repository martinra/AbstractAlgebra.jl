################################################################################
#
#  Map.jl : Maps
#
################################################################################

export MapFromFunc, compose, domain, codomain

################################################################################
#
#  All maps
#
################################################################################

function check_composable(a::AbstractAlgebra.Map{U, C}, b::AbstractAlgebra.Map{D, U}) where {C, U, D}
   domain(a) != codomain(b) && error("Incompatible maps")
end

################################################################################
#
#  IdentityMap
#
################################################################################

domain(f::IdentityMap) = f.domain
codomain(f::IdentityMap) = f.codomain
image_fn(f::IdentityMap) = x -> x

(f::IdentityMap)(a) = a

function show(io::IO, M::IdentityMap)
   println(io, "Identity map with")
   println(io, "")
   println(io, "Domain:")
   println(io, "=======")
   println(io, domain(M))
end

################################################################################
#
#  FunctionalMap
#
################################################################################

domain(f::FunctionalMap) = f.domain
codomain(f::FunctionalMap) = f.codomain
image_fn(f::FunctionalMap) = f.image_fn

(f::FunctionalMap)(a) = image_fn(f)(a)

function MapFromFunc(image_fn::Function, domain, codomain)
   return FunctionalMap(domain, codomain, image_fn)
end

function show(io::IO, M::FunctionalMap)
   println(io, "Map with the following data")
   println(io, "")
   println(io, "Domain:")
   println(io, "=======")
   println(io, domain(M))
   println(io, "")
   println(io, "Coomain:")
   println(io, "========")
   println(io, codomain(M))
end

################################################################################
#
#  CompositeMap
#
################################################################################

domain(f::CompositeMap) = domain(f.map1)
codomain(f::CompositeMap) = codomain(f.map2)

# This is a device to prevent Julia trying to compute
# the types of a very long composition of closures
struct UntypedFunction <: Function
   fn::Function
end

function compose(f::UntypedFunction, g::UntypedFunction)
   return x -> f.fn(g.fn(x))
end

(f::UntypedFunction)(a) = f.fn(a)

function image_fn(f::CompositeMap)
   if isdefined(f, :fn_cache)
      return f.fn_cache
   else
      f1 = image_fn(f.map1)
      f2 = image_fn(f.map2)
      fn = compose(UntypedFunction(f2), UntypedFunction(f1))
      f.fn_cache = fn
      return fn
   end
end

(f::CompositeMap)(a) = image_fn(f)(a)

function compose(f::AbstractAlgebra.Map{U, C}, g::AbstractAlgebra.Map{D, U}) where {D, U, C}
   check_composable(f, g)
   return CompositeMap(f, g)
end

function compose(f::AbstractAlgebra.Map{D, C}, g::AbstractAlgebra.IdentityMap{D}) where {D, C}
   check_composable(f, g)
   return f
end

function compose(f::AbstractAlgebra.IdentityMap{C}, g::AbstractAlgebra.Map{D, C}) where {D, C}
   check_composable(f, g)
   return g
end

function show_short(io::IO, M::AbstractAlgebra.Map)
   println(domain(M), " -> ", codomain(M))
end

function show_short(io::IO, M::CompositeMap)
   show_short(io, M.map2)
   println(io, "then")
   show(io, M.map1)
end

function show(io::IO, M::CompositeMap)
   println(io, "Composite map consisting of the following")
   println(io, "")
   show_short(io, M.map2)
   println(io, "then")
   show_short(io, M.map1)
end