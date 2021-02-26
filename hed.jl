using JSON
<<<<<<< HEAD
using Printf
=======
>>>>>>> 4e511daa4613aecfa07f0c29df5e27c092063cf8
using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--str-func"
            help     = "function on string: choose \"split\" (word-based) or \"identity\" (character-based)"
            arg_type = String
            default  = "identity"
        "prediction"
            help = "the .json file containing the prediction"
            required = true
        "groundTruth"
            help = "the .json file containing the ground truth"
            required = true
    end
    return parse_args(s)
end

const MetricType0 = NamedTuple{(:tp, :fp, :fn), Tuple{Float64, Float64, Float64}}
const MetricType1 = Tuple{Union{T, Vector{T}}, MetricType0} where {T <: AbstractString}
const MetricType2 = Tuple{Vector, MetricType0}
const MetricType3 = Tuple{T, MetricType0} where {T <: AbstractDict{String,Any}}

function countTpFpFn(predicted::T, actual::T, strFunc)::MetricType3 where {T <: AbstractDict{String,Any}}

    # 1) this function is the entry point

    emptyDict   = T()
    emptyVector = Vector{T}()
    emptyString = strFunc == split ? SubString{String}[] : ""
    xs = countTpFpFn(predicted, actual, strFunc, emptyDict, emptyVector, emptyString)
    xx = xs |> first
    tp, fp, fn = xs |> last

    return xx, (tp=tp, fp=fp, fn=fn)
end

function countTpFpFn(predicted::T, actual::T, strFunc, emptyDict::T, emptyVector::Vector{T}, emptyString::Union{S, Vector{S}})::MetricType3 where {T <: AbstractDict{String,Any}, S <: AbstractString}

    # 2) for comparing between Dictionaries, 

    # keys in both predicted and actual
    commonKeys = intersect(keys(predicted), keys(actual))

    # keys in predicted only
    predictedOnly = setdiff(keys(predicted), commonKeys)

    # keys in actual only
    actualOnly = setdiff(keys(actual), commonKeys)

    tp = 0
    fp = 0
    fn = 0
        
    xs = T()
    for k in commonKeys         
        if typeof(predicted[k]) <: AbstractString
            if actual[k] == nothing
                actual[k] = emptyString
            end
            xs[k] = countTpFpFn(strFunc(predicted[k]), strFunc(actual[k]), strFunc, emptyDict, emptyVector, emptyString)
        else
            if actual[k] == nothing
                actual[k] = T[]
            else
                actual[k] = convert(Vector{T}, actual[k])
            end
            xs[k] = countTpFpFn(convert(Vector{T}, predicted[k]), actual[k], strFunc, emptyDict, emptyVector, emptyString)
        end
        
        tp_, fp_, fn_ = xs[k] |> last
        tp += tp_
        fp += fp_
        fn += fn_
    end

    for k in predictedOnly
        if typeof(predicted[k]) <: AbstractString
            xs[k] = countTpFpFn(strFunc(predicted[k]), emptyString, strFunc, emptyDict, emptyVector, emptyString)
        else
            xs[k] = countTpFpFn(convert(Vector{T}, predicted[k]), emptyVector, strFunc, emptyDict, emptyVector, emptyString)
        end
        tp_, fp_, fn_ = xs[k] |> last
        @assert tp_ == 0
        @assert fn_ == 0
        fp += fp_
    end

    for k in actualOnly
        if actual[k] == nothing
            continue
        end
        
        if typeof(actual[k]) <: Vector{T} where {T <: Any}
            xs[k] = countTpFpFn(emptyVector, convert(Vector{T}, actual[k]), strFunc, emptyDict, emptyVector, emptyString)
        else
            xs[k] = countTpFpFn(emptyString, strFunc(actual[k]), strFunc, emptyDict, emptyVector, emptyString)
        end
        
        tp_, fp_, fn_ = xs[k] |> last
        @assert tp_ == 0
        @assert fp_ == 0
        fn += fn_
    end

    return xs, (tp=tp, fp=fp, fn=fn)
end

