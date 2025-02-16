open Prims
let (app0 : FStarC_Reflection_Types.term -> FStarC_Reflection_Types.term) =
  fun t ->
    FStar_Reflection_V2_Derived.mk_app t
      [((Pulse_Reflection_Util.bound_var Prims.int_zero),
         FStarC_Reflection_V2_Data.Q_Explicit)]
let (abs_and_app0 :
  FStarC_Reflection_Types.term ->
    FStarC_Reflection_Types.term -> FStarC_Reflection_Types.term)
  =
  fun ty ->
    fun b ->
      FStar_Reflection_V2_Derived.mk_app
        (Pulse_Reflection_Util.mk_abs ty FStarC_Reflection_V2_Data.Q_Explicit
           b)
        [((Pulse_Reflection_Util.bound_var Prims.int_zero),
           FStarC_Reflection_V2_Data.Q_Explicit)]
let (slprop_arrow : Pulse_Syntax_Base.term -> Pulse_Syntax_Base.term) =
  fun t ->
    Pulse_Syntax_Pure.tm_arrow (Pulse_Syntax_Base.null_binder t)
      FStar_Pervasives_Native.None
      (Pulse_Syntax_Base.C_Tot Pulse_Syntax_Pure.tm_slprop)
let coerce_eq : 'a 'b . 'a -> unit -> 'b =
  fun uu___1 -> fun uu___ -> (fun x -> fun uu___ -> Obj.magic x) uu___1 uu___