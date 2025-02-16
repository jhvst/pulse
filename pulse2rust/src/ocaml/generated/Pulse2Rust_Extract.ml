open Prims
let (tyvar_of : Prims.string -> Prims.string) =
  fun s ->
    let uu___ =
      FStarC_Compiler_String.substring s Prims.int_one
        ((FStarC_Compiler_String.length s) - Prims.int_one) in
    FStarC_Compiler_String.uppercase uu___
let (varname : Prims.string -> Prims.string) =
  fun s -> FStarC_Compiler_Util.replace_char s 39 95
let (enum_or_struct_name : Prims.string -> Prims.string) = fun s -> s
let (is_internal_name : Prims.string -> Prims.bool) =
  fun s ->
    (((((FStarC_Compiler_Util.starts_with s "uu___") || (s = "_fret")) ||
         (s = "_bind_c"))
        || (s = "_while_c"))
       || (s = "_while_b"))
      || (s = "_if_br")
let (lookup_datacon_in_module1 :
  FStarC_Extraction_ML_Syntax.mlident ->
    FStarC_Extraction_ML_Syntax.mlmodule1 ->
      FStarC_Extraction_ML_Syntax.mlsymbol FStar_Pervasives_Native.option)
  =
  fun s ->
    fun m ->
      match m.FStarC_Extraction_ML_Syntax.mlmodule1_m with
      | FStarC_Extraction_ML_Syntax.MLM_Ty l ->
          FStarC_Compiler_Util.find_map l
            (fun t ->
               match t.FStarC_Extraction_ML_Syntax.tydecl_defn with
               | FStar_Pervasives_Native.Some
                   (FStarC_Extraction_ML_Syntax.MLTD_DType l1) ->
                   FStarC_Compiler_Util.find_map l1
                     (fun uu___ ->
                        match uu___ with
                        | (consname, uu___1) ->
                            if consname = s
                            then
                              FStar_Pervasives_Native.Some
                                (t.FStarC_Extraction_ML_Syntax.tydecl_name)
                            else FStar_Pervasives_Native.None)
               | uu___ -> FStar_Pervasives_Native.None)
      | uu___ -> FStar_Pervasives_Native.None
let (lookup_datacon :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlident ->
      (Prims.string Prims.list * FStarC_Extraction_ML_Syntax.mlsymbol)
        FStar_Pervasives_Native.option)
  =
  fun g ->
    fun s ->
      let d_keys = FStarC_Compiler_Util.smap_keys g.Pulse2Rust_Env.d in
      FStarC_Compiler_Util.find_map d_keys
        (fun k ->
           let uu___ =
             let uu___1 =
               FStarC_Compiler_Util.smap_try_find g.Pulse2Rust_Env.d k in
             FStarC_Compiler_Util.must uu___1 in
           match uu___ with
           | (uu___1, uu___2, decls) ->
               let ropt =
                 FStarC_Compiler_Util.find_map decls
                   (lookup_datacon_in_module1 s) in
               (match ropt with
                | FStar_Pervasives_Native.None ->
                    FStar_Pervasives_Native.None
                | FStar_Pervasives_Native.Some tname ->
                    FStar_Pervasives_Native.Some
                      ((FStarC_Compiler_Util.split k "."), tname)))
let (type_of :
  Pulse2Rust_Env.env -> Pulse2Rust_Rust_Syntax.expr -> Prims.bool) =
  fun g ->
    fun e ->
      match e with
      | Pulse2Rust_Rust_Syntax.Expr_path
          ({ Pulse2Rust_Rust_Syntax.path_segment_name = path_segment_name;
             Pulse2Rust_Rust_Syntax.path_segment_generic_args = uu___;_}::[])
          ->
          let uu___1 = Pulse2Rust_Env.lookup_local g path_segment_name in
          (match uu___1 with
           | FStar_Pervasives_Native.Some (_t, b) -> b
           | FStar_Pervasives_Native.None ->
               let uu___2 =
                 FStarC_Compiler_Util.format1 "lookup in env for %s"
                   path_segment_name in
               Pulse2Rust_Env.fail uu___2)
      | uu___ -> false
let rec (uncurry_arrow :
  FStarC_Extraction_ML_Syntax.mlty ->
    (FStarC_Extraction_ML_Syntax.mlty Prims.list *
      FStarC_Extraction_ML_Syntax.mlty))
  =
  fun t ->
    match t with
    | FStarC_Extraction_ML_Syntax.MLTY_Fun (t1, uu___, t2) ->
        let uu___1 = uncurry_arrow t2 in
        (match uu___1 with | (arg_ts, ret_t) -> ((t1 :: arg_ts), ret_t))
    | uu___ -> ([], t)
let (arg_ts_and_ret_t :
  FStarC_Extraction_ML_Syntax.mltyscheme ->
    (FStarC_Extraction_ML_Syntax.ty_param Prims.list *
      FStarC_Extraction_ML_Syntax.mlty Prims.list *
      FStarC_Extraction_ML_Syntax.mlty))
  =
  fun t ->
    let uu___ = t in
    match uu___ with
    | (tvars, t1) ->
        (match t1 with
         | FStarC_Extraction_ML_Syntax.MLTY_Fun
             (uu___1, FStarC_Extraction_ML_Syntax.E_PURE, uu___2) ->
             let uu___3 = uncurry_arrow t1 in
             (match uu___3 with | (arg_ts, ret_t) -> (tvars, arg_ts, ret_t))
         | FStarC_Extraction_ML_Syntax.MLTY_Fun
             (uu___1, FStarC_Extraction_ML_Syntax.E_IMPURE, uu___2) ->
             let uu___3 = uncurry_arrow t1 in
             (match uu___3 with | (arg_ts, ret_t) -> (tvars, arg_ts, ret_t))
         | uu___1 ->
             let uu___2 =
               let uu___3 = FStarC_Extraction_ML_Syntax.mlty_to_string t1 in
               FStarC_Compiler_Util.format1 "top level arg_ts and ret_t %s"
                 uu___3 in
             Pulse2Rust_Env.fail_nyi uu___2)
let (should_extract_mlpath_with_symbol :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlsymbol Prims.list -> Prims.bool)
  =
  fun g ->
    fun path ->
      let p = FStarC_Compiler_String.concat "." path in
      let b =
        (((p = "Prims") || (p = "Pulse.Lib.Pervasives")) ||
           (p = "FStar.Pervasives.Native"))
          || (p = "FStar.Pervasives") in
      Prims.op_Negation b
let (rust_mod_name :
  FStarC_Extraction_ML_Syntax.mlsymbol Prims.list -> Prims.string) =
  fun path ->
    let uu___ =
      FStarC_Compiler_List.map FStarC_Compiler_String.lowercase path in
    FStarC_Compiler_String.concat "_" uu___
let (extract_path_for_symbol :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlsymbol Prims.list ->
      Prims.string Prims.list)
  =
  fun g ->
    fun path ->
      let prefix =
        let uu___ =
          Pulse2Rust_Env.is_external_lib g
            (FStarC_Compiler_String.concat "." path) in
        if uu___ then "crate" else "super" in
      let uu___ = let uu___1 = rust_mod_name path in [uu___1] in prefix ::
        uu___