function countTpFpFn(predicted::Vector{T}, actual::Vector{T}, strFunc, emptyDict::T, emptyVector::Vector{T}, emptyString::Union{S, Vector{S}})::MetricType2 where {T <: AbstractDict{String,Any}, S <: AbstractString}

    # 3) entry function for comparing between line items
    memo = Dict{NTuple{2,Int}, MetricType2}()
    xs = countTpFpFn(predicted, actual, strFunc, emptyDict, emptyVector, emptyString, 1, 1, memo)
    return xs
end

function countTpFpFn(predicted::Vector{T}, actual::Vector{T}, strFunc, emptyDict::T, emptyVector::Vector{T}, emptyString::Union{S, Vector{S}}, i::Int, j::Int, memo::Dict{NTuple{2,Int}, MetricType2})::MetricType2 where {T <: AbstractDict{String,Any}, S <: AbstractString}

    # 4) line item edit distance

    if haskey(memo, (i,j))
        return memo[i,j]
    end

    xs = Vector() # a vector of tuple
    tp, fp, fn = 0, 0, 0
    # the base cases
    if i > length(predicted)
        # calculate the false negatives for remaining actual   
        for k=j:length(actual)
            xx = countTpFpFn(emptyDict, actual[k], strFunc, emptyDict, emptyVector, emptyString)
            tp_, fp_, fn_ = xx |> last
            @assert tp_ == 0
            @assert fp_ == 0
            fn += fn_
            push!(xs, xx)
        end
        
        memo[i,j] = (xs, (tp=tp, fp=fp, fn=fn))
        return memo[i,j]
    end

    if j > length(actual)
        for k=i:length(predicted)
            xx = countTpFpFn(predicted[k], emptyDict, strFunc, emptyDict, emptyVector, emptyString)
            tp_, fp_, fn_ = xx |> last
            @assert tp_ == 0
            @assert fn_ == 0
            fp += fp_
            push!(xs, xx)
        end
        memo[i,j] = (xs, (tp=tp, fp=fp, fn=fn))
        return memo[i,j]
    end

    # choose to do 3 things
    # 1) compare predicted[i] and actual[j]
    xx = countTpFpFn(predicted[i], actual[j], strFunc, emptyDict, emptyVector, emptyString) # MetricType3
    yy = countTpFpFn(predicted, actual, strFunc, emptyDict, emptyVector, emptyString, i+1, j+1, memo) # MetricType2

    tp_xx, fp_xx, fn_xx = xx |> last
    tp_yy, fp_yy, fn_yy = yy |> last
    dist1 = fp_xx + fp_yy + fn_xx + fn_yy 

    # 2) delete predicted[i], a.k.a. increment i
    x_ = countTpFpFn(predicted[i], emptyDict, strFunc, emptyDict, emptyVector, emptyString)
    xy = countTpFpFn(predicted, actual, strFunc, emptyDict, emptyVector, emptyString, i+1, j, memo) # MetricType2

    tp_x_, fp_x_, fn_x_ = x_ |> last
    @assert tp_x_ == 0
    @assert fn_x_ == 0
    tp_xy, fp_xy, fn_xy = xy |> last
    dist2 = fp_x_ + fp_xy + fn_x_ + fn_xy

    # 3) delete actual[j], a.k.a. increment j
    _x = countTpFpFn(emptyDict, actual[j], strFunc, emptyDict, emptyVector, emptyString)
    yx = countTpFpFn(predicted, actual, strFunc, emptyDict, emptyVector, emptyString, i, j+1, memo) # MetricType2

    tp__x, fp__x, fn__x = _x |> last
    @assert tp__x == 0
    @assert fp__x == 0
    tp_yx, fp_yx, fn_yx = yx |> last
    dist3 = fp__x + fp_yx + fn__x + fn_yx

    # choose the minimum path
    if dist1 <= dist2 && dist1 <= dist3
        # choose this
        tp = tp_xx + tp_yy
        fp = fp_xx + fp_yy
        fn = fn_xx + fn_yy
        
        push!(xs, xx)
        if length(yy[1]) > 0
            append!(xs, yy[1])
        end
    elseif dist2 <= dist1 && dist2 <= dist3
        tp = tp_x_ + tp_xy
        fp = fp_x_ + fp_xy
        fn = fn_x_ + fn_xy
        push!(xs, x_)
        if length(xy[1]) > 0
            append!(xs, xy[1])
        end
    else
        @assert dist3 <= dist1 && dist3 <= dist2
        tp = tp__x + tp_yx
        fp = fp__x + fp_yx
        fn = fn__x + fn_yx
        push!(xs, _x)
        if length(yx[1]) > 0
            append!(xs, yx[1])
        end
    end

    memo[i,j] = (xs, (tp=tp, fp=fp, fn=fn))
    return memo[i,j]
