open Prims
let (freevars :
  Pulse_Syntax_Base.term -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun t -> FStar_Reflection_Typing.freevars t
let (freevars_st_comp :
  Pulse_Syntax_Base.st_comp -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun s ->
    FStar_Set.union
      (FStar_Set.union (freevars s.Pulse_Syntax_Base.res)
         (freevars s.Pulse_Syntax_Base.pre))
      (freevars s.Pulse_Syntax_Base.post)
let (freevars_comp :
  Pulse_Syntax_Base.comp -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun c ->
    match c with
    | Pulse_Syntax_Base.C_Tot t -> freevars t
    | Pulse_Syntax_Base.C_ST s -> freevars_st_comp s
    | Pulse_Syntax_Base.C_STGhost (inames, s) ->
        FStar_Set.union (freevars inames) (freevars_st_comp s)
    | Pulse_Syntax_Base.C_STAtomic (inames, uu___, s) ->
        FStar_Set.union (freevars inames) (freevars_st_comp s)
let freevars_opt :
  'a .
    ('a -> Pulse_Syntax_Base.var FStar_Set.set) ->
      'a FStar_Pervasives_Native.option ->
        Pulse_Syntax_Base.var FStar_Set.set
  =
  fun f ->
    fun x ->
      match x with
      | FStar_Pervasives_Native.None -> FStar_Set.empty ()
      | FStar_Pervasives_Native.Some x1 -> f x1
let (freevars_term_opt :
  Pulse_Syntax_Base.term FStar_Pervasives_Native.option ->
    Pulse_Syntax_Base.var FStar_Set.set)
  = fun t -> freevars_opt freevars t
let rec (freevars_list :
  Pulse_Syntax_Base.term Prims.list -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun t ->
    match t with
    | [] -> FStar_Set.empty ()
    | hd::tl -> FStar_Set.union (freevars hd) (freevars_list tl)
let rec (freevars_pairs :
  (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list ->
    Pulse_Syntax_Base.var FStar_Set.set)
  =
  fun pairs ->
    match pairs with
    | [] -> FStar_Set.empty ()
    | (t1, t2)::tl ->
        FStar_Set.union (FStar_Set.union (freevars t1) (freevars t2))
          (freevars_pairs tl)
let (freevars_proof_hint :
  Pulse_Syntax_Base.proof_hint_type -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun ht ->
    match ht with
    | Pulse_Syntax_Base.ASSERT { Pulse_Syntax_Base.p = p;_} -> freevars p
    | Pulse_Syntax_Base.FOLD
        { Pulse_Syntax_Base.names = uu___; Pulse_Syntax_Base.p1 = p;_} ->
        freevars p
    | Pulse_Syntax_Base.UNFOLD
        { Pulse_Syntax_Base.names1 = uu___; Pulse_Syntax_Base.p2 = p;_} ->
        freevars p
    | Pulse_Syntax_Base.RENAME
        { Pulse_Syntax_Base.pairs = pairs; Pulse_Syntax_Base.goal = goal;
          Pulse_Syntax_Base.tac_opt = tac_opt;_}
        ->
        FStar_Set.union
          (FStar_Set.union (freevars_pairs pairs) (freevars_term_opt goal))
          (freevars_term_opt tac_opt)
    | Pulse_Syntax_Base.REWRITE
        { Pulse_Syntax_Base.t1 = t1; Pulse_Syntax_Base.t2 = t2;
          Pulse_Syntax_Base.tac_opt1 = tac_opt;_}
        ->
        FStar_Set.union (FStar_Set.union (freevars t1) (freevars t2))
          (freevars_term_opt tac_opt)
    | Pulse_Syntax_Base.WILD -> FStar_Set.empty ()
    | Pulse_Syntax_Base.SHOW_PROOF_STATE uu___ -> FStar_Set.empty ()
let (freevars_ascription :
  Pulse_Syntax_Base.comp_ascription -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun c ->
    FStar_Set.union
      (freevars_opt freevars_comp c.Pulse_Syntax_Base.elaborated)
      (freevars_opt freevars_comp c.Pulse_Syntax_Base.annotated)
let rec (freevars_st :
  Pulse_Syntax_Base.st_term -> Pulse_Syntax_Base.var FStar_Set.set) =
  fun t ->
    match t.Pulse_Syntax_Base.term1 with
    | Pulse_Syntax_Base.Tm_Return
        { Pulse_Syntax_Base.expected_type = expected_type;
          Pulse_Syntax_Base.insert_eq = uu___;
          Pulse_Syntax_Base.term = term;_}
        -> FStar_Set.union (freevars expected_type) (freevars term)
    | Pulse_Syntax_Base.Tm_Abs
        { Pulse_Syntax_Base.b = b; Pulse_Syntax_Base.q = uu___;
          Pulse_Syntax_Base.ascription = ascription;
          Pulse_Syntax_Base.body = body;_}
        ->
        FStar_Set.union (freevars b.Pulse_Syntax_Base.binder_ty)
          (FStar_Set.union (freevars_st body)
             (freevars_ascription ascription))
    | Pulse_Syntax_Base.Tm_STApp
        { Pulse_Syntax_Base.head = head; Pulse_Syntax_Base.arg_qual = uu___;
          Pulse_Syntax_Base.arg = arg;_}
        -> FStar_Set.union (freevars head) (freevars arg)
    | Pulse_Syntax_Base.Tm_Bind
        { Pulse_Syntax_Base.binder = binder; Pulse_Syntax_Base.head1 = head;
          Pulse_Syntax_Base.body1 = body;_}
        ->
        FStar_Set.union
          (FStar_Set.union (freevars binder.Pulse_Syntax_Base.binder_ty)
             (freevars_st head)) (freevars_st body)
    | Pulse_Syntax_Base.Tm_TotBind
        { Pulse_Syntax_Base.binder1 = binder; Pulse_Syntax_Base.head2 = head;
          Pulse_Syntax_Base.body2 = body;_}
        ->
        FStar_Set.union
          (FStar_Set.union (freevars binder.Pulse_Syntax_Base.binder_ty)
             (freevars head)) (freevars_st body)
    | Pulse_Syntax_Base.Tm_If
        { Pulse_Syntax_Base.b1 = b; Pulse_Syntax_Base.then_ = then_;
          Pulse_Syntax_Base.else_ = else_; Pulse_Syntax_Base.post1 = post;_}
        ->
        FStar_Set.union (FStar_Set.union (freevars b) (freevars_st then_))
          (FStar_Set.union (freevars_st else_) (freevars_term_opt post))
    | Pulse_Syntax_Base.Tm_Match
        { Pulse_Syntax_Base.sc = sc; Pulse_Syntax_Base.returns_ = returns_;
          Pulse_Syntax_Base.brs = brs;_}
        ->
        let op_At_At = FStar_Set.union in
        op_At_At (freevars sc)
          (op_At_At (freevars_term_opt returns_) (freevars_branches brs))
    | Pulse_Syntax_Base.Tm_IntroPure { Pulse_Syntax_Base.p3 = p;_} ->
        freevars p
    | Pulse_Syntax_Base.Tm_ElimExists { Pulse_Syntax_Base.p4 = p;_} ->
        freevars p
    | Pulse_Syntax_Base.Tm_IntroExists
        { Pulse_Syntax_Base.p5 = p;
          Pulse_Syntax_Base.witnesses = witnesses;_}
        -> FStar_Set.union (freevars p) (freevars_list witnesses)
    | Pulse_Syntax_Base.Tm_While
        { Pulse_Syntax_Base.invariant = invariant;
          Pulse_Syntax_Base.condition = condition;
          Pulse_Syntax_Base.condition_var = uu___;
          Pulse_Syntax_Base.body3 = body;_}
        ->
        FStar_Set.union (freevars invariant)
          (FStar_Set.union (freevars_st condition) (freevars_st body))
    | Pulse_Syntax_Base.Tm_Par
        { Pulse_Syntax_Base.pre1 = pre1; Pulse_Syntax_Base.body11 = body1;
          Pulse_Syntax_Base.post11 = post1; Pulse_Syntax_Base.pre2 = pre2;
          Pulse_Syntax_Base.body21 = body2;
          Pulse_Syntax_Base.post2 = post2;_}
        ->
        FStar_Set.union
          (FStar_Set.union (freevars pre1)
             (FStar_Set.union (freevars_st body1) (freevars post1)))
          (FStar_Set.union (freevars pre2)
             (FStar_Set.union (freevars_st body2) (freevars post2)))
    | Pulse_Syntax_Base.Tm_WithLocal
        { Pulse_Syntax_Base.binder2 = binder;
          Pulse_Syntax_Base.initializer1 = initializer1;
          Pulse_Syntax_Base.body4 = body;_}
        ->
        FStar_Set.union (freevars binder.Pulse_Syntax_Base.binder_ty)
          (FStar_Set.union (freevars initializer1) (freevars_st body))
    | Pulse_Syntax_Base.Tm_WithLocalArray
        { Pulse_Syntax_Base.binder3 = binder;
          Pulse_Syntax_Base.initializer2 = initializer1;
          Pulse_Syntax_Base.length = length;
          Pulse_Syntax_Base.body5 = body;_}
        ->
        FStar_Set.union (freevars binder.Pulse_Syntax_Base.binder_ty)
          (FStar_Set.union (freevars initializer1)
             (FStar_Set.union (freevars length) (freevars_st body)))
    | Pulse_Syntax_Base.Tm_Rewrite
        { Pulse_Syntax_Base.t11 = t1; Pulse_Syntax_Base.t21 = t2;
          Pulse_Syntax_Base.tac_opt2 = tac_opt;_}
        ->
        FStar_Set.union (FStar_Set.union (freevars t1) (freevars t2))
          (freevars_term_opt tac_opt)
    | Pulse_Syntax_Base.Tm_Admit
        { Pulse_Syntax_Base.ctag = uu___; Pulse_Syntax_Base.u1 = uu___1;
          Pulse_Syntax_Base.typ = typ; Pulse_Syntax_Base.post3 = post;_}
        -> FStar_Set.union (freevars typ) (freevars_term_opt post)
    | Pulse_Syntax_Base.Tm_Unreachable { Pulse_Syntax_Base.c = c;_} ->
        freevars_comp c
    | Pulse_Syntax_Base.Tm_ProofHintWithBinders
        { Pulse_Syntax_Base.hint_type = hint_type;
          Pulse_Syntax_Base.binders = binders; Pulse_Syntax_Base.t = t1;_}
        -> FStar_Set.union (freevars_proof_hint hint_type) (freevars_st t1)
    | Pulse_Syntax_Base.Tm_WithInv
        { Pulse_Syntax_Base.name1 = name; Pulse_Syntax_Base.body6 = body;
          Pulse_Syntax_Base.returns_inv = returns_inv;_}
        ->
        FStar_Set.union (FStar_Set.union (freevars name) (freevars_st body))
          (freevars_opt
             (fun uu___ ->
                match uu___ with
                | (b, r, is) ->
                    FStar_Set.union (freevars b.Pulse_Syntax_Base.binder_ty)
                      (FStar_Set.union (freevars r) (freevars is)))
             returns_inv)
and (freevars_branches :
  (Pulse_Syntax_Base.pattern * Pulse_Syntax_Base.st_term) Prims.list ->
    Pulse_Syntax_Base.var FStar_Set.set)
  =
  fun t ->
    match t with
    | [] -> FStar_Set.empty ()
    | (uu___, b)::tl ->
        FStar_Set.union (freevars_st b) (freevars_branches tl)
let (ln' : Pulse_Syntax_Base.term -> Prims.int -> Prims.bool) =
  fun t -> fun i -> FStar_Reflection_Typing.ln' t i
let (ln_st_comp : Pulse_Syntax_Base.st_comp -> Prims.int -> Prims.bool) =
  fun s ->
    fun i ->
      ((ln' s.Pulse_Syntax_Base.res i) && (ln' s.Pulse_Syntax_Base.pre i)) &&
        (ln' s.Pulse_Syntax_Base.post (i + Prims.int_one))
let (ln_c' : Pulse_Syntax_Base.comp -> Prims.int -> Prims.bool) =
  fun c ->
    fun i ->
      match c with
      | Pulse_Syntax_Base.C_Tot t -> ln' t i
      | Pulse_Syntax_Base.C_ST s -> ln_st_comp s i
      | Pulse_Syntax_Base.C_STGhost (inames, s) ->
          (ln' inames i) && (ln_st_comp s i)
      | Pulse_Syntax_Base.C_STAtomic (inames, uu___, s) ->
          (ln' inames i) && (ln_st_comp s i)
let ln_opt' :
  'a .
    ('a -> Prims.int -> Prims.bool) ->
      'a FStar_Pervasives_Native.option -> Prims.int -> Prims.bool
  =
  fun f ->
    fun t ->
      fun i ->
        match t with
        | FStar_Pervasives_Native.None -> true
        | FStar_Pervasives_Native.Some t1 -> f t1 i
let rec (ln_list' :
  Pulse_Syntax_Base.term Prims.list -> Prims.int -> Prims.bool) =
  fun t ->
    fun i ->
      match t with | [] -> true | hd::tl -> (ln' hd i) && (ln_list' tl i)
let rec (ln_terms' :
  (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list ->
    Prims.int -> Prims.bool)
  =
  fun t ->
    fun i ->
      match t with
      | [] -> true
      | (t1, t2)::tl -> ((ln' t1 i) && (ln' t2 i)) && (ln_terms' tl i)
let (ln_proof_hint' :
  Pulse_Syntax_Base.proof_hint_type -> Prims.int -> Prims.bool) =
  fun ht ->
    fun i ->
      match ht with
      | Pulse_Syntax_Base.ASSERT { Pulse_Syntax_Base.p = p;_} -> ln' p i
      | Pulse_Syntax_Base.UNFOLD
          { Pulse_Syntax_Base.names1 = uu___; Pulse_Syntax_Base.p2 = p;_} ->
          ln' p i
      | Pulse_Syntax_Base.FOLD
          { Pulse_Syntax_Base.names = uu___; Pulse_Syntax_Base.p1 = p;_} ->
          ln' p i
      | Pulse_Syntax_Base.RENAME
          { Pulse_Syntax_Base.pairs = pairs; Pulse_Syntax_Base.goal = goal;
            Pulse_Syntax_Base.tac_opt = uu___;_}
          -> (ln_terms' pairs i) && (ln_opt' ln' goal i)
      | Pulse_Syntax_Base.REWRITE
          { Pulse_Syntax_Base.t1 = t1; Pulse_Syntax_Base.t2 = t2;
            Pulse_Syntax_Base.tac_opt1 = uu___;_}
          -> (ln' t1 i) && (ln' t2 i)
      | Pulse_Syntax_Base.WILD -> true
      | Pulse_Syntax_Base.SHOW_PROOF_STATE uu___ -> true
let rec (pattern_shift_n : Pulse_Syntax_Base.pattern -> Prims.nat) =
  fun p ->
    match p with
    | Pulse_Syntax_Base.Pat_Constant uu___ -> Prims.int_zero
    | Pulse_Syntax_Base.Pat_Dot_Term uu___ -> Prims.int_zero
    | Pulse_Syntax_Base.Pat_Var (uu___, uu___1) -> Prims.int_one
    | Pulse_Syntax_Base.Pat_Cons (fv, l) -> pattern_args_shift_n l
and (pattern_args_shift_n :
  (Pulse_Syntax_Base.pattern * Prims.bool) Prims.list -> Prims.nat) =
  fun ps ->
    match ps with
    | [] -> Prims.int_zero
    | (p, uu___)::tl -> (pattern_shift_n p) + (pattern_args_shift_n tl)
let rec (ln_pattern' : Pulse_Syntax_Base.pattern -> Prims.int -> Prims.bool)
  =
  fun p ->
    fun i ->
      match p with
      | Pulse_Syntax_Base.Pat_Constant uu___ -> true
      | Pulse_Syntax_Base.Pat_Var (uu___, uu___1) -> true
      | Pulse_Syntax_Base.Pat_Dot_Term (FStar_Pervasives_Native.None) -> true
      | Pulse_Syntax_Base.Pat_Dot_Term (FStar_Pervasives_Native.Some e) ->
          ln' e i
      | Pulse_Syntax_Base.Pat_Cons (fv, l) -> ln_pattern_args' l i
and (ln_pattern_args' :
  (Pulse_Syntax_Base.pattern * Prims.bool) Prims.list ->
    Prims.int -> Prims.bool)
  =
  fun p ->
    fun i ->
      match p with
      | [] -> true
      | (p1, uu___)::tl ->
          (ln_pattern' p1 i) &&
            (ln_pattern_args' tl (i + (pattern_shift_n p1)))
let (ln_ascription' :
  Pulse_Syntax_Base.comp_ascription -> Prims.int -> Prims.bool) =
  fun c ->
    fun i ->
      (ln_opt' ln_c' c.Pulse_Syntax_Base.elaborated i) &&
        (ln_opt' ln_c' c.Pulse_Syntax_Base.annotated i)
let rec (ln_st' : Pulse_Syntax_Base.st_term -> Prims.int -> Prims.bool) =
  fun t ->
    fun i ->
      match t.Pulse_Syntax_Base.term1 with
      | Pulse_Syntax_Base.Tm_Return
          { Pulse_Syntax_Base.expected_type = expected_type;
            Pulse_Syntax_Base.insert_eq = uu___;
            Pulse_Syntax_Base.term = term;_}
          -> (ln' expected_type i) && (ln' term i)
      | Pulse_Syntax_Base.Tm_Abs
          { Pulse_Syntax_Base.b = b; Pulse_Syntax_Base.q = uu___;
            Pulse_Syntax_Base.ascription = ascription;
            Pulse_Syntax_Base.body = body;_}
          ->
          ((ln' b.Pulse_Syntax_Base.binder_ty i) &&
             (ln_st' body (i + Prims.int_one)))
            && (ln_ascription' ascription (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_STApp
          { Pulse_Syntax_Base.head = head;
            Pulse_Syntax_Base.arg_qual = uu___;
            Pulse_Syntax_Base.arg = arg;_}
          -> (ln' head i) && (ln' arg i)
      | Pulse_Syntax_Base.Tm_Bind
          { Pulse_Syntax_Base.binder = binder;
            Pulse_Syntax_Base.head1 = head; Pulse_Syntax_Base.body1 = body;_}
          ->
          ((ln' binder.Pulse_Syntax_Base.binder_ty i) && (ln_st' head i)) &&
            (ln_st' body (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_TotBind
          { Pulse_Syntax_Base.binder1 = binder;
            Pulse_Syntax_Base.head2 = head; Pulse_Syntax_Base.body2 = body;_}
          ->
          ((ln' binder.Pulse_Syntax_Base.binder_ty i) && (ln' head i)) &&
            (ln_st' body (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_If
          { Pulse_Syntax_Base.b1 = b; Pulse_Syntax_Base.then_ = then_;
            Pulse_Syntax_Base.else_ = else_;
            Pulse_Syntax_Base.post1 = post;_}
          ->
          (((ln' b i) && (ln_st' then_ i)) && (ln_st' else_ i)) &&
            (ln_opt' ln' post (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_Match
          { Pulse_Syntax_Base.sc = sc; Pulse_Syntax_Base.returns_ = returns_;
            Pulse_Syntax_Base.brs = brs;_}
          ->
          ((ln' sc i) && (ln_opt' ln' returns_ i)) && (ln_branches' t brs i)
      | Pulse_Syntax_Base.Tm_IntroPure { Pulse_Syntax_Base.p3 = p;_} ->
          ln' p i
      | Pulse_Syntax_Base.Tm_ElimExists { Pulse_Syntax_Base.p4 = p;_} ->
          ln' p i
      | Pulse_Syntax_Base.Tm_IntroExists
          { Pulse_Syntax_Base.p5 = p;
            Pulse_Syntax_Base.witnesses = witnesses;_}
          -> (ln' p i) && (ln_list' witnesses i)
      | Pulse_Syntax_Base.Tm_While
          { Pulse_Syntax_Base.invariant = invariant;
            Pulse_Syntax_Base.condition = condition;
            Pulse_Syntax_Base.condition_var = uu___;
            Pulse_Syntax_Base.body3 = body;_}
          ->
          ((ln' invariant (i + Prims.int_one)) && (ln_st' condition i)) &&
            (ln_st' body i)
      | Pulse_Syntax_Base.Tm_Par
          { Pulse_Syntax_Base.pre1 = pre1; Pulse_Syntax_Base.body11 = body1;
            Pulse_Syntax_Base.post11 = post1; Pulse_Syntax_Base.pre2 = pre2;
            Pulse_Syntax_Base.body21 = body2;
            Pulse_Syntax_Base.post2 = post2;_}
          ->
          (((((ln' pre1 i) && (ln_st' body1 i)) &&
               (ln' post1 (i + Prims.int_one)))
              && (ln' pre2 i))
             && (ln_st' body2 i))
            && (ln' post2 (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_WithLocal
          { Pulse_Syntax_Base.binder2 = binder;
            Pulse_Syntax_Base.initializer1 = initializer1;
            Pulse_Syntax_Base.body4 = body;_}
          ->
          ((ln' binder.Pulse_Syntax_Base.binder_ty i) && (ln' initializer1 i))
            && (ln_st' body (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_WithLocalArray
          { Pulse_Syntax_Base.binder3 = binder;
            Pulse_Syntax_Base.initializer2 = initializer1;
            Pulse_Syntax_Base.length = length;
            Pulse_Syntax_Base.body5 = body;_}
          ->
          (((ln' binder.Pulse_Syntax_Base.binder_ty i) &&
              (ln' initializer1 i))
             && (ln' length i))
            && (ln_st' body (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_Rewrite
          { Pulse_Syntax_Base.t11 = t1; Pulse_Syntax_Base.t21 = t2;
            Pulse_Syntax_Base.tac_opt2 = uu___;_}
          -> (ln' t1 i) && (ln' t2 i)
      | Pulse_Syntax_Base.Tm_Admit
          { Pulse_Syntax_Base.ctag = uu___; Pulse_Syntax_Base.u1 = uu___1;
            Pulse_Syntax_Base.typ = typ; Pulse_Syntax_Base.post3 = post;_}
          -> (ln' typ i) && (ln_opt' ln' post (i + Prims.int_one))
      | Pulse_Syntax_Base.Tm_Unreachable { Pulse_Syntax_Base.c = c;_} ->
          ln_c' c i
      | Pulse_Syntax_Base.Tm_ProofHintWithBinders
          { Pulse_Syntax_Base.hint_type = hint_type;
            Pulse_Syntax_Base.binders = binders; Pulse_Syntax_Base.t = t1;_}
          ->
          let n = FStar_List_Tot_Base.length binders in
          (ln_proof_hint' hint_type (i + n)) && (ln_st' t1 (i + n))
      | Pulse_Syntax_Base.Tm_WithInv
          { Pulse_Syntax_Base.name1 = name; Pulse_Syntax_Base.body6 = body;
            Pulse_Syntax_Base.returns_inv = returns_inv;_}
          ->
          ((ln' name i) && (ln_st' body i)) &&
            (ln_opt'
               (fun uu___ ->
                  fun i1 ->
                    match uu___ with
                    | (b, r, is) ->
                        ((ln' b.Pulse_Syntax_Base.binder_ty i1) &&
                           (ln' r (i1 + Prims.int_one)))
                          && (ln' is i1)) returns_inv i)
and (ln_branch' :
  (Pulse_Syntax_Base.pattern * Pulse_Syntax_Base.st_term) ->
    Prims.int -> Prims.bool)
  =
  fun b ->
    fun i ->
      let uu___ = b in
      match uu___ with
      | (p, e) -> (ln_pattern' p i) && (ln_st' e (i + (pattern_shift_n p)))
and (ln_branches' :
  Pulse_Syntax_Base.st_term ->
    Pulse_Syntax_Base.branch Prims.list -> Prims.int -> Prims.bool)
  =
  fun t ->
    fun brs ->
      fun i -> Pulse_Common.for_all_dec t brs (fun b -> ln_branch' b i)
let (ln : Pulse_Syntax_Base.term -> Prims.bool) =
  fun t -> ln' t (Prims.of_int (-1))
let (ln_st : Pulse_Syntax_Base.st_term -> Prims.bool) =
  fun t -> ln_st' t (Prims.of_int (-1))
let (ln_c : Pulse_Syntax_Base.comp -> Prims.bool) =
  fun c -> ln_c' c (Prims.of_int (-1))
type subst_elt = FStar_Reflection_Typing.subst_elt
let (shift_subst_elt :
  Prims.nat ->
    FStar_Reflection_Typing.subst_elt -> FStar_Reflection_Typing.subst_elt)
  = FStar_Reflection_Typing.shift_subst_elt
type subst = FStar_Reflection_Typing.subst
let (shift_subst_n :
  Prims.nat ->
    FStar_Reflection_Typing.subst_elt Prims.list ->
      FStar_Reflection_Typing.subst_elt Prims.list)
  = fun n -> FStar_Reflection_Typing.shift_subst_n n
let (shift_subst :
  FStar_Reflection_Typing.subst_elt Prims.list ->
    FStar_Reflection_Typing.subst_elt Prims.list)
  = FStar_Reflection_Typing.shift_subst
let (r_subst_of_rt_subst_elt : subst_elt -> FStarC_Syntax_Syntax.subst_elt) =
  fun x ->
    match x with
    | FStar_Reflection_Typing.DT (i, t) ->
        (match FStarC_Reflection_V2_Builtins.inspect_ln t with
         | FStarC_Reflection_V2_Data.Tv_Var n ->
             FStarC_Syntax_Syntax.DB (i, n)
         | uu___ -> FStarC_Syntax_Syntax.DT (i, t))
    | FStar_Reflection_Typing.NT (x1, t) ->
        FStarC_Syntax_Syntax.NT
          ((FStar_Reflection_Typing.var_as_namedv x1), t)
    | FStar_Reflection_Typing.ND (x1, i) ->
        FStarC_Syntax_Syntax.NM
          ((FStar_Reflection_Typing.var_as_namedv x1), i)
let (subst_host_term' :
  Pulse_Syntax_Base.term -> subst -> FStarC_Reflection_Types.term) =
  fun t ->
    fun ss ->
      FStarC_Reflection_V2_Builtins.subst_term
        (FStar_List_Tot_Base.map r_subst_of_rt_subst_elt ss) t
let (subst_host_term :
  Pulse_Syntax_Base.term -> subst -> Pulse_Syntax_Base.term) =
  fun t -> fun ss -> let res0 = subst_host_term' t ss in res0
let (subst_term : Pulse_Syntax_Base.term -> subst -> Pulse_Syntax_Base.term)
  = fun t -> fun ss -> subst_host_term t ss
let (open_term' :
  Pulse_Syntax_Base.term ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.term)
  =
  fun t -> fun v -> fun i -> subst_term t [FStar_Reflection_Typing.DT (i, v)]
let (subst_st_comp :
  Pulse_Syntax_Base.st_comp -> subst -> Pulse_Syntax_Base.st_comp) =
  fun s ->
    fun ss ->
      {
        Pulse_Syntax_Base.u = (s.Pulse_Syntax_Base.u);
        Pulse_Syntax_Base.res = (subst_term s.Pulse_Syntax_Base.res ss);
        Pulse_Syntax_Base.pre = (subst_term s.Pulse_Syntax_Base.pre ss);
        Pulse_Syntax_Base.post =
          (subst_term s.Pulse_Syntax_Base.post (shift_subst ss))
      }
let (open_st_comp' :
  Pulse_Syntax_Base.st_comp ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.st_comp)
  =
  fun s ->
    fun v -> fun i -> subst_st_comp s [FStar_Reflection_Typing.DT (i, v)]
let (subst_comp : Pulse_Syntax_Base.comp -> subst -> Pulse_Syntax_Base.comp)
  =
  fun c ->
    fun ss ->
      match c with
      | Pulse_Syntax_Base.C_Tot t ->
          Pulse_Syntax_Base.C_Tot (subst_term t ss)
      | Pulse_Syntax_Base.C_ST s ->
          Pulse_Syntax_Base.C_ST (subst_st_comp s ss)
      | Pulse_Syntax_Base.C_STAtomic (inames, obs, s) ->
          Pulse_Syntax_Base.C_STAtomic
            ((subst_term inames ss), obs, (subst_st_comp s ss))
      | Pulse_Syntax_Base.C_STGhost (inames, s) ->
          Pulse_Syntax_Base.C_STGhost
            ((subst_term inames ss), (subst_st_comp s ss))
let (open_comp' :
  Pulse_Syntax_Base.comp ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.comp)
  =
  fun c -> fun v -> fun i -> subst_comp c [FStar_Reflection_Typing.DT (i, v)]
let (subst_term_opt :
  Pulse_Syntax_Base.term FStar_Pervasives_Native.option ->
    subst -> Pulse_Syntax_Base.term FStar_Pervasives_Native.option)
  =
  fun t ->
    fun ss ->
      match t with
      | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
      | FStar_Pervasives_Native.Some t1 ->
          FStar_Pervasives_Native.Some (subst_term t1 ss)
let (open_term_opt' :
  Pulse_Syntax_Base.term FStar_Pervasives_Native.option ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index ->
        Pulse_Syntax_Base.term FStar_Pervasives_Native.option)
  =
  fun t ->
    fun v -> fun i -> subst_term_opt t [FStar_Reflection_Typing.DT (i, v)]
let rec (subst_term_list :
  Pulse_Syntax_Base.term Prims.list ->
    subst -> Pulse_Syntax_Base.term Prims.list)
  =
  fun t ->
    fun ss ->
      match t with
      | [] -> []
      | hd::tl -> (subst_term hd ss) :: (subst_term_list tl ss)
let (open_term_list' :
  Pulse_Syntax_Base.term Prims.list ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.term Prims.list)
  =
  fun t ->
    fun v -> fun i -> subst_term_list t [FStar_Reflection_Typing.DT (i, v)]
let (subst_binder :
  Pulse_Syntax_Base.binder -> subst -> Pulse_Syntax_Base.binder) =
  fun b ->
    fun ss ->
      {
        Pulse_Syntax_Base.binder_ty =
          (subst_term b.Pulse_Syntax_Base.binder_ty ss);
        Pulse_Syntax_Base.binder_ppname = (b.Pulse_Syntax_Base.binder_ppname);
        Pulse_Syntax_Base.binder_attrs = (b.Pulse_Syntax_Base.binder_attrs)
      }
let (open_binder :
  Pulse_Syntax_Base.binder ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.binder)
  =
  fun b ->
    fun v ->
      fun i ->
        {
          Pulse_Syntax_Base.binder_ty =
            (open_term' b.Pulse_Syntax_Base.binder_ty v i);
          Pulse_Syntax_Base.binder_ppname =
            (b.Pulse_Syntax_Base.binder_ppname);
          Pulse_Syntax_Base.binder_attrs = (b.Pulse_Syntax_Base.binder_attrs)
        }
let rec (subst_term_pairs :
  (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list ->
    subst -> (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list)
  =
  fun t ->
    fun ss ->
      match t with
      | [] -> []
      | (t1, t2)::tl -> ((subst_term t1 ss), (subst_term t2 ss)) ::
          (subst_term_pairs tl ss)
let (subst_proof_hint :
  Pulse_Syntax_Base.proof_hint_type ->
    subst -> Pulse_Syntax_Base.proof_hint_type)
  =
  fun ht ->
    fun ss ->
      match ht with
      | Pulse_Syntax_Base.ASSERT { Pulse_Syntax_Base.p = p;_} ->
          Pulse_Syntax_Base.ASSERT
            { Pulse_Syntax_Base.p = (subst_term p ss) }
      | Pulse_Syntax_Base.UNFOLD
          { Pulse_Syntax_Base.names1 = names; Pulse_Syntax_Base.p2 = p;_} ->
          Pulse_Syntax_Base.UNFOLD
            {
              Pulse_Syntax_Base.names1 = names;
              Pulse_Syntax_Base.p2 = (subst_term p ss)
            }
      | Pulse_Syntax_Base.FOLD
          { Pulse_Syntax_Base.names = names; Pulse_Syntax_Base.p1 = p;_} ->
          Pulse_Syntax_Base.FOLD
            {
              Pulse_Syntax_Base.names = names;
              Pulse_Syntax_Base.p1 = (subst_term p ss)
            }
      | Pulse_Syntax_Base.RENAME
          { Pulse_Syntax_Base.pairs = pairs; Pulse_Syntax_Base.goal = goal;
            Pulse_Syntax_Base.tac_opt = tac_opt;_}
          ->
          Pulse_Syntax_Base.RENAME
            {
              Pulse_Syntax_Base.pairs = (subst_term_pairs pairs ss);
              Pulse_Syntax_Base.goal = (subst_term_opt goal ss);
              Pulse_Syntax_Base.tac_opt = (subst_term_opt tac_opt ss)
            }
      | Pulse_Syntax_Base.REWRITE
          { Pulse_Syntax_Base.t1 = t1; Pulse_Syntax_Base.t2 = t2;
            Pulse_Syntax_Base.tac_opt1 = tac_opt;_}
          ->
          Pulse_Syntax_Base.REWRITE
            {
              Pulse_Syntax_Base.t1 = (subst_term t1 ss);
              Pulse_Syntax_Base.t2 = (subst_term t2 ss);
              Pulse_Syntax_Base.tac_opt1 = (subst_term_opt tac_opt ss)
            }
      | Pulse_Syntax_Base.WILD -> ht
      | Pulse_Syntax_Base.SHOW_PROOF_STATE uu___ -> ht
let (open_term_pairs' :
  (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index ->
        (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list)
  =
  fun t ->
    fun v -> fun i -> subst_term_pairs t [FStar_Reflection_Typing.DT (i, v)]
let (close_term_pairs' :
  (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index ->
        (Pulse_Syntax_Base.term * Pulse_Syntax_Base.term) Prims.list)
  =
  fun t ->
    fun x -> fun i -> subst_term_pairs t [FStar_Reflection_Typing.ND (x, i)]
let (open_proof_hint' :
  Pulse_Syntax_Base.proof_hint_type ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.proof_hint_type)
  =
  fun ht ->
    fun v -> fun i -> subst_proof_hint ht [FStar_Reflection_Typing.DT (i, v)]
let (close_proof_hint' :
  Pulse_Syntax_Base.proof_hint_type ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.proof_hint_type)
  =
  fun ht ->
    fun x -> fun i -> subst_proof_hint ht [FStar_Reflection_Typing.ND (x, i)]
let rec (subst_pat :
  Pulse_Syntax_Base.pattern -> subst -> Pulse_Syntax_Base.pattern) =
  fun p ->
    fun ss ->
      match p with
      | Pulse_Syntax_Base.Pat_Constant uu___ -> p
      | Pulse_Syntax_Base.Pat_Dot_Term (FStar_Pervasives_Native.None) -> p
      | Pulse_Syntax_Base.Pat_Var (n, t) ->
          let t1 =
            Pulse_RuntimeUtils.map_seal t
              (fun t2 -> FStar_Reflection_Typing.subst_term t2 ss) in
          Pulse_Syntax_Base.Pat_Var (n, t1)
      | Pulse_Syntax_Base.Pat_Dot_Term (FStar_Pervasives_Native.Some e) ->
          Pulse_Syntax_Base.Pat_Dot_Term
            (FStar_Pervasives_Native.Some (subst_term e ss))
      | Pulse_Syntax_Base.Pat_Cons (d, args) ->
          let args1 = subst_pat_args args ss in
          Pulse_Syntax_Base.Pat_Cons (d, args1)
and (subst_pat_args :
  (Pulse_Syntax_Base.pattern * Prims.bool) Prims.list ->
    subst -> (Pulse_Syntax_Base.pattern * Prims.bool) Prims.list)
  =
  fun args ->
    fun ss ->
      match args with
      | [] -> []
      | (arg, b)::tl ->
          let arg' = subst_pat arg ss in
          let tl1 =
            subst_pat_args tl (shift_subst_n (pattern_shift_n arg) ss) in
          (arg', b) :: tl1
let map2_opt :
  'a 'b 'c .
    ('a -> 'b -> 'c) ->
      'a FStar_Pervasives_Native.option ->
        'b -> 'c FStar_Pervasives_Native.option
  =
  fun f ->
    fun x ->
      fun y ->
        match x with
        | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
        | FStar_Pervasives_Native.Some x1 ->
            FStar_Pervasives_Native.Some (f x1 y)
let (subst_ascription :
  Pulse_Syntax_Base.comp_ascription ->
    subst -> Pulse_Syntax_Base.comp_ascription)
  =
  fun c ->
    fun ss ->
      {
        Pulse_Syntax_Base.annotated =
          (map2_opt subst_comp c.Pulse_Syntax_Base.annotated ss);
        Pulse_Syntax_Base.elaborated =
          (map2_opt subst_comp c.Pulse_Syntax_Base.elaborated ss)
      }
let rec (subst_st_term :
  Pulse_Syntax_Base.st_term -> subst -> Pulse_Syntax_Base.st_term) =
  fun t ->
    fun ss ->
      let t' =
        match t.Pulse_Syntax_Base.term1 with
        | Pulse_Syntax_Base.Tm_Return
            { Pulse_Syntax_Base.expected_type = expected_type;
              Pulse_Syntax_Base.insert_eq = insert_eq;
              Pulse_Syntax_Base.term = term;_}
            ->
            Pulse_Syntax_Base.Tm_Return
              {
                Pulse_Syntax_Base.expected_type =
                  (subst_term expected_type ss);
                Pulse_Syntax_Base.insert_eq = insert_eq;
                Pulse_Syntax_Base.term = (subst_term term ss)
              }
        | Pulse_Syntax_Base.Tm_Abs
            { Pulse_Syntax_Base.b = b; Pulse_Syntax_Base.q = q;
              Pulse_Syntax_Base.ascription = ascription;
              Pulse_Syntax_Base.body = body;_}
            ->
            Pulse_Syntax_Base.Tm_Abs
              {
                Pulse_Syntax_Base.b = (subst_binder b ss);
                Pulse_Syntax_Base.q = q;
                Pulse_Syntax_Base.ascription =
                  (subst_ascription ascription (shift_subst ss));
                Pulse_Syntax_Base.body =
                  (subst_st_term body (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_STApp
            { Pulse_Syntax_Base.head = head;
              Pulse_Syntax_Base.arg_qual = arg_qual;
              Pulse_Syntax_Base.arg = arg;_}
            ->
            Pulse_Syntax_Base.Tm_STApp
              {
                Pulse_Syntax_Base.head = (subst_term head ss);
                Pulse_Syntax_Base.arg_qual = arg_qual;
                Pulse_Syntax_Base.arg = (subst_term arg ss)
              }
        | Pulse_Syntax_Base.Tm_Bind
            { Pulse_Syntax_Base.binder = binder;
              Pulse_Syntax_Base.head1 = head;
              Pulse_Syntax_Base.body1 = body;_}
            ->
            Pulse_Syntax_Base.Tm_Bind
              {
                Pulse_Syntax_Base.binder = (subst_binder binder ss);
                Pulse_Syntax_Base.head1 = (subst_st_term head ss);
                Pulse_Syntax_Base.body1 =
                  (subst_st_term body (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_TotBind
            { Pulse_Syntax_Base.binder1 = binder;
              Pulse_Syntax_Base.head2 = head;
              Pulse_Syntax_Base.body2 = body;_}
            ->
            Pulse_Syntax_Base.Tm_TotBind
              {
                Pulse_Syntax_Base.binder1 = (subst_binder binder ss);
                Pulse_Syntax_Base.head2 = (subst_term head ss);
                Pulse_Syntax_Base.body2 =
                  (subst_st_term body (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_If
            { Pulse_Syntax_Base.b1 = b; Pulse_Syntax_Base.then_ = then_;
              Pulse_Syntax_Base.else_ = else_;
              Pulse_Syntax_Base.post1 = post;_}
            ->
            Pulse_Syntax_Base.Tm_If
              {
                Pulse_Syntax_Base.b1 = (subst_term b ss);
                Pulse_Syntax_Base.then_ = (subst_st_term then_ ss);
                Pulse_Syntax_Base.else_ = (subst_st_term else_ ss);
                Pulse_Syntax_Base.post1 =
                  (subst_term_opt post (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_Match
            { Pulse_Syntax_Base.sc = sc;
              Pulse_Syntax_Base.returns_ = returns_;
              Pulse_Syntax_Base.brs = brs;_}
            ->
            Pulse_Syntax_Base.Tm_Match
              {
                Pulse_Syntax_Base.sc = (subst_term sc ss);
                Pulse_Syntax_Base.returns_ = (subst_term_opt returns_ ss);
                Pulse_Syntax_Base.brs = (subst_branches t ss brs)
              }
        | Pulse_Syntax_Base.Tm_IntroPure { Pulse_Syntax_Base.p3 = p;_} ->
            Pulse_Syntax_Base.Tm_IntroPure
              { Pulse_Syntax_Base.p3 = (subst_term p ss) }
        | Pulse_Syntax_Base.Tm_ElimExists { Pulse_Syntax_Base.p4 = p;_} ->
            Pulse_Syntax_Base.Tm_ElimExists
              { Pulse_Syntax_Base.p4 = (subst_term p ss) }
        | Pulse_Syntax_Base.Tm_IntroExists
            { Pulse_Syntax_Base.p5 = p;
              Pulse_Syntax_Base.witnesses = witnesses;_}
            ->
            Pulse_Syntax_Base.Tm_IntroExists
              {
                Pulse_Syntax_Base.p5 = (subst_term p ss);
                Pulse_Syntax_Base.witnesses = (subst_term_list witnesses ss)
              }
        | Pulse_Syntax_Base.Tm_While
            { Pulse_Syntax_Base.invariant = invariant;
              Pulse_Syntax_Base.condition = condition;
              Pulse_Syntax_Base.condition_var = condition_var;
              Pulse_Syntax_Base.body3 = body;_}
            ->
            Pulse_Syntax_Base.Tm_While
              {
                Pulse_Syntax_Base.invariant =
                  (subst_term invariant (shift_subst ss));
                Pulse_Syntax_Base.condition = (subst_st_term condition ss);
                Pulse_Syntax_Base.condition_var = condition_var;
                Pulse_Syntax_Base.body3 = (subst_st_term body ss)
              }
        | Pulse_Syntax_Base.Tm_Par
            { Pulse_Syntax_Base.pre1 = pre1;
              Pulse_Syntax_Base.body11 = body1;
              Pulse_Syntax_Base.post11 = post1;
              Pulse_Syntax_Base.pre2 = pre2;
              Pulse_Syntax_Base.body21 = body2;
              Pulse_Syntax_Base.post2 = post2;_}
            ->
            Pulse_Syntax_Base.Tm_Par
              {
                Pulse_Syntax_Base.pre1 = (subst_term pre1 ss);
                Pulse_Syntax_Base.body11 = (subst_st_term body1 ss);
                Pulse_Syntax_Base.post11 =
                  (subst_term post1 (shift_subst ss));
                Pulse_Syntax_Base.pre2 = (subst_term pre2 ss);
                Pulse_Syntax_Base.body21 = (subst_st_term body2 ss);
                Pulse_Syntax_Base.post2 = (subst_term post2 (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_WithLocal
            { Pulse_Syntax_Base.binder2 = binder;
              Pulse_Syntax_Base.initializer1 = initializer1;
              Pulse_Syntax_Base.body4 = body;_}
            ->
            Pulse_Syntax_Base.Tm_WithLocal
              {
                Pulse_Syntax_Base.binder2 = (subst_binder binder ss);
                Pulse_Syntax_Base.initializer1 = (subst_term initializer1 ss);
                Pulse_Syntax_Base.body4 =
                  (subst_st_term body (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_WithLocalArray
            { Pulse_Syntax_Base.binder3 = binder;
              Pulse_Syntax_Base.initializer2 = initializer1;
              Pulse_Syntax_Base.length = length;
              Pulse_Syntax_Base.body5 = body;_}
            ->
            Pulse_Syntax_Base.Tm_WithLocalArray
              {
                Pulse_Syntax_Base.binder3 = (subst_binder binder ss);
                Pulse_Syntax_Base.initializer2 = (subst_term initializer1 ss);
                Pulse_Syntax_Base.length = (subst_term length ss);
                Pulse_Syntax_Base.body5 =
                  (subst_st_term body (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_Rewrite
            { Pulse_Syntax_Base.t11 = t1; Pulse_Syntax_Base.t21 = t2;
              Pulse_Syntax_Base.tac_opt2 = tac_opt;_}
            ->
            Pulse_Syntax_Base.Tm_Rewrite
              {
                Pulse_Syntax_Base.t11 = (subst_term t1 ss);
                Pulse_Syntax_Base.t21 = (subst_term t2 ss);
                Pulse_Syntax_Base.tac_opt2 = (subst_term_opt tac_opt ss)
              }
        | Pulse_Syntax_Base.Tm_Admit
            { Pulse_Syntax_Base.ctag = ctag; Pulse_Syntax_Base.u1 = u;
              Pulse_Syntax_Base.typ = typ; Pulse_Syntax_Base.post3 = post;_}
            ->
            Pulse_Syntax_Base.Tm_Admit
              {
                Pulse_Syntax_Base.ctag = ctag;
                Pulse_Syntax_Base.u1 = u;
                Pulse_Syntax_Base.typ = (subst_term typ ss);
                Pulse_Syntax_Base.post3 =
                  (subst_term_opt post (shift_subst ss))
              }
        | Pulse_Syntax_Base.Tm_Unreachable { Pulse_Syntax_Base.c = c;_} ->
            Pulse_Syntax_Base.Tm_Unreachable
              { Pulse_Syntax_Base.c = (subst_comp c ss) }
        | Pulse_Syntax_Base.Tm_ProofHintWithBinders
            { Pulse_Syntax_Base.hint_type = hint_type;
              Pulse_Syntax_Base.binders = binders;
              Pulse_Syntax_Base.t = t1;_}
            ->
            let n = FStar_List_Tot_Base.length binders in
            let ss1 = shift_subst_n n ss in
            Pulse_Syntax_Base.Tm_ProofHintWithBinders
              {
                Pulse_Syntax_Base.hint_type =
                  (subst_proof_hint hint_type ss1);
                Pulse_Syntax_Base.binders = binders;
                Pulse_Syntax_Base.t = (subst_st_term t1 ss1)
              }
        | Pulse_Syntax_Base.Tm_WithInv
            { Pulse_Syntax_Base.name1 = name; Pulse_Syntax_Base.body6 = body;
              Pulse_Syntax_Base.returns_inv = returns_inv;_}
            ->
            let name1 = subst_term name ss in
            let body1 = subst_st_term body ss in
            let returns_inv1 =
              match returns_inv with
              | FStar_Pervasives_Native.None -> FStar_Pervasives_Native.None
              | FStar_Pervasives_Native.Some (b, r, is) ->
                  FStar_Pervasives_Native.Some
                    ((subst_binder b ss), (subst_term r (shift_subst ss)),
                      (subst_term is ss)) in
            Pulse_Syntax_Base.Tm_WithInv
              {
                Pulse_Syntax_Base.name1 = name1;
                Pulse_Syntax_Base.body6 = body1;
                Pulse_Syntax_Base.returns_inv = returns_inv1
              } in
      {
        Pulse_Syntax_Base.term1 = t';
        Pulse_Syntax_Base.range1 = (t.Pulse_Syntax_Base.range1);
        Pulse_Syntax_Base.effect_tag = (t.Pulse_Syntax_Base.effect_tag);
        Pulse_Syntax_Base.source = (t.Pulse_Syntax_Base.source)
      }
and (subst_branches :
  Pulse_Syntax_Base.st_term ->
    subst ->
      Pulse_Syntax_Base.branch Prims.list ->
        Pulse_Syntax_Base.branch Prims.list)
  =
  fun t ->
    fun ss ->
      fun brs -> Pulse_Common.map_dec t brs (fun br -> subst_branch ss br)
and (subst_branch :
  subst ->
    (Pulse_Syntax_Base.pattern * Pulse_Syntax_Base.st_term) ->
      (Pulse_Syntax_Base.pattern * Pulse_Syntax_Base.st_term))
  =
  fun ss ->
    fun b ->
      let uu___ = b in
      match uu___ with
      | (p, e) ->
          let p1 = subst_pat p ss in
          let ss1 = shift_subst_n (pattern_shift_n p1) ss in
          (p1, (subst_st_term e ss1))
let (open_st_term' :
  Pulse_Syntax_Base.st_term ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.st_term)
  =
  fun t ->
    fun v -> fun i -> subst_st_term t [FStar_Reflection_Typing.DT (i, v)]
let (open_term_nv :
  Pulse_Syntax_Base.term -> Pulse_Syntax_Base.nvar -> Pulse_Syntax_Base.term)
  =
  fun t ->
    fun nv -> open_term' t (Pulse_Syntax_Pure.term_of_nvar nv) Prims.int_zero
let (open_st_term_nv :
  Pulse_Syntax_Base.st_term ->
    Pulse_Syntax_Base.nvar -> Pulse_Syntax_Base.st_term)
  =
  fun t ->
    fun nv ->
      open_st_term' t (Pulse_Syntax_Pure.term_of_nvar nv) Prims.int_zero
let (open_comp_with :
  Pulse_Syntax_Base.comp -> Pulse_Syntax_Base.term -> Pulse_Syntax_Base.comp)
  = fun c -> fun x -> open_comp' c x Prims.int_zero
let (open_comp_nv :
  Pulse_Syntax_Base.comp -> Pulse_Syntax_Base.nvar -> Pulse_Syntax_Base.comp)
  =
  fun c ->
    fun nv -> open_comp' c (Pulse_Syntax_Pure.term_of_nvar nv) Prims.int_zero
let (close_term' :
  Pulse_Syntax_Base.term ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.term)
  =
  fun t -> fun v -> fun i -> subst_term t [FStar_Reflection_Typing.ND (v, i)]
let (close_st_comp' :
  Pulse_Syntax_Base.st_comp ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.st_comp)
  =
  fun s ->
    fun v -> fun i -> subst_st_comp s [FStar_Reflection_Typing.ND (v, i)]
let (close_comp' :
  Pulse_Syntax_Base.comp ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.comp)
  =
  fun c -> fun v -> fun i -> subst_comp c [FStar_Reflection_Typing.ND (v, i)]
let (close_term_opt' :
  Pulse_Syntax_Base.term FStar_Pervasives_Native.option ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index ->
        Pulse_Syntax_Base.term FStar_Pervasives_Native.option)
  =
  fun t ->
    fun v -> fun i -> subst_term_opt t [FStar_Reflection_Typing.ND (v, i)]
let (close_term_list' :
  Pulse_Syntax_Base.term Prims.list ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.term Prims.list)
  =
  fun t ->
    fun v -> fun i -> subst_term_list t [FStar_Reflection_Typing.ND (v, i)]
let (close_binder :
  Pulse_Syntax_Base.binder ->
    FStarC_Reflection_V2_Data.var -> Prims.nat -> Pulse_Syntax_Base.binder)
  =
  fun b ->
    fun v -> fun i -> subst_binder b [FStar_Reflection_Typing.ND (v, i)]
let (close_st_term' :
  Pulse_Syntax_Base.st_term ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.st_term)
  =
  fun t ->
    fun v -> fun i -> subst_st_term t [FStar_Reflection_Typing.ND (v, i)]
let (close_term :
  Pulse_Syntax_Base.term -> Pulse_Syntax_Base.var -> Pulse_Syntax_Base.term)
  = fun t -> fun v -> close_term' t v Prims.int_zero
let (close_st_term :
  Pulse_Syntax_Base.st_term ->
    Pulse_Syntax_Base.var -> Pulse_Syntax_Base.st_term)
  = fun t -> fun v -> close_st_term' t v Prims.int_zero
let (close_comp :
  Pulse_Syntax_Base.comp -> Pulse_Syntax_Base.var -> Pulse_Syntax_Base.comp)
  = fun t -> fun v -> close_comp' t v Prims.int_zero
let close_n :
  'a .
    'a ->
      ('a -> Pulse_Syntax_Base.var -> Pulse_Syntax_Base.index -> 'a) ->
        Pulse_Syntax_Base.var Prims.list -> 'a
  =
  fun x ->
    fun f ->
      fun vs ->
        let rec aux i vs1 x1 =
          match vs1 with
          | [] -> x1
          | v::vs2 -> aux (i + Prims.int_one) vs2 (f x1 v i) in
        aux Prims.int_zero (FStar_List_Tot_Base.rev vs) x
let (close_term_n :
  Pulse_Syntax_Base.term ->
    Pulse_Syntax_Base.var Prims.list -> Pulse_Syntax_Base.term)
  = fun t -> fun vs -> close_n t close_term' vs
let (close_st_term_n :
  Pulse_Syntax_Base.st_term ->
    Pulse_Syntax_Base.var Prims.list -> Pulse_Syntax_Base.st_term)
  = fun t -> fun vs -> close_n t close_st_term' vs
let (close_comp_n :
  Pulse_Syntax_Base.comp ->
    Pulse_Syntax_Base.var Prims.list -> Pulse_Syntax_Base.comp)
  = fun c -> fun vs -> close_n c close_comp' vs
let (open_ascription' :
  Pulse_Syntax_Base.comp_ascription ->
    Pulse_Syntax_Base.term ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.comp_ascription)
  =
  fun t ->
    fun v -> fun i -> subst_ascription t [FStar_Reflection_Typing.DT (i, v)]
let (close_ascription' :
  Pulse_Syntax_Base.comp_ascription ->
    Pulse_Syntax_Base.var ->
      Pulse_Syntax_Base.index -> Pulse_Syntax_Base.comp_ascription)
  =
  fun t ->
    fun x -> fun i -> subst_ascription t [FStar_Reflection_Typing.ND (x, i)]
let (close_binders :
  Pulse_Syntax_Base.binder Prims.list ->
    Pulse_Syntax_Base.var Prims.list -> Pulse_Syntax_Base.binder Prims.list)
  =
  fun bs ->
    fun xs ->
      let rec aux s out bs1 xs1 =
        match (bs1, xs1) with
        | ([], []) -> FStar_List_Tot_Base.rev out
        | (b::bs2, x::xs2) ->
            let b1 =
              {
                Pulse_Syntax_Base.binder_ty =
                  (subst_term b.Pulse_Syntax_Base.binder_ty s);
                Pulse_Syntax_Base.binder_ppname =
                  (b.Pulse_Syntax_Base.binder_ppname);
                Pulse_Syntax_Base.binder_attrs =
                  (b.Pulse_Syntax_Base.binder_attrs)
              } in
            let s1 = (FStar_Reflection_Typing.ND (x, Prims.int_zero)) ::
              (shift_subst s) in
            aux s1 (b1 :: out) bs2 xs2 in
      aux [] [] bs xs