let rec (extract_mlty :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlty -> Pulse2Rust_Rust_Syntax.typ)
  =
  fun g ->
    fun t ->
      let mk_slice is_mut t1 =
        let uu___ =
          let uu___1 = extract_mlty g t1 in
          Pulse2Rust_Rust_Syntax.mk_slice_typ uu___1 in
        Pulse2Rust_Rust_Syntax.mk_ref_typ is_mut uu___ in
      match t with
      | FStarC_Extraction_ML_Syntax.MLTY_Var s ->
          let uu___ = tyvar_of s in
          Pulse2Rust_Rust_Syntax.mk_scalar_typ uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.Char.char" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "char"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.UInt8.t" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "u8"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.UInt16.t" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "u16"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.UInt32.t" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "u32"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.Int32.t" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "i32"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.UInt64.t" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "u64"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Prims.string" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "String"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          (((let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___ = "FStar.Int64.t") ||
              (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___ = "Prims.int"))
             ||
             (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___ = "Prims.nat"))
            ||
            (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___ = "Prims.pos")
          -> Pulse2Rust_Rust_Syntax.mk_scalar_typ "i64"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.SizeT.t" ->
          Pulse2Rust_Rust_Syntax.mk_scalar_typ "usize"
      | FStarC_Extraction_ML_Syntax.MLTY_Named ([], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Prims.bool" -> Pulse2Rust_Rust_Syntax.mk_scalar_typ "bool"
      | FStarC_Extraction_ML_Syntax.MLTY_Named (l, p) when
          ((let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___ = "FStar.Pervasives.Native.tuple2") ||
             (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___ = "FStar.Pervasives.Native.tuple3"))
            ||
            (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___ = "Prims.dtuple2")
          ->
          let uu___ = FStarC_Compiler_List.map (extract_mlty g) l in
          Pulse2Rust_Rust_Syntax.mk_tuple_typ uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::[], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Pulse.Lib.Reference.ref" ->
          let is_mut = true in
          let uu___ = extract_mlty g arg in
          Pulse2Rust_Rust_Syntax.mk_ref_typ is_mut uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::[], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Pulse.Lib.Box.box" ->
          let uu___ = extract_mlty g arg in
          Pulse2Rust_Rust_Syntax.mk_box_typ uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::[], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Pulse.Lib.Array.Core.array" ->
          let is_mut = true in mk_slice is_mut arg
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::[], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Pulse.Lib.Slice.slice" ->
          let is_mut = true in mk_slice is_mut arg
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::uu___::[], p) when
          let uu___1 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___1 = "Pulse.Lib.Array.Core.larray" ->
          let is_mut = true in mk_slice is_mut arg
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::[], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "Pulse.Lib.Vec.vec" ->
          let uu___ = extract_mlty g arg in
          Pulse2Rust_Rust_Syntax.mk_vec_typ uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::uu___, p) when
          let uu___1 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___1 = "Pulse.Lib.Mutex.mutex" ->
          let uu___1 = extract_mlty g arg in
          Pulse2Rust_Rust_Syntax.mk_mutex_typ uu___1
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::uu___, p) when
          let uu___1 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___1 = "Pulse.Lib.GlobalVar.gvar" -> extract_mlty g arg
      | FStarC_Extraction_ML_Syntax.MLTY_Named (arg::[], p) when
          let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___ = "FStar.Pervasives.Native.option" ->
          let uu___ = extract_mlty g arg in
          Pulse2Rust_Rust_Syntax.mk_option_typ uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Erased ->
          Pulse2Rust_Rust_Syntax.Typ_unit
      | FStarC_Extraction_ML_Syntax.MLTY_Named (args, p) ->
          let path =
            let uu___ =
              should_extract_mlpath_with_symbol g
                (FStar_Pervasives_Native.fst p) in
            if uu___
            then extract_path_for_symbol g (FStar_Pervasives_Native.fst p)
            else [] in
          let uu___ = FStarC_Compiler_List.map (extract_mlty g) args in
          Pulse2Rust_Rust_Syntax.mk_named_typ path
            (FStar_Pervasives_Native.snd p) uu___
      | FStarC_Extraction_ML_Syntax.MLTY_Fun uu___ ->
          let uu___1 = arg_ts_and_ret_t ([], t) in
          (match uu___1 with
           | (uu___2, arg_ts, ret_t) ->
               let uu___3 = FStarC_Compiler_List.map (extract_mlty g) arg_ts in
               let uu___4 = extract_mlty g ret_t in
               Pulse2Rust_Rust_Syntax.mk_fn_typ uu___3 uu___4)
      | FStarC_Extraction_ML_Syntax.MLTY_Top ->
          Pulse2Rust_Rust_Syntax.Typ_infer
      | uu___ ->
          let uu___1 =
            let uu___2 = FStarC_Extraction_ML_Syntax.mlty_to_string t in
            FStarC_Compiler_Util.format1 "mlty %s" uu___2 in
          Pulse2Rust_Env.fail_nyi uu___1
let (extract_mltyopt :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlty FStar_Pervasives_Native.option ->
      Pulse2Rust_Rust_Syntax.typ)
  =
  fun g ->
    fun t ->
      match t with
      | FStar_Pervasives_Native.None -> Pulse2Rust_Rust_Syntax.Typ_infer
      | FStar_Pervasives_Native.Some t1 -> extract_mlty g t1
let (arg_has_mut_attribute :
  FStarC_Extraction_ML_Syntax.mlexpr Prims.list -> Prims.bool) =
  fun attrs ->
    FStarC_Compiler_List.existsb
      (fun attr ->
         match attr.FStarC_Extraction_ML_Syntax.expr with
         | FStarC_Extraction_ML_Syntax.MLE_CTor (p, uu___) when
             let uu___1 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___1 = "Pulse.Lib.Pervasives.Rust_mut_binder" -> true
         | uu___ -> false) attrs
let (extract_top_level_fn_arg :
  Pulse2Rust_Env.env ->
    Prims.string ->
      FStarC_Extraction_ML_Syntax.mlexpr Prims.list ->
        FStarC_Extraction_ML_Syntax.mlty -> Pulse2Rust_Rust_Syntax.fn_arg)
  =
  fun g ->
    fun arg_name ->
      fun arg_attrs ->
        fun t ->
          let uu___ = arg_has_mut_attribute arg_attrs in
          let uu___1 = extract_mlty g t in
          Pulse2Rust_Rust_Syntax.mk_scalar_fn_arg arg_name uu___ uu___1
let (push_fn_arg :
  Pulse2Rust_Env.env ->
    Prims.string -> Pulse2Rust_Rust_Syntax.fn_arg -> Pulse2Rust_Env.env)
  =
  fun g ->
    fun arg_name ->
      fun arg ->
        match arg with
        | Pulse2Rust_Rust_Syntax.Fn_arg_pat
            { Pulse2Rust_Rust_Syntax.pat_typ_pat = uu___;
              Pulse2Rust_Rust_Syntax.pat_typ_typ = pat_typ_typ;_}
            ->
            let is_mut = false in
            Pulse2Rust_Env.push_local g arg_name pat_typ_typ false
let (extract_top_level_sig :
  Pulse2Rust_Env.env ->
    Prims.bool ->
      Prims.string ->
        Pulse2Rust_Rust_Syntax.generic_type_param Prims.list ->
          Prims.string Prims.list ->
            FStarC_Extraction_ML_Syntax.mlexpr Prims.list Prims.list ->
              FStarC_Extraction_ML_Syntax.mlty Prims.list ->
                FStarC_Extraction_ML_Syntax.mlty
                  FStar_Pervasives_Native.option ->
                  (Pulse2Rust_Rust_Syntax.fn_signature * Pulse2Rust_Env.env))
  =
  fun g ->
    fun fn_const ->
      fun fn_name ->
        fun generic_type_params ->
          fun arg_names ->
            fun arg_attrs ->
              fun arg_ts ->
                fun ret_t ->
                  let fn_args =
                    let uu___ = FStarC_Compiler_List.map varname arg_names in
                    FStarC_Compiler_List.map3 (extract_top_level_fn_arg g)
                      uu___ arg_attrs arg_ts in
                  let fn_ret_t = extract_mltyopt g ret_t in
                  let uu___ =
                    Pulse2Rust_Rust_Syntax.mk_fn_signature fn_const fn_name
                      generic_type_params fn_args fn_ret_t in
                  let uu___1 =
                    let uu___2 = FStarC_Compiler_List.zip arg_names fn_args in
                    FStarC_Compiler_List.fold_left
                      (fun g1 ->
                         fun uu___3 ->
                           match uu___3 with
                           | (arg_name, arg) -> push_fn_arg g1 arg_name arg)
                      g uu___2 in
                  (uu___, uu___1)
let (is_binop :
  Prims.string -> Pulse2Rust_Rust_Syntax.binop FStar_Pervasives_Native.option)
  =
  fun s ->
    if
      (((((s = "Prims.op_Addition") || (s = "FStar.UInt8.add")) ||
           (s = "FStar.UInt16.add"))
          || (s = "FStar.UInt32.add"))
         || (s = "FStar.UInt64.add"))
        || (s = "FStar.SizeT.add")
    then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Add
    else
      if
        (((((s = "Prims.op_Subtraction") || (s = "FStar.SizeT.sub")) ||
             (s = "FStar.UInt8.sub"))
            || (s = "FStar.UInt16.sub"))
           || (s = "FStar.UInt32.sub"))
          || (s = "FStar.UInt64.sub")
      then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Sub
      else
        if
          ((((((((s = "Prims.op_Multiply") || (s = "FStar.Mul.op_Star")) ||
                  (s = "FStar.UInt8.mul"))
                 || (s = "FStar.UInt16.mul"))
                || (s = "FStar.UInt32.mul"))
               || (s = "FStar.UInt32.op_Star_Hat"))
              || (s = "FStar.UInt64.mul"))
             || (s = "FStar.SizeT.mul"))
            || (s = "FStar.SizeT.op_Star_Hat")
        then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Mul
        else
          if s = "Prims.op_disEquality"
          then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Ne
          else
            if
              (((((s = "Prims.op_LessThanOrEqual") || (s = "FStar.UInt8.lte"))
                   || (s = "FStar.UInt16.lte"))
                  || (s = "FStar.UInt32.lte"))
                 || (s = "FStar.UInt64.lte"))
                || (s = "FStar.SizeT.lte")
            then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Le
            else
              if
                (((((s = "Prims.op_LessThan") || (s = "FStar.UInt8.lt")) ||
                     (s = "FStar.UInt16.lt"))
                    || (s = "FStar.UInt32.lt"))
                   || (s = "FStar.UInt64.lt"))
                  || (s = "FStar.SizeT.lt")
              then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Lt
              else
                if
                  (((((s = "Prims.op_GreaterThanOrEqual") ||
                        (s = "FStar.UInt8.gte"))
                       || (s = "FStar.UInt16.gte"))
                      || (s = "FStar.UInt32.gte"))
                     || (s = "FStar.UInt64.gte"))
                    || (s = "FStar.SizeT.gte")
                then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Ge
                else
                  if
                    (((((s = "Prims.op_GreaterThan") ||
                          (s = "FStar.UInt8.gt"))
                         || (s = "FStar.UInt16.gt"))
                        || (s = "FStar.UInt32.gt"))
                       || (s = "FStar.UInt64.gt"))
                      || (s = "FStar.SizeT.gt")
                  then FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Gt
                  else
                    if s = "Prims.op_Equality"
                    then
                      FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.Eq
                    else
                      if
                        (((((s = "Prims.rem") || (s = "FStar.UInt8.rem")) ||
                             (s = "FStar.UInt16.rem"))
                            || (s = "FStar.UInt32.rem"))
                           || (s = "FStar.UInt64.rem"))
                          || (s = "FStar.SizeT.rem")
                      then
                        FStar_Pervasives_Native.Some
                          Pulse2Rust_Rust_Syntax.Rem
                      else
                        if s = "Prims.op_AmpAmp"
                        then
                          FStar_Pervasives_Native.Some
                            Pulse2Rust_Rust_Syntax.And
                        else
                          if s = "Prims.op_BarBar"
                          then
                            FStar_Pervasives_Native.Some
                              Pulse2Rust_Rust_Syntax.Or
                          else
                            if
                              (((s = "FStar.UInt8.shift_left") ||
                                  (s = "FStar.UInt16.shift_left"))
                                 || (s = "FStar.UInt32.shift_left"))
                                || (s = "FStar.UInt64.shift_left")
                            then
                              FStar_Pervasives_Native.Some
                                Pulse2Rust_Rust_Syntax.Shl
                            else
                              if
                                (((s = "FStar.UInt8.shift_right") ||
                                    (s = "FStar.UInt16.shift_right"))
                                   || (s = "FStar.UInt32.shift_right"))
                                  || (s = "FStar.UInt64.shift_right")
                              then
                                FStar_Pervasives_Native.Some
                                  Pulse2Rust_Rust_Syntax.Shr
                              else
                                if
                                  (((s = "FStar.UInt8.logor") ||
                                      (s = "FStar.UInt16.logor"))
                                     || (s = "FStar.UInt32.logor"))
                                    || (s = "FStar.UInt64.logor")
                                then
                                  FStar_Pervasives_Native.Some
                                    Pulse2Rust_Rust_Syntax.BitOr
                                else
                                  if
                                    (((s = "FStar.UInt8.logand") ||
                                        (s = "FStar.UInt16.logand"))
                                       || (s = "FStar.UInt32.logand"))
                                      || (s = "FStar.UInt64.logand")
                                  then
                                    FStar_Pervasives_Native.Some
                                      Pulse2Rust_Rust_Syntax.BitAnd
                                  else FStar_Pervasives_Native.None
