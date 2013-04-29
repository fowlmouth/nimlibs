import macros
import fowltek/importc_block, fowltek/macro_dsl

when defined(Linux):
  const
    LibName = "libfann.so"
else:
  {.fatal: "Please fill out the library name for your system in fann.nim".}

when defined(FannIntegers):
  type TFannType* = cint
else:
  type TFannType* = cfloat

type PFannType* = ptr TFannType


{.pragma: dyl, dynlib: LibName.}


#fann_error.h
type
  TFannError* {.pure.} = object
    errno*: TFannErrorNum
    errorLog*: TFile
    errstr*: cstring
  PFannError* = ptr TFannError
  
  TFannErrorNum* {.size: sizeof(cint).} = enum
    FANN_E_NO_ERROR = 0,
    FANN_E_CANT_OPEN_CONFIG_R,
    FANN_E_CANT_OPEN_CONFIG_W,
    FANN_E_WRONG_CONFIG_VERSION,
    FANN_E_CANT_READ_CONFIG,
    FANN_E_CANT_READ_NEURON,
    FANN_E_CANT_READ_CONNECTIONS,
    FANN_E_WRONG_NUM_CONNECTIONS,
    FANN_E_CANT_OPEN_TD_W,
    FANN_E_CANT_OPEN_TD_R,
    FANN_E_CANT_READ_TD,
    FANN_E_CANT_ALLOCATE_MEM,
    FANN_E_CANT_TRAIN_ACTIVATION,
    FANN_E_CANT_USE_ACTIVATION,
    FANN_E_TRAIN_DATA_MISMATCH,
    FANN_E_CANT_USE_TRAIN_ALG,
    FANN_E_TRAIN_DATA_SUBSET,
    FANN_E_INDEX_OUT_OF_BOUND,
    FANN_E_SCALE_NOT_PRESENT 


{.push callConv:cdecl.}
importcizzle "fann_":
  proc set_error_log* (errdat: PFannError, log_file: TFile) {.dyl.}
  proc get_errno* (errdat: PFannError): TFannErrorNum {.dyl.}
  proc reset_errno* (errdat: PFannError) {.dyl.}
  proc reset_errstr* (errdat: PFannError) {.dyl.}
  proc get_errstr*(errdat: PFannError): cstring {.dyl.}
  proc print_error*(errdat: PFannError) {.dyl.}

var default_error_log* {.importc: "fann_default_error_log", dyl, noDecl.}: TFile

# fann_activation.h

# fann_data.h
type
  TTrainingType* {.size:sizeof(cint).} = enum #fann_train_enum
    FANN_TRAIN_INCREMENTAL = 0, FANN_TRAIN_BATCH,
    FANN_TRAIN_RPROP, FANN_TRAIN_QUICKPROP

  TActivationFunc* {.size: sizeof(cint).} = enum
    FANN_LINEAR = 0,
    FANN_THRESHOLD,
    FANN_THRESHOLD_SYMMETRIC,
    FANN_SIGMOID,
    FANN_SIGMOID_STEPWISE,
    FANN_SIGMOID_SYMMETRIC,
    FANN_SIGMOID_SYMMETRIC_STEPWISE,
    FANN_GAUSSIAN,
    FANN_GAUSSIAN_SYMMETRIC,
    FANN_GAUSSIAN_STEPWISE,
    FANN_ELLIOT,
    FANN_ELLIOT_SYMMETRIC,
    FANN_LINEAR_PIECE,
    FANN_LINEAR_PIECE_SYMMETRIC,
    FANN_SIN_SYMMETRIC,
    FANN_COS_SYMMETRIC,
    FANN_SIN,
    FANN_COS
  
  TErrorFunc* {.size: sizeof(cint).} = enum
    FANN_ERRORFUNC_LINEAR = 0, FANN_ERRORFUNC_TANH
  TStopFunc* {.size: sizeof(cint).} = enum
    FANN_STOPFUNC_MSE = 0, FANN_STOPFUNC_BIT
  TNetworkType* {.size:sizeof(cint).} = enum
    FANN_NETTYPE_LAYER = 0, FANN_NETTYPE_SHORTCUT
  
  
  PFann* = ptr TFann
  TFann* {.pure.} = object # fann_data.h:474
  
  PTrainingData* = ptr TTrainingData
  TTrainingData* {.pure.} = object # fann_train.h:53
    errno*: TFannErrorNum
    errorLog*: TFile
    errstr*: cstring
    numData*, numInput*, numOutput*: cuint
    input*, output*: ptr PFannType
  
  TFannCallback* = proc(ann: PFann, train: PTrainingData; 
    maxEpochs, epochsBetweenReports: cuint; desiredError: cfloat; 
    epochs: cuint): cint {.cdecl.} 
  
  PNeuron* = ptr TNeuron
  TNeuron* {.pure.} = object ## has #ifdef __GNUC__  __attribute__ ((packed)); 
    firstCon*, lastCon*: cuint ## so NEEDS TESTING
    sum*, value*, activationSteepness*: TFannType
    activationFunction*: TActivationFunc

  TLayer* {.pure.} = object
    firstNeuron*: PNeuron
    lastNeuron*: PNeuron
  
  TConnection* {.pure.} = object
    fromNeuron*: cuint
    toNeuron*: cuint
    weight*: TFannType