end

function countTpFpFn(predicted::Union{S, Vector{S}}, actual::Union{S, Vector{S}}, strFunc,
    emptyDict::T, emptyVector::Vector{T}, emptyString::Union{S, Vector{S}})::MetricType1 where {S <: AbstractString, T <: AbstractDict{String,Any}}

    # 5) for comparing between primitives

    memo = Dict{NTuple{2,Int}, NTuple{3,Int}}()
    equality = (x, y)->x==y
    tp, fp, fn = countTpFpFn(predicted, actual, firstindex(predicted), firstindex(actual), lastindex(predicted), lastindex(actual), memo; equality=equality)

    return (predicted, (tp=tp, fp=fp, fn=fn))
end

function countTpFpFn(predicted::T, actual::T, i::Int, j::Int, I::Int, J::Int, 
    memo::Dict{NTuple{2,Int}, NTuple{3,Int}}; equality=(x, y) -> x==y)::NTuple{3,Int} where T
    # TP: number of characters correct
    # FP: number of characters deleted in predicted
    # FN: number of characters inserted in predicted
    # return (TP, FP, FN)

    # 6) Field-level edit distance

    if haskey(memo, (i,j))
        return memo[i,j]
    end

    if i > I
        # delete the rest of the characters in actual
        # equivalent to insertion of characters in predicted
        return 0, 0, length(actual[j:end])
    end

    if j > J
        # delete the rest of the characters in predicted
        return 0, length(predicted[i:end]), 0
    end

    if equality(predicted[i], actual[j]) # this needs to be defined for the type
        tp, fp, fn = countTpFpFn(predicted, actual, nextind(predicted, i), nextind(actual, j), I, J, memo; equality=equality)
        tp += 1
        memo[i,j] = (tp, fp, fn)
    else
        # delete i-th character in predicted
        tp₁, fp₁, fn₁ = countTpFpFn(predicted, actual, nextind(predicted, i), j, I, J, memo; equality=equality)
        fp₁ += 1
        
        # insert character at i-th for predicted, 
        # equivalent to deletion of jth at actual
        tp₂, fp₂, fn₂ = countTpFpFn(predicted, actual, i, nextind(actual, j), I, J, memo; equality=equality)
        fn₂ += 1
        
        # choose the smaller of the two
        if (fp₁ + fn₁) < (fp₂ + fn₂)
            memo[i,j] = (tp₁, fp₁, fn₁)
        else
            memo[i,j] = (tp₂, fp₂, fn₂)
        end
    end
    return memo[i,j]
end

function main()
    args = parse_commandline()
    if args["str-func"] == "identity"
        strFunc = identity
    elseif args["str-func"] == "split"
        strFunc = split
    else
        throw("--str-func is neither split nor identity")
    end

    predictionJs  = JSON.parsefile(args["prediction"])
    groundTruthJs = JSON.parsefile(args["groundTruth"])

    tpFpFn = countTpFpFn(predictionJs, groundTruthJs, strFunc)

    JSON.print(tpFpFn, 4)

    tp, fp, fn = tpFpFn |> last

    precision = tp/(tp + fp)
    recall = tp/(tp + fn)
    f1 = 2 * precision * recall / (precision + recall)
    @printf("TP = %d, FP = %d, FN = %d, Precision = %.4g, Recall = %.4g, F₁ = %.4g\n", tp, fp, fn, precision, recall, f1)
end

main()