let (extract_mlconstant_to_lit :
  FStarC_Extraction_ML_Syntax.mlconstant -> Pulse2Rust_Rust_Syntax.lit) =
  fun c ->
    match c with
    | FStarC_Extraction_ML_Syntax.MLC_Int (lit_int_val, swopt) ->
        let lit_int_signed =
          match swopt with
          | FStar_Pervasives_Native.Some (FStarC_Const.Unsigned, uu___) ->
              FStar_Pervasives_Native.Some false
          | FStar_Pervasives_Native.Some (FStarC_Const.Signed, uu___) ->
              FStar_Pervasives_Native.Some true
          | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None in
        let lit_int_width =
          match swopt with
          | FStar_Pervasives_Native.Some (uu___, FStarC_Const.Int8) ->
              FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.I8
          | FStar_Pervasives_Native.Some (uu___, FStarC_Const.Int16) ->
              FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.I16
          | FStar_Pervasives_Native.Some (uu___, FStarC_Const.Int32) ->
              FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.I32
          | FStar_Pervasives_Native.Some (uu___, FStarC_Const.Int64) ->
              FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.I64
          | FStar_Pervasives_Native.Some (uu___, FStarC_Const.Sizet) ->
              FStar_Pervasives_Native.Some Pulse2Rust_Rust_Syntax.I64
          | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None in
        Pulse2Rust_Rust_Syntax.Lit_int
          {
            Pulse2Rust_Rust_Syntax.lit_int_val = lit_int_val;
            Pulse2Rust_Rust_Syntax.lit_int_signed = lit_int_signed;
            Pulse2Rust_Rust_Syntax.lit_int_width = lit_int_width
          }
    | FStarC_Extraction_ML_Syntax.MLC_Bool b ->
        Pulse2Rust_Rust_Syntax.Lit_bool b
    | FStarC_Extraction_ML_Syntax.MLC_String s ->
        Pulse2Rust_Rust_Syntax.Lit_string s
    | uu___ ->
        let uu___1 =
          let uu___2 = FStarC_Extraction_ML_Syntax.mlconstant_to_string c in
          FStarC_Compiler_Util.format1 "mlconstant_to_lit %s" uu___2 in
        Pulse2Rust_Env.fail_nyi uu___1
let rec (extract_mlpattern_to_pat :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlpattern ->
      (Pulse2Rust_Env.env * Pulse2Rust_Rust_Syntax.pat))
  =
  fun g ->
    fun p ->
      match p with
      | FStarC_Extraction_ML_Syntax.MLP_Wild ->
          (g, Pulse2Rust_Rust_Syntax.Pat_wild)
      | FStarC_Extraction_ML_Syntax.MLP_Const c ->
          let uu___ =
            let uu___1 = extract_mlconstant_to_lit c in
            Pulse2Rust_Rust_Syntax.Pat_lit uu___1 in
          (g, uu___)
      | FStarC_Extraction_ML_Syntax.MLP_Var x ->
          let uu___ =
            Pulse2Rust_Env.push_local g x Pulse2Rust_Rust_Syntax.Typ_infer
              false in
          let uu___1 =
            let uu___2 = is_internal_name x in
            if uu___2
            then Pulse2Rust_Rust_Syntax.Pat_wild
            else
              (let uu___4 = varname x in
               Pulse2Rust_Rust_Syntax.mk_pat_ident uu___4) in
          (uu___, uu___1)
      | FStarC_Extraction_ML_Syntax.MLP_CTor (p1, ps) when
          (((FStar_Pervasives_Native.snd p1) = "Mktuple2") ||
             ((FStar_Pervasives_Native.snd p1) = "Mktuple3"))
            || ((FStar_Pervasives_Native.snd p1) = "Mkdtuple2")
          ->
          let uu___ =
            FStarC_Compiler_List.fold_left_map extract_mlpattern_to_pat g ps in
          (match uu___ with
           | (g1, ps1) ->
               let uu___1 = Pulse2Rust_Rust_Syntax.mk_pat_tuple ps1 in
               (g1, uu___1))
      | FStarC_Extraction_ML_Syntax.MLP_CTor (p1, ps) ->
          let uu___ =
            FStarC_Compiler_List.fold_left_map extract_mlpattern_to_pat g ps in
          (match uu___ with
           | (g1, ps1) ->
               let path =
                 let ropt =
                   lookup_datacon g1 (FStar_Pervasives_Native.snd p1) in
                 match ropt with
                 | FStar_Pervasives_Native.Some (l, t) ->
                     let uu___1 = should_extract_mlpath_with_symbol g1 l in
                     if uu___1
                     then
                       let uu___2 = extract_path_for_symbol g1 l in
                       FStarC_Compiler_List.append uu___2 [t]
                     else []
                 | FStar_Pervasives_Native.None -> [] in
               let uu___1 =
                 Pulse2Rust_Rust_Syntax.mk_pat_ts path
                   (FStar_Pervasives_Native.snd p1) ps1 in
               (g1, uu___1))
      | FStarC_Extraction_ML_Syntax.MLP_Record (p1, fs) ->
          let uu___ =
            let uu___1 =
              FStarC_Compiler_List.map FStar_Pervasives_Native.snd fs in
            FStarC_Compiler_List.fold_left_map extract_mlpattern_to_pat g
              uu___1 in
          (match uu___ with
           | (g1, ps) ->
               let uu___1 =
                 let uu___2 = FStarC_Compiler_List.last p1 in
                 let uu___3 =
                   let uu___4 =
                     FStarC_Compiler_List.map FStar_Pervasives_Native.fst fs in
                   FStarC_Compiler_List.zip uu___4 ps in
                 Pulse2Rust_Rust_Syntax.mk_pat_struct uu___2 uu___3 in
               (g1, uu___1))
      | FStarC_Extraction_ML_Syntax.MLP_Tuple ps ->
          let uu___ =
            FStarC_Compiler_List.fold_left_map extract_mlpattern_to_pat g ps in
          (match uu___ with
           | (g1, ps1) ->
               let uu___1 = Pulse2Rust_Rust_Syntax.mk_pat_tuple ps1 in
               (g1, uu___1))
      | uu___ ->
          let uu___1 =
            let uu___2 = FStarC_Extraction_ML_Syntax.mlpattern_to_string p in
            FStarC_Compiler_Util.format1 "mlpattern_to_pat %s" uu___2 in
          Pulse2Rust_Env.fail_nyi uu___1
