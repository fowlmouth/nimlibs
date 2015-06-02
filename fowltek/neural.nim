# available -define:
#   NeuralFloat32 - makes float type used be float32

from math import exp, randomize, random
import strutils, json
randomize()

when defined(NeuralFloat32):
  type NeuralFloat* = float32
else:
  type NeuralFloat* = float64

type
  ActivationFunction* = object
    fn*, deriv*: proc(value:NeuralFloat):NeuralFloat{.nimcall.}

  NeuralNet* = ref object
    layerSizes*: seq[int]
    outputs: seq[seq[NeuralFloat]] #outputs
    deltas:  seq[seq[NeuralFloat]] #error values
    weights, previousWeights: seq[seq[seq[NeuralFloat]]]
    learningRate, momentum: NeuralFloat
    activationf: ActivationFunction

  TTrainingData* = tuple[inputs, target: seq[NeuralFloat]]

let
  sigmoid* = ActivationFunction(
    fn: proc(value:NeuralFloat):NeuralFloat = 1 / (1 + exp(-value)),
    deriv: proc(value:NeuralFloat):NeuralFloat = value * (1 - value)
  )
  tan* = ActivationFunction(
    fn: proc(v:NeuralFloat):NeuralFloat = math.tanh(v),
    deriv: proc(value:NeuralFloat):NeuralFloat = (;let t = math.tanh(value); 1 - t*t)
  )

proc activationFunc* (nn: NeuralNet): ActivationFunction = 
  nn.activationf
proc `activationFunc=`* (nn: NeuralNet, af: ActivationFunction) =
  nn.activationf = af

proc numLayers* (nn: NeuralNet): int = nn.layerSizes.len
proc numInputs* (nn: NeuralNet): int = nn.layerSizes[0]
proc numOutputs*(nn: NeuralNet): int = nn.layerSizes[< nn.layerSizes.len]

proc getOutputs*(nn: NeuralNet): seq[NeuralFloat] = nn.outputs[< nn.numLayers]
proc getOutput* (nn: NeuralNet; idx: int): NeuralFloat = nn.outputs[<nn.numLayers][idx]

proc copy* (nn: NeuralNet): NeuralNet =
  NeuralNet(
    layerSizes: nn.layerSizes,
    outputs: nn.outputs,
    weights: nn.weights
  )

proc newNeuralNet* (layers: openarray[int]): NeuralNet =
  result = NeuralNet(
    layerSizes: @layers,
    activationf: sigmoid
  )
  
  let layerCount = result.numLayers
  newSeq result.outputs, layerCount
  newSeq result.weights, layerCount
  
  for i, L in layers:
    newSeq result.outputs[i], L
    if i > 0:
      newSeq result.weights[i], L
      for j in 0 .. <L:
        newSeq result.weights[i][j], layers[i - 1]+1

proc prepareForTraining* (nn: NeuralNet; learningRate, momentum: NeuralFloat) =
  nn.learningRate = learningRate
  nn.momentum = momentum
  
  # initialize layers
  let layerCount = nn.numLayers
  newSeq nn.deltas, layerCount
  newSeq nn.previousWeights, layerCount
  
  for i in 1 .. <layerCount:
    let L = nn.layerSizes[i]
    newSeq nn.deltas[i], L 
    newSeq nn.previousWeights[i], L
    
    for j in 0 .. < L:
      newSeq nn.previousWeights[i][j], nn.layersizes[i - 1] + 1
      
      for k in 0 .. < nn.layersizes[i - 1] + 1:
        nn.weights[i][j][k] = random(1.0)


proc feed* (nn: NeuralNet; input: openarray[NeuralFloat]) =
  #assign inputs
  for i in 0 .. < nn.numInputs:
    nn.outputs[0][i] = input[i]
  
  for i in 1 .. < nn.numLayers:
    for j in 0 .. < nn.layerSizes[i]:
      var sum = 0.0
      for k in 0 .. < nn.layerSizes[i - 1]:
        sum += nn.outputs[i - 1][k] * nn.weights[i][j][k]
      sum += nn.weights[i][j][nn.layerSizes[i - 1]]
      nn.outputs[i][j] = nn.activationf.fn(sum)