# fann_internal.h
# (skipped)

macro getter(nam, ty): stmt {.immediate.} =
  let gettername = "get_" & $nam
  let fann_func = "fann_" & gettername
  result = newProc(
    name = newNimNode(nnkPostfix).add(!!"*", !!gettername), 
    params = [
      ty, 
      newNimNode(nnkIdentDefs).add(!!"ann", !!"PFann", newEmptyNode())
  ] )
  result.pragma = newNimNode(nnkPragma).add(
    !!"dyl",
    newNimNode(nnkExprColonExpr).add(
      !!"importc", newStrLitNode(fann_func)
  ) )
  when defined(DebugGS): result.repr.echo
macro setter(nam, ty): stmt {.immediate.} =
  let settername = "set_" & $nam
  let fann_func = "fann_" & settername
  result = newProc(
    name = newNimNode(nnkPostfix).add(!!"*", !!settername), 
    params = [
      !!"void",
      newNimNode(nnkIdentDefs).add(!!"ann", !!"PFann", newEmptyNode()),
      newNimNode(nnkIdentDefs).add(!!"val", ty, newEmptyNode())
  ] )
  result.pragma = newNimNode(nnkPragma).add(
    !!"dyl", 
    newNimNode(nnkExprColonExpr).add(
      !!"importc", newStrLitNode(fann_func) 
  ) )
  when defined(DebugGS): result.repr.echo 

macro getSetter(nam, ty): stmt {.immediate.} =
  result = newStmtList(getAst(setter(nam, ty)), getAst(getter(nam, ty)))