let rec (lb_init_and_def :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mllb ->
      (Prims.bool * Pulse2Rust_Rust_Syntax.typ * Pulse2Rust_Rust_Syntax.expr))
  =
  fun g ->
    fun lb ->
      match (((lb.FStarC_Extraction_ML_Syntax.mllb_def).FStarC_Extraction_ML_Syntax.expr),
              (lb.FStarC_Extraction_ML_Syntax.mllb_tysc))
      with
      | (FStarC_Extraction_ML_Syntax.MLE_App
         ({
            FStarC_Extraction_ML_Syntax.expr =
              FStarC_Extraction_ML_Syntax.MLE_TApp
              ({
                 FStarC_Extraction_ML_Syntax.expr =
                   FStarC_Extraction_ML_Syntax.MLE_Name pe;
                 FStarC_Extraction_ML_Syntax.mlty = uu___;
                 FStarC_Extraction_ML_Syntax.loc = uu___1;_},
               uu___2);
            FStarC_Extraction_ML_Syntax.mlty = uu___3;
            FStarC_Extraction_ML_Syntax.loc = uu___4;_},
          init::[]),
         FStar_Pervasives_Native.Some
         ([], FStarC_Extraction_ML_Syntax.MLTY_Named (ty::[], pt))) when
          (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath pe in
           uu___5 = "Pulse.Lib.Reference.alloc") &&
            (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath pt in
             uu___5 = "Pulse.Lib.Reference.ref")
          ->
          let is_mut = true in
          let uu___5 = extract_mlty g ty in
          let uu___6 = extract_mlexpr g init in (is_mut, uu___5, uu___6)
      | (FStarC_Extraction_ML_Syntax.MLE_App
         ({
            FStarC_Extraction_ML_Syntax.expr =
              FStarC_Extraction_ML_Syntax.MLE_TApp
              ({
                 FStarC_Extraction_ML_Syntax.expr =
                   FStarC_Extraction_ML_Syntax.MLE_Name pe;
                 FStarC_Extraction_ML_Syntax.mlty = uu___;
                 FStarC_Extraction_ML_Syntax.loc = uu___1;_},
               uu___2);
            FStarC_Extraction_ML_Syntax.mlty = uu___3;
            FStarC_Extraction_ML_Syntax.loc = uu___4;_},
          init::len::[]),
         FStar_Pervasives_Native.Some
         ([], FStarC_Extraction_ML_Syntax.MLTY_Named (ty::[], pt))) when
          (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath pe in
           uu___5 = "Pulse.Lib.Array.Core.alloc") &&
            (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath pt in
             uu___5 = "Pulse.Lib.Array.Core.array")
          ->
          let init1 = extract_mlexpr g init in
          let len1 = extract_mlexpr g len in
          let is_mut = false in
          let uu___5 =
            let uu___6 =
              let uu___7 =
                FStarC_Compiler_Util.must
                  lb.FStarC_Extraction_ML_Syntax.mllb_tysc in
              FStar_Pervasives_Native.snd uu___7 in
            extract_mlty g uu___6 in
          let uu___6 =
            let uu___7 = Pulse2Rust_Rust_Syntax.mk_repeat init1 len1 in
            Pulse2Rust_Rust_Syntax.mk_reference_expr true uu___7 in
          (is_mut, uu___5, uu___6)
      | uu___ ->
          let is_mut =
            match (lb.FStarC_Extraction_ML_Syntax.mllb_def).FStarC_Extraction_ML_Syntax.expr
            with
            | FStarC_Extraction_ML_Syntax.MLE_App
                ({
                   FStarC_Extraction_ML_Syntax.expr =
                     FStarC_Extraction_ML_Syntax.MLE_TApp
                     ({
                        FStarC_Extraction_ML_Syntax.expr =
                          FStarC_Extraction_ML_Syntax.MLE_Name p;
                        FStarC_Extraction_ML_Syntax.mlty = uu___1;
                        FStarC_Extraction_ML_Syntax.loc = uu___2;_},
                      uu___3::[]);
                   FStarC_Extraction_ML_Syntax.mlty = uu___4;
                   FStarC_Extraction_ML_Syntax.loc = uu___5;_},
                 uu___6)
                ->
                ((let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
                  uu___7 = "Pulse.Lib.Vec.alloc") ||
                   (let uu___7 =
                      FStarC_Extraction_ML_Syntax.string_of_mlpath p in
                    uu___7 = "Pulse.Lib.Box.alloc"))
                  ||
                  (let uu___7 =
                     FStarC_Extraction_ML_Syntax.string_of_mlpath p in
                   uu___7 = "Pulse.Lib.Mutex.lock")
            | uu___1 -> false in
          let uu___1 =
            let uu___2 =
              let uu___3 =
                FStarC_Compiler_Util.must
                  lb.FStarC_Extraction_ML_Syntax.mllb_tysc in
              FStar_Pervasives_Native.snd uu___3 in
            extract_mlty g uu___2 in
          let uu___2 =
            extract_mlexpr g lb.FStarC_Extraction_ML_Syntax.mllb_def in
          (is_mut, uu___1, uu___2)