proc backProp* (nn: NeuralNet; input, target: openarray[NeuralFloat]) =
  assert target.len == nn.numOutputs
  assert input.len == nn.numInputs
  
  # update output values
  nn.feed input
  
  # find deltas for output layer
  let 
    lastLayer = nn.numLayers - 1
    numLayers = nn.numLayers
    
  for i in 0 .. < nn.numOutputs:
    nn.deltas[lastLayer][i] = 
      nn.activationf.deriv(nn.outputs[lastLayer][i]) * 
      (target[i] - nn.outputs[lastLayer][i])

  # find deltas for hidden layer
  for i in countdown(numLayers - 2, 1):
    for j in 0 .. < nn.layerSizes[i]:
      var sum = 0.0
      for k in 0 .. < nn.layerSizes[i+1]:
        sum += nn.deltas[i+1][k] * nn.weights[i+1][k][j]
      nn.deltas[i][j] = 
        nn.activationf.deriv(nn.outputs[i][j]) * sum
      #  nn.outputs[i][j] * (1.0 - nn.outputs[i][j]) * sum

  # apply momentum
  if nn.momentum != 0:
    for i in 1 .. < numLayers:
      for j in 0 .. < nn.layerSizes[i]:
        for k in 0 .. < nn.layerSizes[i-1]:
          nn.weights[i][j][k] += 
            nn.momentum * nn.previousWeights[i][j][k]
        nn.weights[i][j][nn.layerSizes[i-1]] += 
          nn.momentum * nn.previousWeights[i][j][nn.layerSizes[i-1]]

  for i in 1 .. < numLayers:
    for j in 0 .. < nn.layerSizes[i]:
      for k in 0 .. < nn.layerSizes[i-1]:
        nn.previousWeights[i][j][k] = 
          nn.learningRate * nn.deltas[i][j] * nn.outputs[i-1][k]
        nn.weights[i][j][k] +=
          nn.previousWeights[i][j][k]
      nn.previousWeights[i][j][nn.layerSizes[i-1]] = 
        nn.learningRate * nn.deltas[i][j]
      nn.weights[i][j][nn.layerSizes[i-1]] +=
        nn.previousWeights[i][j][nn.layerSizes[i-1]]

proc meanSquareError (nn: NeuralNet; target: openarray[NeuralFloat]): NeuralFloat =
  for i in 0 .. < nn.numOutputs:
    result += 
      (target[i] - nn.getOutput(i)) * (target[i] - nn.getoutput(i))
  result = result / 2.0



proc ff(f: NeuralFloat; prec = 2): string = formatFloat(f, ffDecimal, prec)


proc train* (nn: NeuralNet; 
      data: openarray[TTrainingData]; 
      numIters = 1_000_000; threshold = 0.000001) =
  for i in 0 .. <numIters:
    var 
      correct = 0
    when defined(Debug):
      var avg_mse = 0.0
    
    for ii in 0 .. < data.len:
      nn.backProp data[ii].inputs, data[ii].target
      
      let mse = nn.meanSquareError(data[ii].target)
      if mse < threshold:
        correct.inc
      when defined(Debug):
        avg_mse += mse

    if correct == data.len:
      when defined(Debug):
        echo "Network trained in ", i+1, " iterations."
      break

    when defined(Debug):
      if i mod int(numIters / 10) == 0:
        avg_mse /= data.len.NeuralFloat
        echo "MSE: ", ff(avg_mse, 8)



proc toFloat* (f: PJsonNode): NeuralFloat =
  case f.kind
  of JInt:
    return f.num.NeuralFloat
  of JFloat:
    return f.fnum.NeuralFloat
  of JString:
    return f.str.parseFloat
  else:
    discard
proc getFloat (obj: PJsonNode; field: string; default = 0.0): NeuralFloat =
  if obj.hasKey(field):
    result = obj[field].toFloat    
  else:
    result = default

