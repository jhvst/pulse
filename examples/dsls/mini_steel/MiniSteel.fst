module MiniSteel
module RT = Refl.Typing
module R = FStar.Reflection
open FStar.List.Tot
  
type lident = R.name

type constant =
  | Unit
  | Bool of bool
  | Int of int

let var = nat
let index = nat  

type universe = 
  | U_zero
  | U_succ of universe
  | U_var of var
  | U_max of list universe
  
type term =
  | Tm_BVar     : i:index -> term
  | Tm_Var      : v:var -> term
  | Tm_FVar     : l:lident -> term
  | Tm_Constant : c:constant -> term
  | Tm_Abs      : t:typ -> pre_hint:vprop -> body:term -> term
  | Tm_PureApp  : head:term -> arg:term -> term
  | Tm_Let      : t:typ -> e1:term -> e2:term -> term  
  | Tm_STApp    : head:term -> arg:term -> term  
  | Tm_Bind     : t:typ -> e1:term -> e2:term -> term
  | Tm_Emp      : term
  | Tm_Pure     : p:term -> term
  | Tm_Star     : l:vprop -> r:vprop -> term
  | Tm_ExistsSL : t:typ -> body:vprop -> term
  | Tm_ForallSL : t:typ -> body:vprop -> term
  | Tm_Arrow    : t:typ -> body:comp -> term 
  | Tm_Type     : universe -> term
  | Tm_VProp    : term
  | Tm_If       : b:term -> then_:term -> else_:term -> term

and comp = 
  | C_Tot : typ -> comp
  | C_ST  : st_comp -> comp

and st_comp = {
  res:typ;
  pre:vprop;
  post:vprop
}

and typ = term

and vprop = term

let rec open_term' (t:term) (v:var) (i:index)
  : term
  = admit()
and open_comp' (c:comp) (v:var) (i:index)
  : comp
  = admit()

let open_term t v = open_term' t v 0

let rec close_term' (t:term) (v:var) (i:index)
  : term
  = admit()
and close_comp' (c:comp) (v:var) (i:index)
  : comp
  = admit()

let close_term t v = close_term' t v 0
let close_comp t v = close_comp' t v 0

assume
val open_comp_with' (c:comp) (x:term) (v:index)
  : c':comp{ C_ST? c' <==> C_ST? c }
let open_comp_with c x = open_comp_with' c x 0

let fstar_env =
  g:R.env { 
    RT.lookup_fvar g RT.bool_fv == Some (RT.tm_type RT.u_zero)
    ///\ vprop etc
  }

let fstar_top_env =
  g:fstar_env { 
    forall x. None? (RT.lookup_bvar g x )
  }

let eqn = term & term
let binding = either typ eqn
let env = list (var & binding)

let tun = R.pack_ln R.Tv_Unknown

assume
val mk_st (res pre post:R.term) : R.comp

let rec elab_term (t:term)
  : R.term
  = let open R in
    match t with
    | Tm_BVar n -> 
      let bv = pack_bv (RT.make_bv n tun) in
      pack_ln (Tv_BVar bv)
      
    | Tm_Var n ->
      // tun because type does not matter at a use site
      let bv = pack_bv (RT.make_bv n tun) in
      pack_ln (Tv_Var bv)

    | Tm_FVar l ->
      pack_ln (Tv_FVar (pack_fv l))

    | Tm_Abs t _ b ->
      let t = elab_term t in
      let b = elab_term b in
      R.pack_ln (Tv_Abs (RT.as_binder 0 t) b)
      
    | Tm_PureApp e1 e2 ->
      let e1 = elab_term e1 in
      let e2 = elab_term e2 in
      pack_ln (Tv_App e1 (e2, Q_Explicit))

    | Tm_Arrow t c ->
      let t = elab_term t in
      let c = elab_comp c in
      R.pack_ln 
        (R.Tv_Arrow 
          (RT.as_binder 0 t) 
          c)

    | _ -> admit()

and elab_comp (c:comp) 
  : R.comp
  = match c with
    | C_Tot t ->
      let t = elab_term t in 
      RT.mk_total t

    | C_ST c ->
      let res = elab_term c.res in
      let pre = elab_term c.pre in
      let post = elab_term c.post in
      mk_st res pre post


assume
val extend_env_l (f:fstar_top_env) (g:env) : fstar_env