and (extract_mlexpr :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlexpr -> Pulse2Rust_Rust_Syntax.expr)
  =
  fun g ->
    fun e ->
      match e.FStarC_Extraction_ML_Syntax.expr with
      | FStarC_Extraction_ML_Syntax.MLE_Const
          (FStarC_Extraction_ML_Syntax.MLC_Unit) ->
          Pulse2Rust_Rust_Syntax.Expr_lit Pulse2Rust_Rust_Syntax.Lit_unit
      | FStarC_Extraction_ML_Syntax.MLE_Const c ->
          let elit =
            let uu___ = extract_mlconstant_to_lit c in
            Pulse2Rust_Rust_Syntax.Expr_lit uu___ in
          (match c with
           | FStarC_Extraction_ML_Syntax.MLC_String uu___ ->
               Pulse2Rust_Rust_Syntax.mk_method_call elit "to_string" []
           | uu___ -> elit)
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::[])
          when
          let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___2 = "FStar.SizeT.uint_to_t" -> extract_mlexpr g e1
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::[])
          when
          let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___2 = "FStar.SizeT.uint16_to_sizet" ->
          let uu___2 = extract_mlexpr g e1 in
          let uu___3 = Pulse2Rust_Rust_Syntax.mk_scalar_typ "usize" in
          Pulse2Rust_Rust_Syntax.mk_cast uu___2 uu___3
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::[])
          when
          ((let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___2 = "FStar.Int.Cast.uint16_to_uint8") ||
             (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___2 = "FStar.Int.Cast.uint32_to_uint8"))
            ||
            (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___2 = "FStar.Int.Cast.uint64_to_uint8")
          ->
          let uu___2 = extract_mlexpr g e1 in
          let uu___3 = Pulse2Rust_Rust_Syntax.mk_scalar_typ "u8" in
          Pulse2Rust_Rust_Syntax.mk_cast uu___2 uu___3
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::[])
          when
          ((let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___2 = "FStar.Int.Cast.uint8_to_uint16") ||
             (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___2 = "FStar.Int.Cast.uint32_to_uint16"))
            ||
            (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___2 = "FStar.Int.Cast.uint64_to_uint16")
          ->
          let uu___2 = extract_mlexpr g e1 in
          let uu___3 = Pulse2Rust_Rust_Syntax.mk_scalar_typ "u16" in
          Pulse2Rust_Rust_Syntax.mk_cast uu___2 uu___3
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::[])
          when
          ((let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___2 = "FStar.Int.Cast.uint8_to_uint32") ||
             (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___2 = "FStar.Int.Cast.uint16_to_uint32"))
            ||
            (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___2 = "FStar.Int.Cast.uint64_to_uint32")
          ->
          let uu___2 = extract_mlexpr g e1 in
          let uu___3 = Pulse2Rust_Rust_Syntax.mk_scalar_typ "u32" in
          Pulse2Rust_Rust_Syntax.mk_cast uu___2 uu___3
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::[])
          when
          ((let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___2 = "FStar.Int.Cast.uint8_to_uint64") ||
             (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___2 = "FStar.Int.Cast.uint16_to_uint64"))
            ||
            (let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___2 = "FStar.Int.Cast.uint32_to_uint64")
          ->
          let uu___2 = extract_mlexpr g e1 in
          let uu___3 = Pulse2Rust_Rust_Syntax.mk_scalar_typ "u64" in
          Pulse2Rust_Rust_Syntax.mk_cast uu___2 uu___3
      | FStarC_Extraction_ML_Syntax.MLE_Var x ->
          let uu___ = varname x in
          Pulse2Rust_Rust_Syntax.mk_expr_path_singl uu___
      | FStarC_Extraction_ML_Syntax.MLE_Name p ->
          let uu___ =
            should_extract_mlpath_with_symbol g
              (FStar_Pervasives_Native.fst p) in
          if uu___
          then
            let uu___1 =
              let uu___2 =
                extract_path_for_symbol g (FStar_Pervasives_Native.fst p) in
              FStarC_Compiler_List.append uu___2
                [FStar_Pervasives_Native.snd p] in
            Pulse2Rust_Rust_Syntax.mk_expr_path uu___1
          else
            Pulse2Rust_Rust_Syntax.mk_expr_path_singl
              (FStar_Pervasives_Native.snd p)
      | FStarC_Extraction_ML_Syntax.MLE_Let uu___ ->
          let uu___1 = extract_mlexpr_to_stmts g e in
          Pulse2Rust_Rust_Syntax.mk_block_expr uu___1
      | FStarC_Extraction_ML_Syntax.MLE_Seq uu___ ->
          let uu___1 = extract_mlexpr_to_stmts g e in
          Pulse2Rust_Rust_Syntax.mk_block_expr uu___1
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::[])
          when
          (((let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___5 = "Pulse.Lib.Pervasives.tfst") ||
              (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___5 = "FStar.Pervasives.Native.__proj__Mktuple2__item___1"))
             ||
             (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___5 = "FStar.Pervasives.Native.fst"))
            ||
            (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___5 = "FStar.Pervasives.dfst")
          ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_expr_field_unnamed e2 Prims.int_zero
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::[])
          when
          (((let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___5 = "Pulse.Lib.Pervasives.tsnd") ||
              (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___5 = "FStar.Pervasives.Native.__proj__Mktuple2__item___2"))
             ||
             (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___5 = "FStar.Pervasives.Native.snd"))
            ||
            (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___5 = "FStar.Pervasives.dsnd")
          ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_expr_field_unnamed e2 Prims.int_one
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Pervasives.tthd" ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_expr_field_unnamed e2 (Prims.of_int (2))
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::uu___5::[])
          when
          ((let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___6 = "Pulse.Lib.Reference.op_Colon_Equals") ||
             (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___6 = "Pulse.Lib.Box.op_Colon_Equals"))
            ||
            (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___6 = "Pulse.Lib.Mutex.op_Colon_Equals")
          ->
          let e11 = extract_mlexpr g e1 in
          let e21 = extract_mlexpr g e2 in
          let b = type_of g e11 in
          let is_mutex_guard =
            let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___6 = "Pulse.Lib.Mutex.op_Colon_Equals" in
          if is_mutex_guard || (Prims.op_Negation b)
          then Pulse2Rust_Rust_Syntax.mk_ref_assign e11 e21
          else Pulse2Rust_Rust_Syntax.mk_assign e11 e21
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::uu___5::uu___6::[])
          when
          ((let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___7 = "Pulse.Lib.Reference.op_Bang") ||
             (let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___7 = "Pulse.Lib.Box.op_Bang"))
            ||
            (let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___7 = "Pulse.Lib.Mutex.op_Bang")
          ->
          let e2 = extract_mlexpr g e1 in
          let b = type_of g e2 in
          let is_mutex_guard =
            let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            uu___7 = "Pulse.Lib.Mutex.op_Bang" in
          if is_mutex_guard || (Prims.op_Negation b)
          then Pulse2Rust_Rust_Syntax.mk_ref_read e2
          else e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::uu___5::[])
          when
          let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___6 = "Pulse.Lib.Pervasives.ref_apply" ->
          let uu___6 = extract_mlexpr g e1 in
          let uu___7 = let uu___8 = extract_mlexpr g e2 in [uu___8] in
          Pulse2Rust_Rust_Syntax.mk_call uu___6 uu___7
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Box.box_to_ref" ->
          let e2 = extract_mlexpr g e1 in
          let is_mut = true in
          Pulse2Rust_Rust_Syntax.mk_reference_expr is_mut e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Box.alloc" ->
          let e2 = extract_mlexpr g e1 in
          let uu___5 =
            Pulse2Rust_Rust_Syntax.mk_expr_path
              ["std"; "boxed"; "Box"; "new"] in
          Pulse2Rust_Rust_Syntax.mk_call uu___5 [e2]
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::i::uu___5)
          when
          ((((let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___6 = "Pulse.Lib.Array.Core.op_Array_Access") ||
               (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
                uu___6 = "Pulse.Lib.Array.Core.pts_to_range_index"))
              ||
              (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___6 = "Pulse.Lib.Slice.op_Array_Access"))
             ||
             (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___6 = "Pulse.Lib.Vec.op_Array_Access"))
            ||
            (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___6 = "Pulse.Lib.Vec.read_ref")
          ->
          let uu___6 = extract_mlexpr g e1 in
          let uu___7 = extract_mlexpr g i in
          Pulse2Rust_Rust_Syntax.mk_expr_index uu___6 uu___7
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::e3::uu___5)
          when
          ((((let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___6 = "Pulse.Lib.Array.Core.op_Array_Assignment") ||
               (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
                uu___6 = "Pulse.Lib.Array.Core.pts_to_range_upd"))
              ||
              (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___6 = "Pulse.Lib.Slice.op_Array_Assignment"))
             ||
             (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              uu___6 = "Pulse.Lib.Vec.op_Array_Assignment"))
            ||
            (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___6 = "Pulse.Lib.Vec.write_ref")
          ->
          let e11 = extract_mlexpr g e1 in
          let e21 = extract_mlexpr g e2 in
          let e31 = extract_mlexpr g e3 in
          let uu___6 = Pulse2Rust_Rust_Syntax.mk_expr_index e11 e21 in
          Pulse2Rust_Rust_Syntax.mk_assign uu___6 e31
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                a::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___2;
             FStarC_Extraction_ML_Syntax.loc = uu___3;_},
           e_v::e_i::e_x::uu___4)
          when
          (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
           uu___5 = "Pulse.Lib.Vec.replace_i") ||
            (let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___5 = "Pulse.Lib.Vec.replace_i_ref")
          ->
          let e_v1 = extract_mlexpr g e_v in
          let e_i1 = extract_mlexpr g e_i in
          let e_x1 = extract_mlexpr g e_x in
          let is_mut = true in
          let uu___5 = extract_mlty g a in
          let uu___6 =
            let uu___7 = Pulse2Rust_Rust_Syntax.mk_expr_index e_v1 e_i1 in
            Pulse2Rust_Rust_Syntax.mk_reference_expr is_mut uu___7 in
          Pulse2Rust_Rust_Syntax.mk_mem_replace uu___5 uu___6 e_x1
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                a::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___2;
             FStarC_Extraction_ML_Syntax.loc = uu___3;_},
           e_r::e_x::uu___4)
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Reference.replace" ->
          let uu___5 = extract_mlty g a in
          let uu___6 = extract_mlexpr g e_r in
          let uu___7 = extract_mlexpr g e_x in
          Pulse2Rust_Rust_Syntax.mk_mem_replace uu___5 uu___6 uu___7
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::uu___5)
          when
          let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___6 = "Pulse.Lib.Slice.from_array" -> extract_mlexpr g e1
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::uu___5::i::uu___6)
          when
          let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___7 = "Pulse.Lib.Slice.split" ->
          let uu___7 = extract_mlexpr g e1 in
          let uu___8 = let uu___9 = extract_mlexpr g i in [uu___9] in
          Pulse2Rust_Rust_Syntax.mk_method_call uu___7 "split_at_mut" uu___8
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           s::uu___5::a::b::uu___6)
          when
          let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___7 = "Pulse.Lib.Slice.subslice" ->
          let mutb = true in
          let uu___7 =
            let uu___8 = extract_mlexpr g s in
            let uu___9 =
              let uu___10 =
                let uu___11 = extract_mlexpr g a in
                FStar_Pervasives_Native.Some uu___11 in
              let uu___11 =
                let uu___12 = extract_mlexpr g b in
                FStar_Pervasives_Native.Some uu___12 in
              Pulse2Rust_Rust_Syntax.mk_range uu___10
                Pulse2Rust_Rust_Syntax.RangeLimitsHalfOpen uu___11 in
            Pulse2Rust_Rust_Syntax.mk_expr_index uu___8 uu___9 in
          Pulse2Rust_Rust_Syntax.mk_reference_expr true uu___7
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           a::uu___5::b::uu___6)
          when
          let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___7 = "Pulse.Lib.Slice.copy" ->
          let uu___7 = extract_mlexpr g a in
          let uu___8 = let uu___9 = extract_mlexpr g b in [uu___9] in
          Pulse2Rust_Rust_Syntax.mk_method_call uu___7 "copy_from_slice"
            uu___8
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           a::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Slice.len" ->
          let uu___5 = extract_mlexpr g a in
          Pulse2Rust_Rust_Syntax.mk_method_call uu___5 "len" []
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Vec.vec_to_array" ->
          let e2 = extract_mlexpr g e1 in
          let is_mut = true in
          Pulse2Rust_Rust_Syntax.mk_reference_expr is_mut e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Vec.alloc" ->
          let e11 = extract_mlexpr g e1 in
          let e21 = extract_mlexpr g e2 in
          let uu___5 =
            Pulse2Rust_Rust_Syntax.mk_expr_path_singl
              Pulse2Rust_Rust_Syntax.vec_new_fn in
          Pulse2Rust_Rust_Syntax.mk_call uu___5 [e11; e21]
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Array.Core.alloc" ->
          let uu___5 =
            let uu___6 = FStarC_Extraction_ML_Syntax.mlexpr_to_string e in
            FStarC_Compiler_Util.format1 "mlexpr %s" uu___6 in
          Pulse2Rust_Env.fail_nyi uu___5
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::uu___5::[])
          when
          (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
           uu___6 = "Pulse.Lib.Vec.free") ||
            (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___6 = "Pulse.Lib.Box.free")
          ->
          let e2 = extract_mlexpr g e1 in
          let uu___6 = Pulse2Rust_Rust_Syntax.mk_expr_path_singl "drop" in
          Pulse2Rust_Rust_Syntax.mk_call uu___6 [e2]
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::e1::uu___6)
          when
          let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___7 = "Pulse.Lib.Mutex.new_mutex" ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_new_mutex e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::uu___6::e1::uu___7)
          when
          let uu___8 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___8 = "Pulse.Lib.Mutex.lock" ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_lock_mutex e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::e1::uu___6)
          when
          let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___7 = "Pulse.Lib.Mutex.lock" ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_lock_mutex e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::uu___6::uu___7::e1::uu___8)
          when
          let uu___9 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___9 = "Pulse.Lib.Mutex.unlock" ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_unlock_mutex e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::uu___6::e1::uu___7)
          when
          let uu___8 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___8 = "Pulse.Lib.Mutex.unlock" ->
          let e2 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_unlock_mutex e2
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                a::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___2;
             FStarC_Extraction_ML_Syntax.loc = uu___3;_},
           e_mg::e_x::uu___4)
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Mutex.replace" ->
          let is_mut = true in
          let uu___5 = extract_mlty g a in
          let uu___6 =
            let uu___7 = extract_mlexpr g e_mg in
            Pulse2Rust_Rust_Syntax.mk_reference_expr is_mut uu___7 in
          let uu___7 = extract_mlexpr g e_x in
          Pulse2Rust_Rust_Syntax.mk_mem_replace uu___5 uu___6 uu___7
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::[])
          when
          let uu___5 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___5 = "Pulse.Lib.Array.Core.free" ->
          let uu___5 =
            let uu___6 = FStarC_Extraction_ML_Syntax.mlexpr_to_string e in
            FStarC_Compiler_Util.format1 "mlexpr %s" uu___6 in
          Pulse2Rust_Env.fail_nyi uu___5
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           {
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Fun (uu___2, cond);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_}::{
                                                            FStarC_Extraction_ML_Syntax.expr
                                                              =
                                                              FStarC_Extraction_ML_Syntax.MLE_Fun
                                                              (uu___5, body);
                                                            FStarC_Extraction_ML_Syntax.mlty
                                                              = uu___6;
                                                            FStarC_Extraction_ML_Syntax.loc
                                                              = uu___7;_}::[])
          when
          let uu___8 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___8 = "Pulse.Lib.Dv.while_" ->
          let expr_while_cond = extract_mlexpr g cond in
          let expr_while_body = extract_mlexpr_to_stmts g body in
          Pulse2Rust_Rust_Syntax.Expr_while
            {
              Pulse2Rust_Rust_Syntax.expr_while_cond = expr_while_cond;
              Pulse2Rust_Rust_Syntax.expr_while_body = expr_while_body
            }
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::uu___6::e1::uu___7)
          when
          let uu___8 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___8 = "Pulse.Lib.GlobalVar.mk_gvar" ->
          let uu___8 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_call uu___8
            [Pulse2Rust_Rust_Syntax.Expr_lit Pulse2Rust_Rust_Syntax.Lit_unit]
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5::e1::uu___6)
          when
          let uu___7 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___7 = "Pulse.Lib.GlobalVar.read_gvar" ->
          let uu___7 = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_reference_expr false uu___7
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5)
          when
          (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
           uu___6 = "failwith") ||
            (let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___6 = "Pulse.Lib.Dv.unreachable")
          ->
          let uu___6 =
            Pulse2Rust_Rust_Syntax.mk_expr_path_singl
              Pulse2Rust_Rust_Syntax.panic_fn in
          Pulse2Rust_Rust_Syntax.mk_call uu___6 []
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           uu___2)
          when
          (let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
           uu___3 = "failwith") ||
            (let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___3 = "Pulse.Lib.Dv.unreachable")
          ->
          let uu___3 =
            Pulse2Rust_Rust_Syntax.mk_expr_path_singl
              Pulse2Rust_Rust_Syntax.panic_fn in
          Pulse2Rust_Rust_Syntax.mk_call uu___3 []
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::e2::[])
          when
          let uu___2 =
            let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            is_binop uu___3 in
          FStar_Pervasives_Native.uu___is_Some uu___2 ->
          let e11 = extract_mlexpr g e1 in
          let op =
            let uu___2 =
              let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              is_binop uu___3 in
            FStarC_Compiler_Util.must uu___2 in
          let e21 = extract_mlexpr g e2 in
          Pulse2Rust_Rust_Syntax.mk_binop e11 op e21
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2::[]);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           e1::e2::[])
          when
          let uu___5 =
            let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            is_binop uu___6 in
          FStar_Pervasives_Native.uu___is_Some uu___5 ->
          let e11 = extract_mlexpr g e1 in
          let op =
            let uu___5 =
              let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              is_binop uu___6 in
            FStarC_Compiler_Util.must uu___5 in
          let e21 = extract_mlexpr g e2 in
          Pulse2Rust_Rust_Syntax.mk_binop e11 op e21
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_Name p;
             FStarC_Extraction_ML_Syntax.mlty = uu___;
             FStarC_Extraction_ML_Syntax.loc = uu___1;_},
           e1::e2::[])
          when
          let uu___2 =
            let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
            is_binop uu___3 in
          FStar_Pervasives_Native.uu___is_Some uu___2 ->
          let e11 = extract_mlexpr g e1 in
          let op =
            let uu___2 =
              let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
              is_binop uu___3 in
            FStarC_Compiler_Util.must uu___2 in
          let e21 = extract_mlexpr g e2 in
          Pulse2Rust_Rust_Syntax.mk_binop e11 op e21
      | FStarC_Extraction_ML_Syntax.MLE_App (head, args) ->
          let head1 = extract_mlexpr g head in
          let args1 = FStarC_Compiler_List.map (extract_mlexpr g) args in
          Pulse2Rust_Rust_Syntax.mk_call head1 args1
      | FStarC_Extraction_ML_Syntax.MLE_CTor (p, e1::e2::uu___) when
          (FStar_Pervasives_Native.snd p) = "Mkdtuple2" ->
          let uu___1 =
            let uu___2 = extract_mlexpr g e1 in
            let uu___3 = let uu___4 = extract_mlexpr g e2 in [uu___4] in
            uu___2 :: uu___3 in
          Pulse2Rust_Rust_Syntax.mk_expr_tuple uu___1
      | FStarC_Extraction_ML_Syntax.MLE_CTor (p, args) ->
          let is_native =
            (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___ = "FStar.Pervasives.Native.Some") ||
              (let uu___ = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___ = "FStar.Pervasives.Native.None") in
          let ty_name =
            match e.FStarC_Extraction_ML_Syntax.mlty with
            | FStarC_Extraction_ML_Syntax.MLTY_Named (uu___, p1) ->
                enum_or_struct_name (FStar_Pervasives_Native.snd p1)
            | uu___ -> failwith "S.MLE_CTor: unexpected type" in
          let dexpr =
            if is_native
            then
              Pulse2Rust_Rust_Syntax.mk_expr_path_singl
                (FStar_Pervasives_Native.snd p)
            else
              (let path =
                 let uu___1 =
                   should_extract_mlpath_with_symbol g
                     (FStar_Pervasives_Native.fst p) in
                 if uu___1
                 then
                   extract_path_for_symbol g (FStar_Pervasives_Native.fst p)
                 else [] in
               Pulse2Rust_Rust_Syntax.mk_expr_path
                 (FStarC_Compiler_List.append path
                    [ty_name; FStar_Pervasives_Native.snd p])) in
          if (FStarC_Compiler_List.length args) = Prims.int_zero
          then dexpr
          else
            (let uu___1 = FStarC_Compiler_List.map (extract_mlexpr g) args in
             Pulse2Rust_Rust_Syntax.mk_call dexpr uu___1)
      | FStarC_Extraction_ML_Syntax.MLE_TApp (head, uu___) ->
          extract_mlexpr g head
      | FStarC_Extraction_ML_Syntax.MLE_If (cond, if_then, if_else_opt) ->
          let cond1 = extract_mlexpr g cond in
          let then_ = extract_mlexpr_to_stmts g if_then in
          let else_ =
            FStarC_Compiler_Util.map_option (extract_mlexpr g) if_else_opt in
          let else_1 =
            match else_ with
            | FStar_Pervasives_Native.None -> else_
            | FStar_Pervasives_Native.Some (Pulse2Rust_Rust_Syntax.Expr_if
                uu___) -> else_
            | FStar_Pervasives_Native.Some (Pulse2Rust_Rust_Syntax.Expr_block
                uu___) -> else_
            | FStar_Pervasives_Native.Some else_2 ->
                let uu___ =
                  Pulse2Rust_Rust_Syntax.mk_block_expr
                    [Pulse2Rust_Rust_Syntax.Stmt_expr else_2] in
                FStar_Pervasives_Native.Some uu___ in
          Pulse2Rust_Rust_Syntax.mk_if cond1 then_ else_1
      | FStarC_Extraction_ML_Syntax.MLE_Match (e1, branches) ->
          let e2 = extract_mlexpr g e1 in
          let uu___ =
            FStarC_Compiler_List.map (extract_mlbranch_to_arm g) branches in
          Pulse2Rust_Rust_Syntax.mk_match e2 uu___
      | FStarC_Extraction_ML_Syntax.MLE_Coerce (e1, uu___, uu___1) ->
          extract_mlexpr g e1
      | FStarC_Extraction_ML_Syntax.MLE_Record (p, nm, fields) ->
          let path =
            let uu___ = should_extract_mlpath_with_symbol g p in
            if uu___ then extract_path_for_symbol g p else [] in
          let uu___ =
            FStarC_Compiler_List.map
              (fun uu___1 ->
                 match uu___1 with
                 | (f, e1) -> let uu___2 = extract_mlexpr g e1 in (f, uu___2))
              fields in
          Pulse2Rust_Rust_Syntax.mk_expr_struct
            (FStarC_Compiler_List.append path [nm]) uu___
      | FStarC_Extraction_ML_Syntax.MLE_Proj (e1, p) ->
          let uu___ = extract_mlexpr g e1 in
          Pulse2Rust_Rust_Syntax.mk_expr_field uu___
            (FStar_Pervasives_Native.snd p)
      | FStarC_Extraction_ML_Syntax.MLE_Tuple l ->
          let uu___ = FStarC_Compiler_List.map (extract_mlexpr g) l in
          Pulse2Rust_Rust_Syntax.mk_expr_tuple uu___
      | uu___ ->
          let uu___1 =
            let uu___2 = FStarC_Extraction_ML_Syntax.mlexpr_to_string e in
            FStarC_Compiler_Util.format1 "mlexpr %s" uu___2 in
          Pulse2Rust_Env.fail_nyi uu___1
