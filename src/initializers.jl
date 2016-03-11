#=
# Code change history:
#     Zheng Li (zheng@bitfusion.io) at Bifusion.io Inc.   : Add multi-GPU support.
#
=#
# An Initializer is used to initialize network parameters
export Initializer
export ConstantInitializer
export XavierInitializer
export GaussianInitializer
export OrthogonalInitializer

abstract Initializer # The root type of all initializer

immutable NullInitializer <: Initializer end
function init(::NullInitializer, blob::Blob)
  # do nothing
end

immutable ConstantInitializer <: Initializer
  value
end

function init(initializer::ConstantInitializer, blob::Blob)
  fill_all!(blob, initializer.value)
end

################################################################################
# An initializer  based on the paper [Bengio and Glorot 2010]: Understanding
# the difficulty of training deep feedforward neuralnetworks, but does not
# use the fan_out value.
#
# It fills the incoming matrix by randomly sampling uniform data from
# [-scale, scale] where scale = sqrt(3 / fan_in) where fan_in is the number
# of input nodes.
#
# For a ND-tensor blob parameter, the product of the 1 ~ (N-1) dimensions
# are considered as fan-in, and the last dimension is considered as fan-out.
################################################################################
immutable XavierInitializer <: Initializer
end
function init(initializer::XavierInitializer, blob::Blob)
  fan_in = get_fea_size(blob)
  scale = sqrt(3.0 / fan_in)
  init_val = rand(eltype(blob), size(blob)) * 2scale - scale
  copy_all!(blob, init_val)
end

immutable GaussianInitializer <: Initializer
  mean :: AbstractFloat
  std  :: AbstractFloat
end
GaussianInitializer(;mean=0.0, std=1.0) = GaussianInitializer(mean, std)

function init(initializer::GaussianInitializer, blob::Blob)
  init_val = randn(size(blob)) * initializer.std + initializer.mean
  init_val = convert(Array{eltype(blob)}, init_val)
  copy_all!(blob, init_val)
end

####### Orthogonal Initializer ##############################################
#
# Based on https://github.com/Lasagne/Lasagne/blob/master/lasagne/init.py
#
#############################################################################

immutable OrthogonalInitializer <: Initializer
  gain::AbstractFloat
end
OrthogonalInitializer() = OrthogonalInitializer(1.0) # but use OrthogonalInitializer(sqrt(2)) for ReLU units

function init(initializer::OrthogonalInitializer, blob::Blob)
  dims = size(blob)
  if length(dims) < 2
    error("Must have length(size(blob)) >= 2")
  end
  flatshape = (dims[1], prod(dims[2:end]))
  x = randn(flatshape)
  u, _, v = svd(x)
  x = (size(u) == flatshape) ? u : v
  copy_all!(blob, convert(Array{eltype(blob)}, x*initializer.gain))
end