let rec lookup (e:list (var & 'a)) (x:var)
  : option 'a
  = match e with
    | [] -> None
    | (y, v) :: tl -> if x = y then Some v else lookup tl x

let lookup_ty (e:env) (x:var)
  : option typ
  = match lookup e x with
    | Some (Inl t) -> Some t
    | _ -> None

let comp_ty (c:comp) 
  : typ
  = match c with
    | C_Tot t -> t
    | C_ST c -> c.res

let add_frame (s:st_comp) (frame:term) = 
   { s with pre = Tm_Star s.pre frame;
            post = Tm_Star s.post frame }

assume
val freevars (t:term) : FStar.Set.set var


[@@erasable]
noeq
type bind_comp (f:fstar_top_env) : env -> st_comp -> var -> st_comp -> st_comp -> Type =
  | Bind_comp :
      g:env ->
      c1:st_comp ->
      x:var ->
      c2:st_comp {
        open_term c1.post x == c2.pre /\
        ~(x `Set.mem` freevars c2.post) /\
        ~(x `Set.mem` freevars c2.res) 
      } ->
      bind_comp f g c1 x c2 ({res = c2.res; pre = c1.pre; post=c2.post})



assume
val tm_bool : term
assume
val tm_true : term
assume
val tm_false : term
let mk_eq2 t (e0 e1:term) 
  : term
  = Tm_PureApp
         (Tm_PureApp (Tm_PureApp (Tm_FVar R.eq2_qn) t)
                      e0) e1

let return_comp (t:typ) (e:term) =
  { res = t;
    pre = Tm_Emp;
    post = Tm_Pure (mk_eq2 t (Tm_BVar 0) e) }


[@@erasable]
noeq
type vprop_equiv (f:fstar_top_env) : env -> term -> term -> Type =
  | VE_Refl:
     g:env ->
     t:term ->
     vprop_equiv f g t t

  | VE_Sym:
     g:env ->
     t1:term -> 
     t2:term -> 
     vprop_equiv f g t1 t2 ->
     vprop_equiv f g t2 t1

  | VE_Trans:
     g:env ->
     t0:term ->
     t1:term ->
     t2:term ->
     vprop_equiv f g t0 t1 ->
     vprop_equiv f g t1 t2 ->
     vprop_equiv f g t0 t2

  | VE_Ctxt:
     g:env ->
     t0:term -> 
     t1:term -> 
     t0':term -> 
     t1':term ->
     vprop_equiv f g t0 t0' ->
     vprop_equiv f g t1 t1' ->
     vprop_equiv f g (Tm_Star t0 t1) (Tm_Star t0' t1')
     
  | VE_Unit:
     g:env ->
     t:term ->
     vprop_equiv f g (Tm_Star Tm_Emp t) t

  | VE_Comm:
     g:env ->
     t0:term ->
     t1:term ->
     vprop_equiv f g (Tm_Star t0 t1) (Tm_Star t1 t0)
     
  | VE_Assoc:
     g:env ->
     t0:term ->
     t1:term ->
     t2:term ->
     vprop_equiv f g (Tm_Star t0 (Tm_Star t1 t2)) (Tm_Star (Tm_Star t0 t1) t2)

  | VE_Ex:
     g:env ->
     x:var { None? (lookup_ty g x) } ->
     ty:typ ->
     t0:term ->
     t1:term ->
     vprop_equiv f ((x, Inl ty)::g) (open_term t0 x) (open_term t1 x) ->
     vprop_equiv f g (Tm_ExistsSL ty t0) (Tm_ExistsSL ty t1)

  | VE_Fa:
     g:env ->
     x:var { None? (lookup_ty g x) } ->
     ty:typ ->
     t0:term ->
     t1:term ->
     vprop_equiv f ((x, Inl ty)::g) (open_term t0 x) (open_term t1 x) ->
     vprop_equiv f g (Tm_ForallSL ty t0) (Tm_ForallSL ty t1)

[@@erasable]
noeq
type st_equiv (f:fstar_top_env) : env -> st_comp -> st_comp -> Type =
  | ST_Equiv :
      g:env ->
      c1:st_comp ->
      c2:st_comp { c1.res == c2.res } -> 
      x:var { None? (lookup_ty g x) } ->
      vprop_equiv f g c1.pre c2.pre ->
      vprop_equiv f ((x, Inl c1.res)::g) (open_term c1.post x) (open_term c2.post x) ->      
      st_equiv f g c1 c2

[@@erasable]
noeq
type src_typing (f:fstar_top_env) : env -> term -> comp -> Type =
  | T_Tot: 
      g:env ->
      e:term ->
      ty:typ ->
      RT.typing (extend_env_l f g) (elab_term e) (elab_term ty) ->
      src_typing f g e (C_Tot ty)

  | T_Abs: 
      g:env ->
      x:var { None? (lookup g x) } ->
      ty:typ ->
      u:universe ->
      body:term ->
      c:comp ->
      hint:vprop ->
      tot_typing f g ty (Tm_Type u) ->
      src_typing f ((x, Inl ty)::g) (open_term body x) c ->
      src_typing f g (Tm_Abs ty hint body) (C_Tot (Tm_Arrow ty (close_comp c x)))
  
  | T_STApp :
      g:env ->
      head:term -> 
      formal:typ ->
      res:st_comp ->
      arg:term ->
      tot_typing f g head (Tm_Arrow formal (C_ST res)) ->
      tot_typing f g arg formal ->
      src_typing f g (Tm_STApp head arg) (open_comp_with (C_ST res) arg)

  | T_Return:
      g:env ->
      e:term -> 
      t:typ -> 
      tot_typing f g e t ->
      src_typing f g e (C_ST (return_comp t e))
      
  | T_Bind:
      g:env ->
      e1:term ->
      e2:term ->
      c1:st_comp ->
      c2:st_comp ->
      x:var { None? (lookup g x) (*  /\ ~(x `Set.mem` freevars e2) *) } ->
      c:st_comp ->
      src_typing f g e1 (C_ST c1) ->
      src_typing f ((x, Inl c1.res)::g) (open_term e2 x) (C_ST c2) ->
      bind_comp f g c1 x c2 c ->
      src_typing f g (Tm_Bind c1.res e1 e2) (C_ST c)

  | T_If:
      g:env ->
      b:term -> 
      e1:term ->
      e2:term -> 
      c:comp ->
      hyp:var { None? (lookup g hyp) // /\ ~ (hyp `Set.mem` freevars e1) /\ ~ (hyp `Set.mem` freevars e2)
  } ->
      tot_typing f g b tm_bool ->
      src_typing f ((hyp, Inr (b, tm_true)) :: g) e1 c ->
      src_typing f ((hyp, Inr (b, tm_false)) :: g) e2 c ->
      src_typing f g (Tm_If b e1 e2) c

  | T_Frame:
      g:env ->
      e:term ->
      c:st_comp ->
      frame:term ->
      tot_typing f g frame Tm_VProp ->
      src_typing f g e (C_ST c) ->
      src_typing f g e (C_ST (add_frame c frame))

  | T_Equiv:
      g:env ->
      e:term ->
      c:st_comp ->
      c':st_comp ->      
      src_typing f g e (C_ST c) ->
      st_equiv f g c c' ->
      src_typing f g e (C_ST c')

and tot_typing (f:fstar_top_env) (g:env) (e:term) (t:typ) = 
  src_typing f g e (C_Tot t)

and st_typing (f:fstar_top_env) (g:env) (e:term) (st:st_comp) = 
  src_typing f g e (C_ST st)

let star_typing_inversion (f:_) (g:_) (t0 t1:term) (d:tot_typing f g (Tm_Star t0 t1) Tm_VProp)
  : (tot_typing f g t0 Tm_VProp &
     tot_typing f g t1 Tm_VProp)
  = admit()

let star_typing (#f:_) (#g:_) (#t0 #t1:term)
                (d0:tot_typing f g t0 Tm_VProp)
                (d1:tot_typing f g t1 Tm_VProp)
  : tot_typing f g (Tm_Star t0 t1) Tm_VProp
  = admit()


let emp_typing (#f:_) (#g:_) 
  : tot_typing f g Tm_Emp Tm_VProp
  = admit()

let rec vprop_equiv_typing (f:_) (g:_) (t0 t1:term) (v:vprop_equiv f g t0 t1)
  : GTot ((tot_typing f g t0 Tm_VProp -> tot_typing f g t1 Tm_VProp) &
          (tot_typing f g t1 Tm_VProp -> tot_typing f g t0 Tm_VProp))
         (decreases v)
  = match v with
    | VE_Refl _ _ -> (fun x -> x), (fun x -> x)
    | VE_Sym _ _ _ v' -> 
      let f, g = vprop_equiv_typing f g t1 t0 v' in
      g, f
    | VE_Trans g t0 t2 t1 v02 v21 ->
      let f02, f20 = vprop_equiv_typing _ _ _ _ v02 in
      let f21, f12 = vprop_equiv_typing _ _ _ _ v21 in
      (fun x -> f21 (f02 x)), 
      (fun x -> f20 (f12 x))
    | VE_Ctxt g s0 s1 s0' s1' v0 v1 ->
      let f0, f0' = vprop_equiv_typing _ _ _ _ v0 in
      let f1, f1' = vprop_equiv_typing _ _ _ _ v1 in      
      let ff (x:tot_typing f g (Tm_Star s0 s1) Tm_VProp)
        : tot_typing f g (Tm_Star s0' s1') Tm_VProp
        = let s0_typing, s1_typing = star_typing_inversion _ _ _ _ x in
          let s0'_typing, s1'_typing = f0 s0_typing, f1 s1_typing in
          star_typing s0'_typing s1'_typing
      in
      let gg (x:tot_typing f g (Tm_Star s0' s1') Tm_VProp)
        : tot_typing f g (Tm_Star s0 s1) Tm_VProp
        = let s0'_typing, s1'_typing = star_typing_inversion _ _ _ _ x in
          star_typing (f0' s0'_typing) (f1' s1'_typing)        
      in
      ff, gg


    | _ -> admit()
      

  
module L = FStar.List.Tot
let max (n1 n2:nat) = if n1 < n2 then n2 else n1

let rec fresh (e:list (var & 'a))
  : var
  = match e with
    | [] -> 0
    | (y, _) :: tl ->  max (fresh tl) y + 1
    | _ :: tl -> fresh tl

let rec fresh_not_mem (e:list (var & 'a)) (elt: (var & 'a))
  : Lemma (ensures L.memP elt e ==> fresh e > fst elt)
  = match e with
    | [] -> ()
    | hd :: tl -> fresh_not_mem tl elt
  
let rec lookup_mem (e:list (var & 'a)) (x:var)
  : Lemma
    (requires Some? (lookup e x))
    (ensures exists elt. L.memP elt e /\ fst elt == x)
  = match e with
    | [] -> ()
    | hd :: tl -> 
      match lookup tl x with
      | None -> assert (L.memP hd e)
      | _ -> 
        lookup_mem tl x;
        eliminate exists elt. L.memP elt tl /\ fst elt == x
        returns _
        with _ . ( 
          introduce exists elt. L.memP elt e /\ fst elt == x
          with elt
          and ()
        )

let fresh_is_fresh (e:env)
  : Lemma (None? (lookup e (fresh e)))
          [SMTPat (lookup e (fresh e))]
  =  match lookup e (fresh e) with
     | None -> ()
     | Some _ ->
       lookup_mem e (fresh e);
       FStar.Classical.forall_intro (fresh_not_mem e)
module RT = Refl.Typing

module T = FStar.Tactics      

assume
val tc_meta_callback (f:fstar_env) (e:R.term) 
  : T.Tac (option (t:R.term & RT.typing f e t))

assume
val readback_ty (t:R.term)
  : T.Tac (option (ty:typ { elab_term ty == t }))
  
let check_tot (f:fstar_top_env) (g:env) (t:term)
  : T.Tac (ty:typ &
           tot_typing f g t ty)
  = let f = extend_env_l f g in
    match tc_meta_callback f (elab_term t) with
    | None -> T.fail "Not typeable"
    | Some (| ty', tok |) ->
      match readback_ty ty' with
      | None -> T.fail "Inexpressible type"
      | Some ty -> (| ty, T_Tot g t ty tok |)

let rec vprop_as_list (vp:term)
  : list term
  = match vp with
    | Tm_Star vp0 vp1 -> vprop_as_list vp0 @ vprop_as_list vp1
    | _ -> [vp]

let rec list_as_vprop (vps:list term)
  = match vps with
    | [] -> Tm_Emp
    | hd::tl -> Tm_Star hd (list_as_vprop tl)

let canon_vprop (vp:term)
  : term
  = list_as_vprop (vprop_as_list vp)

let rec list_as_vprop_append f g (vp0 vp1:list term)
  : GTot (vprop_equiv f g (list_as_vprop (vp0 @ vp1))
                          (Tm_Star (list_as_vprop vp0) 
                                   (list_as_vprop vp1)))
         (decreases vp0)
  = match vp0 with
    | [] -> 
      let v : vprop_equiv f g (list_as_vprop vp1)
                              (Tm_Star Tm_Emp (list_as_vprop vp1)) = VE_Sym _ _ _ (VE_Unit _ _)
      in
      v
    | hd::tl ->
      let tl_vp1 = list_as_vprop_append f g tl vp1 in
      let d : vprop_equiv f g (list_as_vprop (vp0 @ vp1))
                              (Tm_Star hd (Tm_Star (list_as_vprop tl) (list_as_vprop vp1)))
            = VE_Ctxt _ _ _ _ _ (VE_Refl _ _) tl_vp1
      in
      let d : vprop_equiv f g (list_as_vprop (vp0 @ vp1))
                              (Tm_Star (Tm_Star hd (list_as_vprop tl)) (list_as_vprop vp1))
            = VE_Trans _ _ _ _ d (VE_Assoc _ _ _ _) in
      d

let list_as_vprop_comm f g (vp0 vp1:list term)
  : GTot (vprop_equiv f g (list_as_vprop (vp0 @ vp1))
                          (list_as_vprop (vp1 @ vp0)))
  = let d1 : _ = list_as_vprop_append f g vp0 vp1 in
    let d2 : _ = VE_Sym _ _ _ (list_as_vprop_append f g vp1 vp0) in
    let d1 : _ = VE_Trans _ _ _ _ d1 (VE_Comm _ _ _) in
    VE_Trans _ _ _ _ d1 d2

let list_as_vprop_assoc f g (vp0 vp1 vp2:list term)
  : GTot (vprop_equiv f g (list_as_vprop (vp0 @ (vp1 @ vp2)))
                          (list_as_vprop ((vp0 @ vp1) @ vp2)))
  = List.Tot.append_assoc vp0 vp1 vp2;
    VE_Refl _ _
  
let rec vprop_list_equiv (f:fstar_top_env)
                         (g:env)
                         (vp:term)
  : GTot (vprop_equiv f g vp (canon_vprop vp))
         (decreases vp)
  = match vp with
    | Tm_Star vp0 vp1 ->
      let eq0 = vprop_list_equiv f g vp0 in
      let eq1 = vprop_list_equiv f g vp1 in      
      let app_eq
        : vprop_equiv _ _ (canon_vprop vp) (Tm_Star (canon_vprop vp0) (canon_vprop vp1))
        = list_as_vprop_append f g (vprop_as_list vp0) (vprop_as_list vp1)
      in
      let step
        : vprop_equiv _ _ vp (Tm_Star (canon_vprop vp0) (canon_vprop vp1))
        = VE_Ctxt _ _ _ _ _ eq0 eq1
      in
      VE_Trans _ _ _ _ step (VE_Sym _ _ _ app_eq)
      
    | _ -> 
      VE_Sym _ _ _
        (VE_Trans _ _ _ _ (VE_Comm g vp Tm_Emp) (VE_Unit _ vp))

module L = FStar.List.Tot.Base
let rec maybe_split_one_vprop (p:term) (qs:list term)
  : option (list term & list term)
  = match qs with
    | [] -> None
    | q::qs -> 
      if p = q
      then Some ([], qs)
      else match maybe_split_one_vprop p qs with
           | None -> None
           | Some (l, r) -> Some (q::l, r)
    
let can_split_one_vprop p qs = Some? (maybe_split_one_vprop p qs)

let split_one_vprop_l (p:term) 
                    (qs:list term { can_split_one_vprop p qs })
  : list term
  = let Some (l, r) = maybe_split_one_vprop p qs in
    l

let split_one_vprop_r (p:term) 
                    (qs:list term { can_split_one_vprop p qs })
  : list term
  = let Some (l, r) = maybe_split_one_vprop p qs in
    r

let vprop_equiv_swap (f:_) (g:_) (l0 l1 l2:list term)
  : GTot (vprop_equiv f g (list_as_vprop ((l0 @ l1) @ l2))
                          (list_as_vprop (l1 @ (l0 @ l2))))
  = let d1 : _ = list_as_vprop_append f g (l0 @ l1) l2 in
    let d2 = VE_Trans _ _ _ _ d1 (VE_Ctxt _ _ _ _ _ (list_as_vprop_comm _ _ _ _) (VE_Refl _ _)) in
    let d3 = VE_Sym _ _ _ (list_as_vprop_append f g (l1 @ l0) l2) in
    let d4 = VE_Trans _ _ _ _ d2 d3 in
    List.Tot.append_assoc l1 l0 l2;
    d4

let split_one_vprop (p:term) 
                    (qs:list term { can_split_one_vprop p qs })
  : list term
  = split_one_vprop_l p qs @ split_one_vprop_r p qs 

let split_one_vprop_equiv f g (p:term) (qs:list term { can_split_one_vprop p qs })
  : vprop_equiv f g (list_as_vprop qs) (Tm_Star p (list_as_vprop (split_one_vprop p qs)))
  = let rec aux (qs:list term { can_split_one_vprop p qs })
      : Lemma (qs == ((split_one_vprop_l p qs @ [p]) @ split_one_vprop_r p qs))
      = match qs with
        | q :: qs ->
          if p = q then ()
          else aux qs
    in
    aux qs;
    vprop_equiv_swap f g (split_one_vprop_l p qs) [p] (split_one_vprop_r p qs)

let rec try_split_vprop f g (req:list term) (ctxt:list term)
  : option (frame:list term &
            vprop_equiv f g (list_as_vprop (req @ frame)) (list_as_vprop ctxt))
  = match req with
    | [] -> Some (| ctxt, VE_Refl g _ |)
    | hd::tl ->
      match maybe_split_one_vprop hd ctxt with
      | None -> None
      | Some (l, r) -> 
        let d1 : vprop_equiv f g (list_as_vprop ctxt) (list_as_vprop (hd :: (l@r))) = split_one_vprop_equiv _ _ hd ctxt in
        match try_split_vprop f g tl (l @ r) with
        | None -> None
        | Some (| frame, d |) ->
          let d : vprop_equiv f g (list_as_vprop (tl @ frame)) (list_as_vprop (l @ r)) = d in
          let dd : vprop_equiv f g (list_as_vprop (req @ frame)) (list_as_vprop (hd :: (l @ r))) = 
              VE_Ctxt _ _ _ _ _ (VE_Refl _ hd) d
          in
          let ddd = VE_Trans _ _ _ _ dd (VE_Sym _ _ _ d1) in
          Some (| frame, ddd |)
                       
let split_vprop (f:fstar_top_env)
                (g:env)
                (ctxt:term)
                (ctxt_typing: tot_typing f g ctxt Tm_VProp)
                (req:term)
   : T.Tac (frame:term &
            tot_typing f g frame Tm_VProp &
            vprop_equiv f g (Tm_Star req frame) ctxt)
   = let ctxt_l = vprop_as_list ctxt in
     let req_l = vprop_as_list req in
     match try_split_vprop f g req_l ctxt_l with
     | None -> T.fail "Could not find frame"
     | Some (| frame, veq |) ->
       let d1 
         : vprop_equiv _ _ (Tm_Star (canon_vprop req) (list_as_vprop frame))
                           (list_as_vprop (req_l @ frame))
         = VE_Sym _ _ _ (list_as_vprop_append f g req_l frame)
       in
       let d1 
         : vprop_equiv _ _ (Tm_Star req (list_as_vprop frame))
                           (list_as_vprop (req_l @ frame))
         = VE_Trans _ _ _ _ (VE_Ctxt _ _ _ _ _ (vprop_list_equiv f g req) (VE_Refl _ _)) d1
       in
       let d : vprop_equiv _ _ (Tm_Star req (list_as_vprop frame))
                               (canon_vprop ctxt) =
           VE_Trans _ _ _ _ d1 veq
       in
       let d : vprop_equiv _ _ (Tm_Star req (list_as_vprop frame))
                               ctxt =
         VE_Trans _ _ _ _ d (VE_Sym _ _ _ (vprop_list_equiv f g ctxt))
       in
       let typing : tot_typing f g (list_as_vprop frame) Tm_VProp = 
         let fwd, bk = vprop_equiv_typing _ _ _ _ d in
         let star_typing = bk ctxt_typing in
         snd (star_typing_inversion _ _ _ _ star_typing)
       in
       (| list_as_vprop frame, typing, d |)

let try_frame_pre (#f:fstar_top_env)
                  (#g:env)
                  (#t:term)
                  (#pre:term)
                  (pre_typing: tot_typing f g pre Tm_VProp)
                  (#c:comp { C_ST? c })
                  (t_typing: src_typing f g t c)
  : T.Tac (c':st_comp { c'.pre == pre } &
           src_typing f g t (C_ST c'))
  = let C_ST s = c in
    let (| frame, frame_typing, ve |) = split_vprop f g pre pre_typing s.pre in
    let t_typing
      : st_typing f g t (add_frame s frame)
      = T_Frame g t s frame frame_typing t_typing in
    let x = fresh g in
    let s' = add_frame s frame in
    let ve: vprop_equiv f g s'.pre pre = ve in
    let s'' = { s' with pre = pre } in
    let st_equiv = ST_Equiv g s' s'' x ve (VE_Refl _ _) in
    let t_typing = T_Equiv _ _ _ _ t_typing st_equiv in
    (| s'', t_typing |)

let rec check (f:fstar_top_env)
              (g:env)
              (t:term)
              (pre:term)
              (pre_typing: tot_typing f g pre Tm_VProp)
  : T.Tac (c:st_comp { c.pre == pre } &
           src_typing f g t (C_ST c))
  = let return (ty:typ) (d:tot_typing f g t ty)
      : (c:st_comp {c.pre == pre} &
         src_typing f g t (C_ST c))
      = let d = T_Return _ _ _ d in
        let d = T_Frame _ _ _ pre pre_typing d in
        let c = add_frame (return_comp ty t) pre in
        let d : src_typing f g t (C_ST c) = d in
        let c' = { c with pre = pre } in
        let x = fresh g in
        let eq : st_equiv f g c c' = ST_Equiv g c c' x (VE_Unit g pre) (VE_Refl _ _) in
        (| c', T_Equiv _ _ _ _ d eq |)
    in
    match t with
    | Tm_BVar _ -> T.fail "not locally nameless"
    | Tm_Var _
    | Tm_FVar _ 
    | Tm_Constant _
    | Tm_PureApp _ _
    | Tm_Let _ _ _ 
    | Tm_Emp
    | Tm_Pure _
    | Tm_Star _ _ 
    | Tm_ExistsSL _ _
    | Tm_ForallSL _ _
    | Tm_Arrow _ _
    | Tm_Type _
    | Tm_VProp ->
      let (| ty, d |) = check_tot f g t in
      return ty d

    | Tm_Abs t pre_hint body -> (
      match check_tot f g t with
      | (| Tm_Type u, t_typing |) ->
        let x = fresh g in
        let g' = (x, Inl t) :: g in
        let pre = open_term pre_hint x in
        (
        match check_tot f g' pre with
        | (| Tm_VProp, pre_typing |) ->
          let (| c_body, body_typing |) = check f g' (open_term body x) pre pre_typing in
          let tt = T_Abs g x t u body (C_ST c_body) pre_hint t_typing body_typing in
          return _ tt
          
        | _ -> T.fail "bad hint"
        )
      | _ -> T.fail "Expected a type"
      )

    | Tm_STApp head arg ->
      let (| ty_head, dhead |) = check_tot f g head in
      let (| ty_arg, darg |) = check_tot f g arg in      
      begin
      match ty_head with
      | Tm_Arrow formal (C_ST res) ->
        if ty_arg <> formal
        then T.fail "Type of formal parameter does not match type of argument"
        else let d = T_STApp g head formal res arg dhead darg in
             try_frame_pre pre_typing d
      | _ -> T.fail "Unexpected head type in impure application"
      end

    | Tm_Bind t e1 e2 ->
      let (| c1, d1 |) = check f g e1 pre pre_typing in
      if t <> c1.res 
      then T.fail "Annotated type of let-binding is incorrect"
      else (
        let x = fresh g in
        let next_pre = open_term c1.post x in
        let g' = (x, Inl c1.res)::g in
        let next_pre_typing : tot_typing f g' next_pre Tm_VProp =
          //would be nice to prove that this is typable as a lemma,
          //without having to re-check it
          match check_tot f g' next_pre with
          | (| Tm_VProp, nt |) -> nt
          | _ -> T.fail "next pre is not typable"
        in
        let (| c2, d2 |) = check f g' (open_term e2 x) next_pre next_pre_typing in
        if x `Set.mem` freevars c2.post
        ||  x `Set.mem` freevars c2.res
        then T.fail "Let-bound variable escapes its scope"
        else (| _, T_Bind _ _ _ _ _ _ _ d1 d2 (Bind_comp _ _ _ _) |)
     )

    | Tm_If _ _ _ ->
      T.fail "Not handling if yet"

////////////////////////////////////////////////////////////////////////////////
// elaboration
////////////////////////////////////////////////////////////////////////////////