and (extract_mlexpr_to_stmts :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlexpr ->
      Pulse2Rust_Rust_Syntax.stmt Prims.list)
  =
  fun g ->
    fun e ->
      match e.FStarC_Extraction_ML_Syntax.expr with
      | FStarC_Extraction_ML_Syntax.MLE_Const
          (FStarC_Extraction_ML_Syntax.MLC_Unit) -> []
      | FStarC_Extraction_ML_Syntax.MLE_Let
          ((uu___,
            { FStarC_Extraction_ML_Syntax.mllb_name = uu___1;
              FStarC_Extraction_ML_Syntax.mllb_tysc = uu___2;
              FStarC_Extraction_ML_Syntax.mllb_add_unit = uu___3;
              FStarC_Extraction_ML_Syntax.mllb_def =
                {
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Const
                    (FStarC_Extraction_ML_Syntax.MLC_Unit);
                  FStarC_Extraction_ML_Syntax.mlty = uu___4;
                  FStarC_Extraction_ML_Syntax.loc = uu___5;_};
              FStarC_Extraction_ML_Syntax.mllb_attrs = uu___6;
              FStarC_Extraction_ML_Syntax.mllb_meta = uu___7;
              FStarC_Extraction_ML_Syntax.print_typ = uu___8;_}::[]),
           e1)
          -> extract_mlexpr_to_stmts g e1
      | FStarC_Extraction_ML_Syntax.MLE_Let
          ((FStarC_Extraction_ML_Syntax.NonRec, lb::[]), e1) ->
          let uu___ = lb_init_and_def g lb in
          (match uu___ with
           | (is_mut, ty, init) ->
               let topt = FStar_Pervasives_Native.None in
               let s =
                 let uu___1 =
                   match lb.FStarC_Extraction_ML_Syntax.mllb_tysc with
                   | FStar_Pervasives_Native.Some
                       (uu___2, FStarC_Extraction_ML_Syntax.MLTY_Erased) ->
                       FStar_Pervasives_Native.None
                   | uu___2 ->
                       let uu___3 =
                         varname lb.FStarC_Extraction_ML_Syntax.mllb_name in
                       FStar_Pervasives_Native.Some uu___3 in
                 Pulse2Rust_Rust_Syntax.mk_local_stmt uu___1 topt is_mut init in
               let uu___1 =
                 let uu___2 =
                   Pulse2Rust_Env.push_local g
                     lb.FStarC_Extraction_ML_Syntax.mllb_name ty is_mut in
                 extract_mlexpr_to_stmts uu___2 e1 in
               s :: uu___1)
      | FStarC_Extraction_ML_Syntax.MLE_Seq es ->
          let rec fixup_nonterminal_exprs uu___ =
            match uu___ with
            | [] -> []
            | e1::[] -> [e1]
            | (Pulse2Rust_Rust_Syntax.Stmt_expr e1)::es1 ->
                let uu___1 = fixup_nonterminal_exprs es1 in
                (Pulse2Rust_Rust_Syntax.Stmt_local
                   {
                     Pulse2Rust_Rust_Syntax.local_stmt_pat =
                       FStar_Pervasives_Native.None;
                     Pulse2Rust_Rust_Syntax.local_stmt_init =
                       (FStar_Pervasives_Native.Some e1)
                   })
                  :: uu___1
            | e1::es1 ->
                let uu___1 = fixup_nonterminal_exprs es1 in e1 :: uu___1 in
          let rec aux uu___ =
            match uu___ with
            | [] -> []
            | e1::es1 ->
                let uu___1 = extract_mlexpr_to_stmts g e1 in
                let uu___2 = aux es1 in
                FStarC_Compiler_List.op_At uu___1 uu___2 in
          let uu___ = aux es in fixup_nonterminal_exprs uu___
      | FStarC_Extraction_ML_Syntax.MLE_App
          ({
             FStarC_Extraction_ML_Syntax.expr =
               FStarC_Extraction_ML_Syntax.MLE_TApp
               ({
                  FStarC_Extraction_ML_Syntax.expr =
                    FStarC_Extraction_ML_Syntax.MLE_Name p;
                  FStarC_Extraction_ML_Syntax.mlty = uu___;
                  FStarC_Extraction_ML_Syntax.loc = uu___1;_},
                uu___2);
             FStarC_Extraction_ML_Syntax.mlty = uu___3;
             FStarC_Extraction_ML_Syntax.loc = uu___4;_},
           uu___5)
          when
          let uu___6 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
          uu___6 = "failwith" ->
          let uu___6 =
            let uu___7 =
              let uu___8 =
                Pulse2Rust_Rust_Syntax.mk_expr_path_singl
                  Pulse2Rust_Rust_Syntax.panic_fn in
              Pulse2Rust_Rust_Syntax.mk_call uu___8 [] in
            Pulse2Rust_Rust_Syntax.Stmt_expr uu___7 in
          [uu___6]
      | uu___ ->
          let uu___1 =
            let uu___2 = extract_mlexpr g e in
            Pulse2Rust_Rust_Syntax.Stmt_expr uu___2 in
          [uu___1]
