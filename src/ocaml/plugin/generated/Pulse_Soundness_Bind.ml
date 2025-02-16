open Prims
let (inst_bind_t2 :
  FStarC_Reflection_Types.universe ->
    FStarC_Reflection_Types.universe ->
      FStarC_Reflection_Types.env ->
        FStarC_Reflection_Types.term ->
          FStarC_Reflection_Types.term ->
            (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
              FStarC_Reflection_Types.term ->
                (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                  (unit, unit, unit) FStar_Reflection_Typing.tot_typing)
  =
  fun u1 ->
    fun u2 ->
      fun g ->
        fun head ->
          fun t1 ->
            fun head_typing -> fun t2 -> fun t2_typing -> Prims.admit ()
let (inst_bind_pre :
  FStarC_Reflection_Types.universe ->
    FStarC_Reflection_Types.universe ->
      FStarC_Reflection_Types.env ->
        FStarC_Reflection_Types.term ->
          FStarC_Reflection_Types.term ->
            FStarC_Reflection_Types.term ->
              (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                FStarC_Reflection_Types.term ->
                  (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                    (unit, unit, unit) FStar_Reflection_Typing.tot_typing)
  =
  fun u1 ->
    fun u2 ->
      fun g ->
        fun head ->
          fun t1 ->
            fun t2 ->
              fun head_typing -> fun pre -> fun pre_typing -> Prims.admit ()
let (inst_bind_post1 :
  FStarC_Reflection_Types.universe ->
    FStarC_Reflection_Types.universe ->
      FStarC_Reflection_Types.env ->
        FStarC_Reflection_Types.term ->
          FStarC_Reflection_Types.term ->
            FStarC_Reflection_Types.term ->
              FStarC_Reflection_Types.term ->
                (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                  FStarC_Reflection_Types.term ->
                    (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                      (unit, unit, unit) FStar_Reflection_Typing.tot_typing)
  =
  fun u1 ->
    fun u2 ->
      fun g ->
        fun head ->
          fun t1 ->
            fun t2 ->
              fun pre ->
                fun head_typing ->
                  fun post1 -> fun post1_typing -> Prims.admit ()
let (inst_bind_post2 :
  FStarC_Reflection_Types.universe ->
    FStarC_Reflection_Types.universe ->
      FStarC_Reflection_Types.env ->
        FStarC_Reflection_Types.term ->
          FStarC_Reflection_Types.term ->
            FStarC_Reflection_Types.term ->
              FStarC_Reflection_Types.term ->
                FStarC_Reflection_Types.term ->
                  (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                    FStarC_Reflection_Types.term ->
                      (unit, unit, unit) FStar_Reflection_Typing.tot_typing
                        ->
                        (unit, unit, unit) FStar_Reflection_Typing.tot_typing)
  =
  fun u1 ->
    fun u2 ->
      fun g ->
        fun head ->
          fun t1 ->
            fun t2 ->
              fun pre ->
                fun post1 ->
                  fun head_typing ->
                    fun post2 -> fun post2_typing -> Prims.admit ()
let (inst_bind_f :
  FStarC_Reflection_Types.universe ->
    FStarC_Reflection_Types.universe ->
      FStarC_Reflection_Types.env ->
        FStarC_Reflection_Types.term ->
          FStarC_Reflection_Types.term ->
            FStarC_Reflection_Types.term ->
              FStarC_Reflection_Types.term ->
                FStarC_Reflection_Types.term ->
                  FStarC_Reflection_Types.term ->
                    (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                      FStarC_Reflection_Types.term ->
                        (unit, unit, unit) FStar_Reflection_Typing.tot_typing
                          ->
                          (unit, unit, unit)
                            FStar_Reflection_Typing.tot_typing)
  =
  fun u1 ->
    fun u2 ->
      fun g ->
        fun head ->
          fun t1 ->
            fun t2 ->
              fun pre ->
                fun post1 ->
                  fun post2 ->
                    fun head_typing ->
                      fun f -> fun f_typing -> Prims.admit ()
let (inst_bind_g :
  FStarC_Reflection_Types.universe ->
    FStarC_Reflection_Types.universe ->
      FStarC_Reflection_Types.env ->
        FStarC_Reflection_Types.term ->
          FStarC_Reflection_Types.term ->
            FStarC_Reflection_Types.term ->
              FStarC_Reflection_Types.term ->
                FStarC_Reflection_Types.term ->
                  FStarC_Reflection_Types.term ->
                    (unit, unit, unit) FStar_Reflection_Typing.tot_typing ->
                      FStarC_Reflection_Types.term ->
                        (unit, unit, unit) FStar_Reflection_Typing.tot_typing
                          ->
                          (unit, unit, unit)
                            FStar_Reflection_Typing.tot_typing)
  =
  fun u1 ->
    fun u2 ->
      fun g ->
        fun head ->
          fun t1 ->
            fun t2 ->
              fun pre ->
                fun post1 ->
                  fun post2 ->
                    fun head_typing ->
                      fun gg ->
                        fun g_typing ->
                          let d =
                            FStar_Reflection_Typing.T_App
                              (g, head, gg,
                                (Pulse_Reflection_Util.binder_of_t_q
                                   (Pulse_Soundness_Common.g_type_bind u2 t1
                                      t2 post1 post2)
                                   FStarC_Reflection_V2_Data.Q_Explicit),
                                (Pulse_Soundness_Common.bind_res u2 t2 pre
                                   post2), FStarC_TypeChecker_Core.E_Total,
                                head_typing, g_typing) in
                          d