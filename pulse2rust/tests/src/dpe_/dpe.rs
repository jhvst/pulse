////
////
//// This file is generated by the Pulse2Rust tool
////
////

pub fn run_stt<A>(post: (), f: A) -> A {
    panic!()
}
pub type ctxt_hndl_t = u32;
pub type sid_t = u32;
#[derive(Clone)]
pub struct session_state__Available__payload {
    pub handle: super::dpe::ctxt_hndl_t,
    pub context: super::dpetypes::context_t,
}
#[derive(Clone)]
pub enum session_state {
    SessionStart,
    Available(super::dpe::session_state__Available__payload),
    InUse,
    SessionClosed,
    SessionError,
}
pub fn mk_available(
    hndl: super::dpe::ctxt_hndl_t,
    ctxt: super::dpetypes::context_t,
) -> super::dpe::session_state {
    super::dpe::session_state::Available(super::dpe::session_state__Available__payload {
        handle: hndl,
        context: ctxt,
    })
}
pub fn mk_available_payload(
    handle: super::dpe::ctxt_hndl_t,
    context: super::dpetypes::context_t,
) -> super::dpe::session_state__Available__payload {
    super::dpe::session_state__Available__payload {
        handle: handle,
        context: context,
    }
}
pub fn intro_session_state_perm_available(
    ctxt: super::dpetypes::context_t,
    hndl: super::dpe::ctxt_hndl_t,
    __repr: (),
) -> super::dpe::session_state {
    super::dpe::session_state::Available(super::dpe::mk_available_payload(hndl, ctxt))
}
pub struct global_state_t {
    pub session_id_counter: super::dpe::sid_t,
    pub session_table: super::pulse_lib_hashtable_type::ht_t<
        super::dpe::sid_t,
        super::dpe::session_state,
    >,
}
pub fn sid_hash(uu___: super::dpe::sid_t) -> usize {
    panic!()
}
pub const fn initialize_global_state(
    uu___: (),
) -> std::sync::Mutex<std::option::Option<super::dpe::global_state_t>> {
    let res = None;
    std::sync::Mutex::new(res)
}
pub static global_state: std::sync::Mutex<
    std::option::Option<super::dpe::global_state_t>,