and (extract_mlbranch_to_arm :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlbranch -> Pulse2Rust_Rust_Syntax.arm)
  =
  fun g ->
    fun uu___ ->
      match uu___ with
      | (pat, pat_guard, body) ->
          (match pat_guard with
           | FStar_Pervasives_Native.Some e ->
               let uu___1 =
                 let uu___2 = FStarC_Extraction_ML_Syntax.mlexpr_to_string e in
                 FStarC_Compiler_Util.format1
                   "mlbranch_to_arm with pat guard %s" uu___2 in
               Pulse2Rust_Env.fail_nyi uu___1
           | FStar_Pervasives_Native.None ->
               let uu___1 = extract_mlpattern_to_pat g pat in
               (match uu___1 with
                | (g1, pat1) ->
                    let arm_body = extract_mlexpr g1 body in
                    Pulse2Rust_Rust_Syntax.mk_arm pat1 arm_body))
let (has_rust_const_fn_attribute :
  FStarC_Extraction_ML_Syntax.mllb -> Prims.bool) =
  fun lb ->
    FStarC_Compiler_List.existsb
      (fun attr ->
         match attr.FStarC_Extraction_ML_Syntax.expr with
         | FStarC_Extraction_ML_Syntax.MLE_CTor (p, uu___) when
             let uu___1 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
             uu___1 = "Pulse.Lib.Pervasives.Rust_const_fn" -> true
         | uu___ -> false) lb.FStarC_Extraction_ML_Syntax.mllb_attrs
let (extract_generic_type_param_trait_bounds :
  FStarC_Extraction_ML_Syntax.mlexpr Prims.list ->
    Prims.string Prims.list Prims.list)
  =
  fun attrs ->
    let uu___ =
      let uu___1 =
        FStarC_Compiler_List.tryFind
          (fun attr ->
             match attr.FStarC_Extraction_ML_Syntax.expr with
             | FStarC_Extraction_ML_Syntax.MLE_CTor (p, uu___2) when
                 let uu___3 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
                 uu___3 = "Pulse.Lib.Pervasives.Rust_generics_bounds" -> true
             | uu___2 -> false) attrs in
      FStarC_Compiler_Util.map_option
        (fun attr ->
           let uu___2 = attr.FStarC_Extraction_ML_Syntax.expr in
           match uu___2 with
           | FStarC_Extraction_ML_Syntax.MLE_CTor (p, args) ->
               let uu___3 =
                 let uu___4 = FStarC_Compiler_List.hd args in
                 FStarC_Extraction_ML_Util.list_elements uu___4 in
               (match uu___3 with
                | FStar_Pervasives_Native.Some l ->
                    let uu___4 =
                      FStarC_Compiler_List.map
                        (fun e ->
                           match e.FStarC_Extraction_ML_Syntax.expr with
                           | FStarC_Extraction_ML_Syntax.MLE_Const
                               (FStarC_Extraction_ML_Syntax.MLC_String s) ->
                               s
                           | uu___5 ->
                               failwith
                                 "unexpected generic type param bounds") l in
                    FStarC_Compiler_List.map
                      (fun bound -> FStarC_Compiler_Util.split bound "::")
                      uu___4)) uu___1 in
    FStarC_Compiler_Util.dflt [] uu___
let (extract_generic_type_params :
  FStarC_Extraction_ML_Syntax.ty_param Prims.list ->
    Pulse2Rust_Rust_Syntax.generic_type_param Prims.list)
  =
  fun tyvars ->
    FStarC_Compiler_List.map
      (fun uu___ ->
         match uu___ with
         | { FStarC_Extraction_ML_Syntax.ty_param_name = ty_param_name;
             FStarC_Extraction_ML_Syntax.ty_param_attrs = ty_param_attrs;_}
             ->
             let uu___1 = tyvar_of ty_param_name in
             let uu___2 =
               extract_generic_type_param_trait_bounds ty_param_attrs in
             Pulse2Rust_Rust_Syntax.mk_generic_type_param uu___1 uu___2)
      tyvars
