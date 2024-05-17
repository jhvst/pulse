(*
   Copyright 2023 Microsoft Research

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)

module L0Core

open Pulse.Lib.Pervasives
open L0Types

module G = FStar.Ghost
module U8 = FStar.UInt8
module U32 = FStar.UInt32
module A = Pulse.Lib.Array

val l0_post
  (cdi_repr fwid_repr:Seq.seq U8.t)
  (deviceID_label_len:U32.t)
  (deviceID_label_repr:Seq.seq U8.t)
  (aliasKey_label_len:U32.t)
  (aliasKey_label_repr:Seq.seq U8.t)
  (deviceIDCSR_ingredients:deviceIDCSR_ingredients_t)
  (aliasKeyCRT_ingredients:aliasKeyCRT_ingredients_t)
  (deviceID_pub_repr aliasKey_pub_repr aliasKey_priv_repr:Seq.seq U8.t)
  (deviceIDCSR_len:(n:U32.t { valid_deviceIDCSR_ingredients deviceIDCSR_ingredients n }))
  (deviceIDCSR_buf_repr:Seq.seq U8.t)
  (aliasKeyCRT_len:(n:U32.t { valid_aliasKeyCRT_ingredients aliasKeyCRT_ingredients n }))
  (aliasKeyCRT_buf_repr:Seq.seq U8.t)
  : prop


val l0
  (cdi:A.larray U8.t 32)
  (fwid:A.larray U8.t 32)
  (deviceID_label_len:(n:U32.t { valid_hkdf_lbl_len n }))
  (deviceID_label:A.larray U8.t (U32.v deviceID_label_len))
  (aliasKey_label_len:(n:U32.t { valid_hkdf_lbl_len n }))
  (aliasKey_label:A.larray U8.t (U32.v aliasKey_label_len))
  (deviceIDCSR_ingredients:deviceIDCSR_ingredients_t)
  (aliasKeyCRT_ingredients:aliasKeyCRT_ingredients_t)
  (deviceID_pub:A.larray U8.t 32)
  (aliasKey_pub:A.larray U8.t 32)
  (aliasKey_priv:A.larray U8.t 32)
  (deviceIDCSR_len:(n:U32.t { valid_deviceIDCSR_ingredients deviceIDCSR_ingredients n }))
  (deviceIDCSR_buf:A.larray U8.t (U32.v deviceIDCSR_len))
  (aliasKeyCRT_len:(n:U32.t { valid_aliasKeyCRT_ingredients aliasKeyCRT_ingredients n }))
  (aliasKeyCRT_buf:A.larray U8.t (U32.v aliasKeyCRT_len))

  (#cdi_repr:G.erased (Seq.seq U8.t))
  (#fwid_repr:G.erased (Seq.seq U8.t))
  (#deviceID_label_repr:G.erased (Seq.seq U8.t))
  (#aliasKey_label_repr:G.erased (Seq.seq U8.t))
  (#deviceID_pub_repr:G.erased (Seq.seq U8.t))
  (#aliasKey_pub_repr:G.erased (Seq.seq U8.t))
  (#aliasKey_priv_repr:G.erased (Seq.seq U8.t))
  (#deviceIDCSR_buf_repr:G.erased (Seq.seq U8.t))
  (#aliasKeyCRT_buf_repr:G.erased (Seq.seq U8.t))

  : stt unit
      (requires
         A.pts_to cdi cdi_repr **
         A.pts_to fwid fwid_repr **
         A.pts_to deviceID_label deviceID_label_repr **
         A.pts_to aliasKey_label aliasKey_label_repr **
         A.pts_to deviceID_pub deviceID_pub_repr **
         A.pts_to aliasKey_pub aliasKey_pub_repr **
         A.pts_to aliasKey_priv aliasKey_priv_repr **
         A.pts_to deviceIDCSR_buf deviceIDCSR_buf_repr **
         A.pts_to aliasKeyCRT_buf aliasKeyCRT_buf_repr)
      (ensures fun _ ->
         A.pts_to cdi cdi_repr **
         A.pts_to fwid fwid_repr **
         A.pts_to deviceID_label deviceID_label_repr **
         A.pts_to aliasKey_label aliasKey_label_repr **
         (exists* deviceID_pub_repr aliasKey_pub_repr aliasKey_priv_repr deviceIDCSR_buf_repr aliasKeyCRT_buf_repr.
            A.pts_to deviceID_pub deviceID_pub_repr **
            A.pts_to aliasKey_pub aliasKey_pub_repr **
            A.pts_to aliasKey_priv aliasKey_priv_repr **
            A.pts_to deviceIDCSR_buf deviceIDCSR_buf_repr **
            A.pts_to aliasKeyCRT_buf aliasKeyCRT_buf_repr **
            pure (l0_post
              cdi_repr
              fwid_repr
              deviceID_label_len
              deviceID_label_repr
              aliasKey_label_len
              aliasKey_label_repr
              deviceIDCSR_ingredients
              aliasKeyCRT_ingredients
              deviceID_pub_repr
              aliasKey_pub_repr
              aliasKey_priv_repr
              deviceIDCSR_len
              deviceIDCSR_buf_repr
              aliasKeyCRT_len
              aliasKeyCRT_buf_repr)))