> = super::dpe::initialize_global_state(());
pub fn mk_global_state(uu___: ()) -> super::dpe::global_state_t {
    let session_table = super::pulse_lib_hashtable::alloc(super::dpe::sid_hash, 256);
    let st = super::dpe::global_state_t {
        session_id_counter: 0,
        session_table: session_table,
    };
    st
}
pub fn get_profile(uu___: ()) -> super::dpetypes::profile_descriptor_t {
    super::dpetypes::mk_profile_descriptor(
        "".to_string(),
        1,
        0,
        false,
        false,
        false,
        false,
        0,
        "".to_string(),
        false,
        "".to_string(),
        "".to_string(),
        false,
        true,
        1,
        16,
        false,
        false,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        true,
        "".to_string(),
        "".to_string(),
        "".to_string(),
        false,
        "".to_string(),
        "".to_string(),
        "".to_string(),
        false,
        false,
        false,
        "".to_string(),
        "".to_string(),
        "".to_string(),
        false,
        0,
        0,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        "".to_string(),
        false,
        "".to_string(),
        "".to_string(),
        "".to_string(),
        false,
        "".to_string(),
        "".to_string(),
        false,
        false,
        false,
        "".to_string(),
    )
}
pub fn insert_if_not_full<KT: Copy + PartialEq + Clone, VT: Clone>(
    ht: super::pulse_lib_hashtable_type::ht_t<KT, VT>,
    k: KT,
    v: VT,
    pht: (),
) -> (super::pulse_lib_hashtable_type::ht_t<KT, VT>, bool) {
    let b = super::pulse_lib_hashtable::not_full(ht, ());
    if b.1 {
        super::pulse_lib_hashtable::insert(b.0, k, v, ())
    } else {
        let res = (b.0, false);
        res
    }
}
pub fn safe_add(i: u32, j: u32) -> std::option::Option<u32> {
    panic!()
}
pub fn open_session_aux(
    st: super::dpe::global_state_t,
) -> (super::dpe::global_state_t, std::option::Option<super::dpe::sid_t>) {
    let ctr = st.session_id_counter;
    let tbl = st.session_table;
    let opt_inc = super::dpe::safe_add(ctr, 1);
    match opt_inc {
        None => {
            let st1 = super::dpe::global_state_t {
                session_id_counter: ctr,
                session_table: tbl,
            };
            let res = (st1, None);
            res
        }
        Some(mut next_sid) => {
            let res = super::dpe::insert_if_not_full(
                tbl,
                ctr,
                super::dpe::session_state::SessionStart,
                (),
            );
            if res.1 {
                let st1 = super::dpe::global_state_t {
                    session_id_counter: next_sid,
                    session_table: res.0,
                };
                let res1 = (st1, Some(next_sid));
                res1
            } else {
                let st1 = super::dpe::global_state_t {
                    session_id_counter: ctr,
                    session_table: res.0,
                };
                let res1 = (st1, None);
                res1
            }
        }
    }
}
pub fn open_session(uu___: ()) -> std::option::Option<super::dpe::sid_t> {
    let r: &mut std::option::Option<super::dpe::global_state_t> = &mut super::dpe::global_state
        .lock()
        .unwrap();
    let st_opt = std::mem::replace(r, None);
    match st_opt {
        None => {
            let st = super::dpe::mk_global_state(());
            let res = super::dpe::open_session_aux(st);
            *r = Some(res.0);
            res.1
        }
        Some(mut st) => {
            let res = super::dpe::open_session_aux(st);
            *r = Some(res.0);
            res.1
        }
    }
}
pub fn destroy_ctxt(ctxt: super::dpetypes::context_t, repr: ()) -> () {
    match ctxt {
        super::dpetypes::context_t::Engine_context(mut c) => drop(c.uds),
        super::dpetypes::context_t::L0_context(mut c) => drop(c.cdi),
        super::dpetypes::context_t::L1_context(mut c) => {
            drop(c.deviceID_priv);
            drop(c.deviceID_pub);
            drop(c.aliasKey_priv);
            drop(c.aliasKey_pub);
            drop(c.aliasKeyCRT);
            drop(c.deviceIDCSR)
        }
    }
}
pub fn return_none<A>(p: ()) -> std::option::Option<A> {
    None
}
pub fn dflt<A>(x: std::option::Option<A>, y: A) -> A {
    match x {
        Some(mut v) => v,
        _ => y,
    }
}
pub fn take_session_state(
    sid: super::dpe::sid_t,
    replace_with: super::dpe::session_state,
) -> std::option::Option<super::dpe::session_state> {
    let r: &mut std::option::Option<super::dpe::global_state_t> = &mut super::dpe::global_state
        .lock()
        .unwrap();
    let st_opt = std::mem::replace(r, None);
    match st_opt {
        None => None,
        Some(mut st) => {
            let ctr = st.session_id_counter;
            let tbl = st.session_table;
            if sid < ctr {
                let ss = super::pulse_lib_hashtable::lookup((), tbl, sid);
                if ss.1 {
                    match ss.2 {
                        Some(mut idx) => {
                            let ok = super::pulse_lib_hashtable::replace(
                                (),
                                ss.0,
                                idx,
                                sid,
                                replace_with,
                                (),
                            );
                            let st1 = super::dpe::global_state_t {
                                session_id_counter: ctr,
                                session_table: ok.0,
                            };
                            *r = Some(st1);
                            Some(ok.1)
                        }
                        None => {
                            let st1 = super::dpe::global_state_t {
                                session_id_counter: ctr,
                                session_table: ss.0,
                            };
                            *r = Some(st1);
                            None
                        }
                    }
                } else {
                    let st1 = super::dpe::global_state_t {
                        session_id_counter: ctr,
                        session_table: ss.0,
                    };
                    *r = Some(st1);
                    None
                }
            } else {
                let st1 = super::dpe::global_state_t {
                    session_id_counter: ctr,
                    session_table: tbl,
                };
                *r = Some(st1);
                None
            }
        }
    }
}
pub fn destroy_context(
    sid: super::dpe::sid_t,
    ctxt_hndl: super::dpe::ctxt_hndl_t,
) -> bool {
    let st = super::dpe::take_session_state(sid, super::dpe::session_state::InUse);
    match st {
        None => false,
        Some(mut st1) => {
            match st1 {
                super::dpe::session_state::Available(mut st11) => {
                    if ctxt_hndl == st11.handle {
                        super::dpe::destroy_ctxt(st11.context, ());
                        let st_ = super::dpe::take_session_state(
                            sid,
                            super::dpe::session_state::SessionStart,
                        );
                        true
                    } else {
                        let st_ = super::dpe::take_session_state(
                            sid,
                            super::dpe::session_state::Available(st11),
                        );
                        false
                    }
                }
                _ => {
                    let st_ = super::dpe::take_session_state(
                        sid,
                        super::dpe::session_state::SessionError,
                    );
                    false
                }
            }
        }
    }
}
pub fn destroy_session_state(st: super::dpe::session_state) -> () {
    match st {
        super::dpe::session_state::Available(mut st1) => {
            super::dpe::destroy_ctxt(st1.context, ())
        }
        _ => {}
    }
}
pub fn close_session(sid: super::dpe::sid_t) -> bool {
    let st = super::dpe::take_session_state(sid, super::dpe::session_state::InUse);
    match st {
        None => false,
        Some(mut st1) => {
            super::dpe::destroy_session_state(st1);
            let st_ = super::dpe::take_session_state(
                sid,
                super::dpe::session_state::SessionClosed,
            );
            true
        }
    }
}
pub fn init_engine_ctxt(
    uds: &mut [u8],
    p: (),
    uds_bytes: (),
) -> super::dpetypes::context_t {
    let mut uds_buf = vec![0; super::enginetypes::uds_len];
    super::pulse_lib_array::memcpy(
        super::enginetypes::uds_len,
        uds,
        &mut uds_buf,
        (),
        (),
        (),
    );
    let engine_context = super::dpetypes::mk_engine_context_t(uds_buf);
    let ctxt = super::dpetypes::mk_context_t_engine(engine_context);
    ctxt
}
pub fn init_l0_ctxt(
    cdi: &mut [u8],
    engine_repr: (),
    s: (),
    uds_bytes: (),
    uu___: (),
) -> super::dpetypes::context_t {
    let mut cdi_buf = vec![0; 32];
    super::pulse_lib_array::memcpy(32, cdi, &mut cdi_buf, (), (), ());
    let l0_context = super::dpetypes::mk_l0_context_t(cdi_buf);
    let ctxt = super::dpetypes::mk_context_t_l0(l0_context);
    ctxt
}
pub fn init_l1_ctxt(
    deviceIDCSR_len: usize,
    aliasKeyCRT_len: usize,
    deviceID_priv: &mut [u8],
    deviceID_pub: &mut [u8],
    aliasKey_priv: &mut [u8],
    aliasKey_pub: &mut [u8],
    deviceIDCSR: &mut [u8],
    aliasKeyCRT: &mut [u8],
    deviceID_label_len: (),
    aliasKey_label_len: (),
    cdi: (),
    repr: (),
    deviceIDCSR_ingredients: (),
    aliasKeyCRT_ingredients: (),
    deviceID_priv0: (),
    deviceID_pub0: (),
    aliasKey_priv0: (),
    aliasKey_pub0: (),
    deviceIDCSR0: (),
    aliasKeyCRT0: (),
) -> super::dpetypes::context_t {
    let mut deviceID_pub_buf = vec![0; 32];
    let mut deviceID_priv_buf = vec![0; 32];
    let mut aliasKey_priv_buf = vec![0; 32];
    let mut aliasKey_pub_buf = vec![0; 32];
    let mut deviceIDCSR_buf = vec![0; deviceIDCSR_len];
    let mut aliasKeyCRT_buf = vec![0; aliasKeyCRT_len];
    super::pulse_lib_array::memcpy(
        32,
        deviceID_priv,
        &mut deviceID_priv_buf,
        (),
        (),
        (),
    );
    super::pulse_lib_array::memcpy(32, deviceID_pub, &mut deviceID_pub_buf, (), (), ());
    super::pulse_lib_array::memcpy(
        32,
        aliasKey_priv,
        &mut aliasKey_priv_buf,
        (),
        (),
        (),
    );
    super::pulse_lib_array::memcpy(32, aliasKey_pub, &mut aliasKey_pub_buf, (), (), ());
    super::pulse_lib_array::memcpy(
        deviceIDCSR_len,
        deviceIDCSR,
        &mut deviceIDCSR_buf,
        (),
        (),
        (),
    );
    super::pulse_lib_array::memcpy(
        aliasKeyCRT_len,
        aliasKeyCRT,
        &mut aliasKeyCRT_buf,
        (),
        (),
        (),
    );
    let l1_context = super::dpetypes::mk_l1_context_t(
        deviceID_priv_buf,
        deviceID_pub_buf,
        aliasKey_priv_buf,
        aliasKey_pub_buf,
        aliasKeyCRT_buf,
        deviceIDCSR_buf,
    );
    let ctxt = super::dpetypes::mk_context_t_l1(l1_context);
    ctxt
}
pub fn prng(uu___: ()) -> u32 {
    panic!()
}
pub fn initialize_context(
    p: (),
    uds_bytes: (),
    sid: super::dpe::sid_t,
    uds: &mut [u8],
) -> std::option::Option<super::dpe::ctxt_hndl_t> {
    let st = super::dpe::take_session_state(sid, super::dpe::session_state::InUse);
    match st {
        None => None,
        Some(mut st1) => {
            match st1 {
                super::dpe::session_state::SessionStart => {
                    let ctxt = super::dpe::init_engine_ctxt(uds, (), ());
                    let ctxt_hndl = super::dpe::prng(());
                    let st_ = super::dpe::intro_session_state_perm_available(
                        ctxt,
                        ctxt_hndl,
                        (),
                    );
                    let st__ = super::dpe::take_session_state(sid, st_);
                    Some(ctxt_hndl)
                }
                _ => {
                    super::dpe::destroy_session_state(st1);
                    let st_ = super::dpe::take_session_state(
                        sid,
                        super::dpe::session_state::SessionError,
                    );
                    None
                }
            }
        }
    }
}
pub fn rotate_context_handle(
    sid: super::dpe::sid_t,
    ctxt_hndl: super::dpe::ctxt_hndl_t,
) -> std::option::Option<super::dpe::ctxt_hndl_t> {
    let st = super::dpe::take_session_state(sid, super::dpe::session_state::InUse);
    match st {
        None => None,
        Some(mut st1) => {
            match st1 {
                super::dpe::session_state::InUse => None,
                super::dpe::session_state::Available(mut st11) => {
                    let new_ctxt_hndl = super::dpe::prng(());
                    let st_ = super::dpe::intro_session_state_perm_available(
                        st11.context,
                        new_ctxt_hndl,
                        (),
                    );
                    let st__ = super::dpe::take_session_state(sid, st_);
                    Some(new_ctxt_hndl)
                }
                _ => {
                    let st_ = super::dpe::take_session_state(
                        sid,
                        super::dpe::session_state::SessionError,
                    );
                    None
                }
            }
        }
    }
}
pub fn intro_maybe_context_perm(
    c: super::dpetypes::context_t,
    __repr: (),
) -> std::option::Option<super::dpetypes::context_t> {
    Some(c)
}
pub fn derive_child_from_context(
    context: super::dpetypes::context_t,
    record: super::dpetypes::record_t,
    p: (),
    record_repr: (),
    context_repr: (),
) -> (
    super::dpetypes::context_t,
    super::dpetypes::record_t,
    std::option::Option<super::dpetypes::context_t>,
) {
    match context {
        super::dpetypes::context_t::Engine_context(mut c) => {
            match record {
                super::dpetypes::record_t::Engine_record(mut r) => {
                    let cdi = &mut [0; 32];
                    let ret = super::enginecore::engine_main(
                        cdi,
                        &mut c.uds,
                        r,
                        (),
                        (),
                        (),
                        (),
                        (),
                    );
                    let _bind_c = match ret.1 {
                        super::enginetypes::dice_return_code::DICE_SUCCESS => {
                            let l0_ctxt = super::dpe::init_l0_ctxt(cdi, (), (), (), ());
                            let l0_ctxt_opt = super::dpe::intro_maybe_context_perm(
                                l0_ctxt,
                                (),
                            );
                            let res = (
                                super::dpetypes::context_t::Engine_context(c),
                                super::dpetypes::record_t::Engine_record(ret.0),
                                l0_ctxt_opt,
                            );
                            res
                        }
                        super::enginetypes::dice_return_code::DICE_ERROR => {
                            super::pulse_lib_array::zeroize(32, cdi, ());
                            let res = (
                                super::dpetypes::context_t::Engine_context(c),
                                super::dpetypes::record_t::Engine_record(ret.0),
                                None,
                            );
                            res
                        }
                    };
                    let cdi1 = _bind_c;
                    cdi1
                }
                _ => {
                    let res = (
                        super::dpetypes::context_t::Engine_context(c),
                        record,
                        None,
                    );
                    res
                }
            }
        }
        super::dpetypes::context_t::L0_context(mut c) => {
            match record {
                super::dpetypes::record_t::L0_record(mut r) => {
                    let deviceIDCRI_len_and_ing = super::x509::len_of_deviceIDCRI(
                        r.deviceIDCSR_ingredients,
                    );
                    let deviceIDCSR_ingredients = deviceIDCRI_len_and_ing.0;
                    let deviceIDCRI_len = deviceIDCRI_len_and_ing.1;
                    let aliasKeyTBS_len_and_ing = super::x509::len_of_aliasKeyTBS(
                        r.aliasKeyCRT_ingredients,
                    );
                    let aliasKeyCRT_ingredients = aliasKeyTBS_len_and_ing.0;
                    let aliasKeyTBS_len = aliasKeyTBS_len_and_ing.1;
                    let deviceIDCSR_len = super::x509::length_of_deviceIDCSR(
                        deviceIDCRI_len,
                    );
                    let aliasKeyCRT_len = super::x509::length_of_aliasKeyCRT(
                        aliasKeyTBS_len,
                    );
                    let deviceID_pub = &mut [0; 32];
                    let deviceID_priv = &mut [0; 32];
                    let aliasKey_pub = &mut [0; 32];
                    let aliasKey_priv = &mut [0; 32];
                    let mut deviceIDCSR = vec![0; deviceIDCSR_len];
                    let mut aliasKeyCRT = vec![0; aliasKeyCRT_len];
                    let r1 = super::l0types::l0_record_t {
                        fwid: r.fwid,
                        deviceID_label_len: r.deviceID_label_len,
                        deviceID_label: r.deviceID_label,
                        aliasKey_label_len: r.aliasKey_label_len,
                        aliasKey_label: r.aliasKey_label,
                        deviceIDCSR_ingredients: deviceIDCSR_ingredients,
                        aliasKeyCRT_ingredients: aliasKeyCRT_ingredients,
                    };
                    let r2 = super::l0core::l0_main(
                        &mut c.cdi,
                        deviceID_pub,
                        deviceID_priv,
                        aliasKey_pub,
                        aliasKey_priv,
                        aliasKeyTBS_len,
                        aliasKeyCRT_len,
                        &mut aliasKeyCRT,
                        deviceIDCRI_len,
                        deviceIDCSR_len,
                        &mut deviceIDCSR,
                        r1,
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                    );
                    let l1_context = super::dpe::init_l1_ctxt(
                        deviceIDCSR_len,
                        aliasKeyCRT_len,
                        deviceID_priv,
                        deviceID_pub,
                        aliasKey_priv,
                        aliasKey_pub,
                        &mut deviceIDCSR,
                        &mut aliasKeyCRT,
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                        (),
                    );
                    drop(deviceIDCSR);
                    drop(aliasKeyCRT);
                    let l1_context_opt = super::dpe::intro_maybe_context_perm(
                        l1_context,
                        (),
                    );
                    let res = (
                        super::dpetypes::context_t::L0_context(c),
                        super::dpetypes::record_t::L0_record(r2),
                        l1_context_opt,
                    );
                    let aliasKey_priv1 = res;
                    let aliasKey_pub1 = aliasKey_priv1;
                    let deviceID_priv1 = aliasKey_pub1;
                    let deviceID_pub1 = deviceID_priv1;
                    deviceID_pub1
                }
                _ => {
                    let res = (super::dpetypes::context_t::L0_context(c), record, None);
                    res
                }
            }
        }
        super::dpetypes::context_t::L1_context(mut c) => {
            let res = (super::dpetypes::context_t::L1_context(c), record, None);
            res
        }
    }
}
pub fn derive_child(
    sid: super::dpe::sid_t,
    ctxt_hndl: super::dpe::ctxt_hndl_t,
    record: super::dpetypes::record_t,
    repr: (),
    p: (),
) -> (super::dpetypes::record_t, std::option::Option<super::dpe::ctxt_hndl_t>) {
    let st = super::dpe::take_session_state(sid, super::dpe::session_state::InUse);
    match st {
        None => {
            let res = (record, None);
            res
        }
        Some(mut st1) => {
            match st1 {
                super::dpe::session_state::InUse => {
                    let res = (record, None);
                    res
                }
                super::dpe::session_state::Available(mut st11) => {
                    let next_ctxt = super::dpe::derive_child_from_context(
                        st11.context,
                        record,
                        (),
                        (),
                        (),
                    );
                    super::dpe::destroy_ctxt(next_ctxt.0, ());
                    match next_ctxt.2 {
                        None => {
                            let st_ = super::dpe::take_session_state(
                                sid,
                                super::dpe::session_state::SessionError,
                            );
                            let res = (next_ctxt.1, None);
                            res
                        }
                        Some(mut next_ctxt1) => {
                            let next_ctxt_hndl = super::dpe::prng(());
                            let st_ = super::dpe::intro_session_state_perm_available(
                                next_ctxt1,
                                next_ctxt_hndl,
                                (),
                            );
                            let st__ = super::dpe::take_session_state(sid, st_);
                            let res = (next_ctxt.1, Some(next_ctxt_hndl));
                            res
                        }
                    }
                }
                _ => {
                    let st_ = super::dpe::take_session_state(
                        sid,
                        super::dpe::session_state::SessionError,
                    );
                    let res = (record, None);
                    res
                }
            }
        }
    }
}