let (extract_top_level_lb :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlletbinding ->
      (Pulse2Rust_Rust_Syntax.item * Pulse2Rust_Env.env))
  =
  fun g ->
    fun lbs ->
      let uu___ = lbs in
      match uu___ with
      | (is_rec, lbs1) ->
          let uu___1 = lbs1 in
          (match uu___1 with
           | lb::[] ->
               (match (lb.FStarC_Extraction_ML_Syntax.mllb_def).FStarC_Extraction_ML_Syntax.expr
                with
                | FStarC_Extraction_ML_Syntax.MLE_Fun (bs, body) ->
                    let arg_names =
                      FStarC_Compiler_List.map
                        (fun b -> b.FStarC_Extraction_ML_Syntax.mlbinder_name)
                        bs in
                    let arg_attrs =
                      FStarC_Compiler_List.map
                        (fun b ->
                           b.FStarC_Extraction_ML_Syntax.mlbinder_attrs) bs in
                    let uu___2 =
                      match lb.FStarC_Extraction_ML_Syntax.mllb_tysc with
                      | FStar_Pervasives_Native.Some tsc ->
                          let uu___3 = arg_ts_and_ret_t tsc in
                          (match uu___3 with
                           | (tvars, arg_ts, ret_t) ->
                               (tvars, arg_ts,
                                 (FStar_Pervasives_Native.Some ret_t)))
                      | FStar_Pervasives_Native.None ->
                          let uu___3 =
                            FStarC_Compiler_List.map
                              (fun b ->
                                 b.FStarC_Extraction_ML_Syntax.mlbinder_ty)
                              bs in
                          ([], uu___3, FStar_Pervasives_Native.None) in
                    (match uu___2 with
                     | (tvars, arg_ts, ret_t) ->
                         let fn_const = has_rust_const_fn_attribute lb in
                         let uu___3 =
                           let uu___4 = extract_generic_type_params tvars in
                           extract_top_level_sig g fn_const
                             lb.FStarC_Extraction_ML_Syntax.mllb_name uu___4
                             arg_names arg_attrs arg_ts ret_t in
                         (match uu___3 with
                          | (fn_sig, g_body) ->
                              let fn_body =
                                extract_mlexpr_to_stmts g_body body in
                              let uu___4 =
                                let uu___5 =
                                  Pulse2Rust_Rust_Syntax.mk_fn fn_sig fn_body in
                                Pulse2Rust_Rust_Syntax.Item_fn uu___5 in
                              let uu___5 =
                                Pulse2Rust_Env.push_fn g
                                  lb.FStarC_Extraction_ML_Syntax.mllb_name
                                  fn_sig in
                              (uu___4, uu___5)))
                | uu___2 ->
                    (match lb.FStarC_Extraction_ML_Syntax.mllb_tysc with
                     | FStar_Pervasives_Native.Some ([], ty) ->
                         let name = lb.FStarC_Extraction_ML_Syntax.mllb_name in
                         let ty1 = extract_mlty g ty in
                         let uu___3 =
                           let uu___4 =
                             extract_mlexpr g
                               lb.FStarC_Extraction_ML_Syntax.mllb_def in
                           Pulse2Rust_Rust_Syntax.mk_item_static name ty1
                             uu___4 in
                         let uu___4 = Pulse2Rust_Env.push_static g name ty1 in
                         (uu___3, uu___4)
                     | uu___3 ->
                         let uu___4 =
                           let uu___5 =
                             FStarC_Extraction_ML_Syntax.mlexpr_to_string
                               lb.FStarC_Extraction_ML_Syntax.mllb_def in
                           FStarC_Compiler_Util.format1
                             "top level lb def with either no tysc or generics %s"
                             uu___5 in
                         Pulse2Rust_Env.fail_nyi uu___4)))
let (has_rust_derive_attr :
  FStarC_Extraction_ML_Syntax.mlattribute Prims.list ->
    Pulse2Rust_Rust_Syntax.attribute FStar_Pervasives_Native.option)
  =
  fun attrs ->
    let uu___ =
      FStarC_Compiler_List.tryFind
        (fun attr ->
           match attr.FStarC_Extraction_ML_Syntax.expr with
           | FStarC_Extraction_ML_Syntax.MLE_CTor (p, uu___1) when
               let uu___2 = FStarC_Extraction_ML_Syntax.string_of_mlpath p in
               uu___2 = "Pulse.Lib.Pervasives.Rust_derive" -> true
           | uu___1 -> false) attrs in
    FStarC_Compiler_Util.map_option
      (fun attr ->
         let uu___1 = attr.FStarC_Extraction_ML_Syntax.expr in
         match uu___1 with
         | FStarC_Extraction_ML_Syntax.MLE_CTor (p, arg::uu___2) ->
             let uu___3 = arg.FStarC_Extraction_ML_Syntax.expr in
             (match uu___3 with
              | FStarC_Extraction_ML_Syntax.MLE_Const
                  (FStarC_Extraction_ML_Syntax.MLC_String s) ->
                  Pulse2Rust_Rust_Syntax.mk_derive_attr s)) uu___
let (extract_struct_defn :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlattribute Prims.list ->
      FStarC_Extraction_ML_Syntax.one_mltydecl ->
        (Pulse2Rust_Rust_Syntax.item * Pulse2Rust_Env.env))
  =
  fun g ->
    fun attrs ->
      fun d ->
        let uu___ = d.FStarC_Extraction_ML_Syntax.tydecl_defn in
        match uu___ with
        | FStar_Pervasives_Native.Some
            (FStarC_Extraction_ML_Syntax.MLTD_Record fts) ->
            let uu___1 =
              let uu___2 =
                let uu___3 =
                  let uu___4 = has_rust_derive_attr attrs in
                  FStarC_Compiler_Util.map_option (fun a -> [a]) uu___4 in
                FStarC_Compiler_Util.dflt [] uu___3 in
              let uu___3 =
                enum_or_struct_name d.FStarC_Extraction_ML_Syntax.tydecl_name in
              let uu___4 =
                extract_generic_type_params
                  d.FStarC_Extraction_ML_Syntax.tydecl_parameters in
              let uu___5 =
                FStarC_Compiler_List.map
                  (fun uu___6 ->
                     match uu___6 with
                     | (f, t) -> let uu___7 = extract_mlty g t in (f, uu___7))
                  fts in
              Pulse2Rust_Rust_Syntax.mk_item_struct uu___2 uu___3 uu___4
                uu___5 in
            (uu___1, g)
let (extract_type_abbrev :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlattribute Prims.list ->
      FStarC_Extraction_ML_Syntax.one_mltydecl ->
        (Pulse2Rust_Rust_Syntax.item * Pulse2Rust_Env.env))
  =
  fun g ->
    fun attrs ->
      fun d ->
        let uu___ = d.FStarC_Extraction_ML_Syntax.tydecl_defn in
        match uu___ with
        | FStar_Pervasives_Native.Some
            (FStarC_Extraction_ML_Syntax.MLTD_Abbrev t) ->
            let uu___1 =
              let uu___2 =
                extract_generic_type_params
                  d.FStarC_Extraction_ML_Syntax.tydecl_parameters in
              let uu___3 = extract_mlty g t in
              Pulse2Rust_Rust_Syntax.mk_item_type
                d.FStarC_Extraction_ML_Syntax.tydecl_name uu___2 uu___3 in
            (uu___1, g)
let (extract_enum :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlattribute Prims.list ->
      FStarC_Extraction_ML_Syntax.one_mltydecl ->
        (Pulse2Rust_Rust_Syntax.item * Pulse2Rust_Env.env))
  =
  fun g ->
    fun attrs ->
      fun d ->
        let uu___ = d.FStarC_Extraction_ML_Syntax.tydecl_defn in
        match uu___ with
        | FStar_Pervasives_Native.Some
            (FStarC_Extraction_ML_Syntax.MLTD_DType cts) ->
            let uu___1 =
              let uu___2 =
                let uu___3 =
                  let uu___4 = has_rust_derive_attr attrs in
                  FStarC_Compiler_Util.map_option (fun a -> [a]) uu___4 in
                FStarC_Compiler_Util.dflt [] uu___3 in
              let uu___3 =
                enum_or_struct_name d.FStarC_Extraction_ML_Syntax.tydecl_name in
              let uu___4 =
                extract_generic_type_params
                  d.FStarC_Extraction_ML_Syntax.tydecl_parameters in
              let uu___5 =
                FStarC_Compiler_List.map
                  (fun uu___6 ->
                     match uu___6 with
                     | (cname, dts) ->
                         let uu___7 =
                           FStarC_Compiler_List.map
                             (fun uu___8 ->
                                match uu___8 with
                                | (uu___9, t) -> extract_mlty g t) dts in
                         (cname, uu___7)) cts in
              Pulse2Rust_Rust_Syntax.mk_item_enum uu___2 uu___3 uu___4 uu___5 in
            (uu___1, g)
let (extract_mltydecl :
  Pulse2Rust_Env.env ->
    FStarC_Extraction_ML_Syntax.mlexpr Prims.list ->
      FStarC_Extraction_ML_Syntax.mltydecl ->
        (Pulse2Rust_Rust_Syntax.item Prims.list * Pulse2Rust_Env.env))
  =
  fun g ->
    fun mlattrs ->
      fun d ->
        FStarC_Compiler_List.fold_left
          (fun uu___ ->
             fun d1 ->
               match uu___ with
               | (items, g1) ->
                   let f =
                     match d1.FStarC_Extraction_ML_Syntax.tydecl_defn with
                     | FStar_Pervasives_Native.Some
                         (FStarC_Extraction_ML_Syntax.MLTD_Abbrev uu___1) ->
                         extract_type_abbrev
                     | FStar_Pervasives_Native.Some
                         (FStarC_Extraction_ML_Syntax.MLTD_Record uu___1) ->
                         extract_struct_defn
                     | FStar_Pervasives_Native.Some
                         (FStarC_Extraction_ML_Syntax.MLTD_DType uu___1) ->
                         extract_enum
                     | uu___1 ->
                         let uu___2 =
                           let uu___3 =
                             FStarC_Extraction_ML_Syntax.one_mltydecl_to_string
                               d1 in
                           FStarC_Compiler_Util.format1 "mltydecl %s" uu___3 in
                         Pulse2Rust_Env.fail_nyi uu___2 in
                   let uu___1 = f g1 mlattrs d1 in
                   (match uu___1 with
                    | (item, g2) ->
                        ((FStarC_Compiler_List.op_At items [item]), g2)))
          ([], g) d