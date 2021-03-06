import jInv.ForwardShare.getSensTMatVec
export getSensTMatVec

"""
function matv = getSensTMatVec(x, sigma, param)

Multiplies the transposed sensitvity matrix by a vector

inputs:
        x::Vector               - A vector
        sigma::Vector{Float64}  - A conductivity model
        param::MaxwellFreqParam - MaxwellFreqParam

output:
        matv:Array{Complex{Float64}}  - Solution (J.T*x)

"""
function getSensTMatVec(x::Vector, sigma::Vector{Float64}, param::MaxwellFreqParam)

    if param.sensitivityMethod == :Implicit
        U = param.Fields
        w = param.freq
        P = param.Obs
        Ne, = getEdgeConstraints(param.Mesh)

        if param.useIw
           iw =  complex(0., w)
        else
           iw = -complex(0., w)
        end

        X    = reshape(complex(x), size(P,2), size(U,2))
        matv = zeros(param.Mesh.nc)

        for i=1:size(U, 2)
          #  u = U[:, i]
          #  dAdm = getdEdgeMassMatrix(param.Mesh, u)
          #  dAdm = -im*w*Ne'*dAdm
            z = -Ne'*(P*X[:, i])
            z, = solveMaxFreq(z, sigma, param, 1)  # Solve A'*z = z
          #  z = vec(z)
          #  matv += real(dAdm'*z)
            z = Ne * vec(z)
            dAdmTz  = DerivativeTrTimesVector(param.Mesh, sigma, U[:,i], z)
            matv += real( iw * dAdmTz )
        end  # i

    elseif param.sensitivityMethod == :Explicit
        if isempty(param.Sens)
            warn("getSensTMatVec: Recomputing data to get sensitvity matrix. This should be avoided.")
            Dc, param = getData(sigma, param)
        end
        matv = real(param.Sens'*x)
    else
        error("getSensMatVec: Invalid sensitivity method")
    end

    return matv
end