# fann_train.h
importcizzle "fann_":
  proc train*(ann: PFann; input: PFannType; desiredOutput: PFannType) {.dyl.}
  
  proc test*(ann: PFann, input: PFannType; desiredOutput: PFannType): PFannType {.dyl.}
  
  proc get_MSE*(ann: PFann): cfloat {.dyl.}
  proc get_bit_fail*(ann: PFann): cuint {.dyl.}
  proc reset_MSE*(ann: PFann) {.dyl.}
  
  proc train_on_data*(ann: PFann; data: PTrainingData; maxEpochs, epochsBetweenReports: cuint;
    desiredError: cfloat) {.dyl.}
  proc train_on_file* (ann: PFann; filename: cstring; maxEpochs, epochsBetweenReports: cuint,
    desiredError: cfloat) {.dyl.}
  proc train_epoch* (ann: PFann; data: PTrainingData): cfloat {.dyl.}
  
  proc test_data* (ann: PFann; data: PTrainingData): cfloat {.dyl.}
  
  proc read_train_from_file*(ann: PFann; filename: cstring): PTrainingData {.dyl.}

  proc create_train_from_callback*(num_data, num_input, num_output: cuint,
    user_function: proc(num, num_input, num_output: cuint,
      input, output: PFannType): pointer {.cdecl.}): PTrainingData {.dyl.}
  
  proc destroy_train* (train_data: PTrainingData) {.dyl.}
  
  proc shuffle_train_data*(train_data: PTrainingData){.dyl.}
  
  proc scale_train*(ann: PFann; data: PTrainingData) {.dyl.}
  
  proc descale_train*(ann: PFann; data: PTrainingData){.dyl.}
  
  proc set_input_scaling_params*(ann: PFann; data: PTrainingData;
    newInputMin, newInputMax: cfloat): cint {.dyl.}
  proc set_output_scaling_params*(ann: PFann; data: PTrainingData;
    newOutputMin, newOutputMax: cfloat): cint {.dyl.}
  proc set_scaling_params*(ann: PFann; data: PTrainingData;
    newInputMin, newInputMax, newOutputMin, newOutputMax: cfloat): cint{.dyl.}
  
  proc clear_scaling_params*(ann: PFann): cint {.dyl.}

  proc scale_input* (ann: PFann; input_vector: PFannType) {.dyl.}
  proc scale_output* (ann: PFann; output_vector: PFannType) {.dyl.}
  
  proc descale_input*(ann: PFann; input_vector: PFannType) {.dyl.}
  proc descale_output*(ann: PFann; output_vector: PFannType){.dyl.}
  
  proc scale_input_train_data*(train_data: PTrainingData; newMin, newMax: TFannType){.dyl.}
  proc scale_output_train_data*(train_data: PTrainingData; newMin, newMax: TFannType){.dyl.}
  proc scale_train_data*(train_data: PTrainingData; newMin, newMax: TFannType){.dyl.}
  
  proc merge_train_data*(data1, data2: PTrainingData): PTrainingData {.dyl.}
  proc duplicate_train_data*(data: PTrainingData): PTrainingData {.dyl.}
  
  proc subset_train_data*(data: PTrainingData; pos, length: cuint): PTrainingData {.dyl.}
  
  proc length_train_data*(data: PTrainingData): cuint {.dyl.}
  proc num_input_train_data*(data: PTrainingData): cuint{.dyl.}
  proc num_output_train_data*(data: PTrainingData): cuint {.dyl.}
  proc save_train*(data: PTrainingData; filename: cstring): cint {.dyl.}
  proc save_train_to_fixed*(data: PTrainingData; filename: cstring; decimalPoint: cuint): cint {.
    dyl.}
  proc get_training_algorithm*(ann: PFann): TTrainingType {.dyl.}
  proc set_training_algorithm*(ann: PFann; algo: TTrainingType) {.dyl.}
  proc get_learning_rate* (ann: PFann): cfloat {.dyl.}
  proc set_learning_rate* (ann: PFann; rate: cfloat) {.dyl.}
  proc get_learning_momentum* (ann: PFann): cfloat {.dyl.}
  proc set_learning_momentum* (ann: PFann; momentum: cfloat) {.dyl.}
  

  proc get_activation_function*(ann: PFann; layer, neuron: cint): TActivationFunc {.
    dyl.}
  
  proc set_activation_function*(ann: PFann; func: TActivationFunc; layer, neuron: cint) {.
    dyl.}
  proc set_activation_function_layer*(ann: PFann; func: TActivationFunc; layer: cint) {.
    dyl.}
  proc set_activation_function_hidden* (ann: PFann, func: TActivationFunc) {.
    dyl.}
  proc set_activation_function_output* (ann: PFann, func: TActivationFunc) {.
    dyl.}
  
  proc get_activation_steepness* (ann: PFann; layer, neuron: cint): TFannType {.
    dyl.}
  proc set_activation_steepness* (ann: PFann; steepness: TFannType; lyaer, neuron: cint){.
    dyl.}
  
  proc set_activation_steepness_layer* (ann: PFann; steepness: TFannType; layer: cint){.
    dyl.}
  proc set_activation_steepness_hidden* (ann: PFann; steepness: TFannType) {.dyl.}
  proc set_activation_steepness_output* (ann: PFann; steepness: TFannType) {.dyl.}
  proc get_train_error_function*(ann: PFann): TErrorFunc {.dyl.}
  proc set_train_error_function*(ann: PFann; func: TErrorFunc) {.dyl.}
  
  proc get_train_stop_function*(ann: PFann): TStopFunc {.dyl.}
  proc set_train_stop_function*(ann: PFann; func: TStopFunc){.dyl.}
  proc get_bit_fail_limit*(ann: PFann): TFannType {.dyl.}
  proc set_bit_fail_limit*(ann: PFann; limit: TFannType) {.dyl.}
  
  proc set_callback*(ann: PFann; cb: TFannCallback) {.dyl.}
  proc get_quickprop_decay*(ann: PFann): cfloat {.dyl.}
  proc set_quickprop_decay*(ann: PFann; val: cfloat) {.dyl.}
  proc get_quickprop_mu*(ann: PFann): cfloat {.dyl.}
  proc set_quickprop_mu*(ann: PFann; val: cfloat) {.dyl.}
  proc get_rprop_increase_factor*(ann: PFann): cfloat{.dyl.}
  proc set_rprop_increase_factor*(ann: PFann; factor: cfloat){.dyl.}
  proc get_rprop_decrease_factor*(ann: PFann): cfloat {.dyl.}
  proc set_rprop_decrease_factor*(ann: PFann; val: cfloat) {.dyl.}
  proc get_rprop_delta_min*(ann: PFann): cfloat {.dyl.}
  proc set_rprop_delta_min*(ann: PFann; val: cfloat) {.dyl.}
  proc get_rprop_delta_max*(ann: PFann): cfloat {.dyl.}
  proc set_rprop_delta_max*(ann: PFann; val: cfloat) {.dyl.}
  proc get_rprop_delta_zero*(ann: PFann): cfloat {.dyl.}
  proc set_rprop_delta_zero*(ann: PFann; val: cfloat) {.dyl.}
  
  # fann_cascade.h 
  proc cascadetrain_on_file*(ann: PFann; filename: cstring; 
    maxNeurons, neuronsBetweenReports: cuint, desiredError: cfloat){.dyl.}
  proc get_cascade_output_change_fraction*(ann: PFann): cfloat {.dyl.}
  proc set_cascade_output_change_fraction*(ann: PFann; val: cfloat) {.dyl.}
  
  proc get_cascade_output_stagnation_epochs*(ann: PFann): cuint {.dyl.}
  proc set_cascade_output_stagnation_epochs*(ann: PFann; epochs: cuint) {.dyl.}
  proc get_cascade_candidate_change_fraction*(ann: PFann): cfloat {.dyl.}
  proc set_cascade_candidate_change_fraction*(ann: PFann; fraction: cfloat) {.dyl.}
  proc get_cascade_candidate_stagnation_epochs*(ann: PFann): cuint {.dyl.}
  proc set_cascade_candidate_stagnation_epochs*(ann: PFann; epochs: cuint) {.dyl.}
  proc get_cascade_weight_multiplier*(ann: PFann): TFannType{.dyl.}
  proc set_cascade_weight_multiplier*(ann: PFann; mult: TFannType) {.dyl.} 

  getsetter cascade_candidate_limit, TFannType
  getsetter cascade_max_out_epochs, cuint

  getsetter cascade_max_cand_epochs, cuint

  getter cascade_num_candidates, cuint

  getter cascade_activation_functions_count, cuint

  getter cascade_activation_functions, ptr TActivationFunc

  
  proc set_cascade_activation_functions*(ann: PFann; functions: ptr TActivationFunc;
      functionCount: cuint) {.dyl.}
  
  proc get_cascade_activation_steepnesses_count*(ann: PFann): cuint {.dyl.}  
  getter cascade_activation_steepnesses, PFannType
  
  proc set_cascade_activation_steepnesses*(ann: PFann; steepnesses: PFannType; count: cuint) {.dyl.}
  
  getsetter cascade_num_candidate_groups, cuint

  # fann_io.h
  proc create_from_file* (filename: cstring): PFann {.dyl.}
  proc save* (ann: PFann; filename: cstring): cint {.dyl.}
  
  proc save_to_fixed* (ann: PFann; filename: string): cint {.dyl.}
  
  # fann.h
  
  proc create_standard*(num_layers: cuint): PFann {.varargs, dyl.} 
    ## arguments should be CUINT
  proc create_standard_array*(num_layers: cuint; layers: ptr cuint): PFann {.dyl.}
  
  proc create_sparse*(connectionRate: cfloat; numLayers: cuint): PFann {.varargs, dyl.}
  proc create_sparse_array*(connectionRate: cfloat; numLayers: cuint; 
    layers: ptr cuint): PFann{.varargs, dyl.}
  proc create_shortcut* (numLayers: cuint): PFann {.varargs, dyl.}
  proc create_shortcut_array* (numLayers: cuint; layers: ptr cuint): PFann {.dyl.}
  proc destroy* (ann: PFann) {.dyl.}
  
  proc run* (ann: PFann; input: PFannType): PFannType {.dyl.} 
  proc randomize_weights*(ann: PFann; minWeight, maxWeight: TFannType) {.dyl.}
  
  proc init_weights*(ann: PFann; trainingData: PTrainingData) {.dyl.}
  
  proc print_connections*(ann: PFann) {.dyl.}
  proc print_parameters*(ann: PFann) {.dyl.}
  
  getter num_input, cuint
  getter num_output, cuint
  getter total_neurons, cuint
  getter total_connections, cuint
  getter network_type, TNetworkType
  getter connection_rate, cfloat
  getter num_layers, cuint
  proc get_layer_array*(ann: PFann; layers: ptr cuint) {.dyl.}
  proc get_bias_array*(ann: PFann; bias: ptr cuint) {.dyl.}
  proc get_connection_array*(ann: PFann; connections: ptr TConnection) {.dyl.}
  proc set_weight_array*(ann: PFann; connections: ptr TConnection; numConnections: cuint) {.dyl.}
  proc set_weight*(ann: PFann; fromNeuron, toNeuron: cuint; weight: TFannType){.dyl.}
  getsetter user_data, pointer
  
  when defined(FannIntegers):
    getter decimal_point, cuint
    getter multiplier, cuint 
  
{.pop.}



# Nimrod helpers

proc destroy* (some: PTrainingData) {.inline.} = destroy_train(some)

proc len* (some: PTrainingData): int {.inline.} = some.length_train_data.int