proc toInt* (i: PJsonNode): int =
  case i.kind
  of JInt:
    return i.num.int
  of JFloat:
    return i.fnum.int
  of JString:
    return i.str.parseInt
  else:
    discard
proc getInt (obj: PJsonNode; field: string; default = 0): int =
  if obj.hasKey(field): 
    result = obj[field].toInt
  else: 
    result = default

proc setActivationFunc* (net:NeuralNet; fn:string) =
  case fn.toLower
  of "tanh":
    net.activationf = neural.tan
  of "logistic","sigmoid":
    net.activationf = neural.sigmoid
  else:
    raise newException(ValueError, "activation function not recognized: "& fn)

proc loadNeuralNet* (data:PJsonNode): NeuralNet =
  ## loads a neural net defined in JSON. see the bottom of the page for an example
  ## if there is a "training" section the net will be trained before being returned.
  var layers: seq[int] = @[]
  for n in data["layers"]:
    layers.add n.num.int
  
  result = newNeuralNet(layers)
  
  if data.hasKey("activation_function"):
    result.setActivationFunc data["activation_function"].str

  if data.hasKey("weights"):
    for layer in 1 .. < result.numLayers:
      for id1 in 0 .. < data["weights"][layer-1].len:
        for id2 in 0 .. < data["weights"][layer-1][id1].len:
          result.weights[layer][id1][id2] = data["weights"][layer-1][id1][id2].toFloat

  elif data.hasKey("training"):
    var trainingData: seq[TTrainingData] = @[]
    
    let 
      training     = data["training"]
      iterations   = training.getInt("iterations", 500000)
      threshold    = training.getFloat("threshold", 0.00001)
      learningRate = training.getFloat("learning-rate", 0.3)
      momentum     = training.getFloat("momentum", 0.1)
    
    for t in training["set"]:
      let
        j_input = t[0]
        j_target= t[1]
      var
        data: TTrainingData
      data.inputs = @[]
      data.target = @[]
      
      for i in j_input:
        data.inputs.add i.toFloat
      for i in j_target:
        data.target.add i.toFloat
      
      trainingData.add data
    
    result.prepareForTraining(learningRate, momentum)
    result.train trainingData, iterations, threshold

proc loadNeuralNet* (file:string): NeuralNet =
  loadNeuralNet(json.parseFile(file))

proc `%`* (nn: NeuralNet): PJsonNode =
  let layers = newJarray()
  for L in nn.layerSizes:
    layers.add(%L)
  
  let weights = newJarray()
  for idx in 1 .. <nn.numLayers:
    let x = newJarray()
    for j in nn.weights[idx]:
      let y = newJarray()
      for k in j:
        y.add(%k)
      x.add y
    weights.add x
  
  result = %{"layers": layers, "weights": weights}

proc save* (nn: NeuralNet; file: string) =
  let j = %nn
  writeFile(file, j.pretty)

when isMainModule:
  
  import os, times
  
  let sets = ["or", "xor", "and", "nand", "nor", "xnor"]

  let training_data = {
    "or": %*{
      "layers": [2,1],
      "training": {
        "set": [
          [[0,1], [1]],
          [[1,0], [1]],
          [[0,1], [1]],
          [[0,0], [0]]
        ]
      }
    },
    "xor": %*{
      "layers": [2,2,1],
      "training": {
        "set": [
          [[0,1], [1]],
          [[1,0], [1]],
          [[1,1], [0]],
          [[0,0], [0]]
        ]
      }
    }
  }

  for name, dat in training_data.items:
    echo "Training \"", name, '"'
    let start = epochTime()
    var net = loadNeuralNet(dat)
    echo "finished in ", formatFloat(epochTime() - start, ffDecimal, 4), "seconds"

    var inputs = newseq[NeuralFloat](net.numInputs)
    for s in dat["training"]["set"]:
      for idx,f in s[0].elems.pairs:
        inputs[idx] = f.toFloat
      net.feed inputs
      echo "  $# = $#".format(
        inputs, net.getOutput(0))
