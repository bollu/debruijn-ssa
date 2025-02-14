import DeBruijnSSA.BinSyntax.Syntax.Subst
import DeBruijnSSA.BinSyntax.Syntax.Rewrite

namespace BinSyntax

namespace Region

variable [Φ: EffectSet φ ε] [SemilatticeSup ε] [OrderBot ε]

def lsubst0 (r : Region φ) : Subst φ
  | 0 => r
  | ℓ + 1 => br ℓ (Term.var 0)

def alpha (ℓ : ℕ) (r : Region φ) : Subst φ
  := Function.update Subst.id ℓ r

def ret (e : Term φ) := br 0 e

def nil : Region φ := ret (Term.var 0)

@[simp]
theorem nil_vwk1 : nil.vwk1 = @nil φ := rfl

@[simp]
theorem alpha0_nil : alpha 0 nil = @Subst.id φ := by
  rw [alpha, Function.update_eq_self_iff]
  rfl

theorem vlift_alpha (n : ℕ) (r : Region φ) : (alpha n r).vlift = alpha n r.vwk1 := by
  simp only [Subst.vlift, alpha, Function.comp_update]
  rfl

theorem vliftn_alpha (n m : ℕ) (r : Region φ) : (alpha n r).vliftn m = alpha n (r.vwk (Nat.liftWk (· + m))) := by
  simp only [Subst.vliftn, alpha, Function.comp_update]
  rfl

theorem lift_alpha (n) (r : Region φ) : (alpha n r).lift = alpha (n + 1) (r.lwk Nat.succ) := by
  funext i; cases i; rfl;
  simp only [Subst.lift, alpha, Function.update, eq_rec_constant, Subst.id, dite_eq_ite,
    add_left_inj]
  split <;> rfl

theorem liftn_alpha (n m) (r : Region φ) : (alpha n r).liftn m = alpha (n + m) (r.lwk (· + m)) := by
  rw [Subst.liftn_eq_iterate_lift]
  induction m generalizing n r with
  | zero => simp
  | succ m I =>
    simp only [Function.iterate_succ, Function.comp_apply, lift_alpha, I, lwk_lwk]
    apply congrArg₂
    simp_arith
    apply congrFun
    apply congrArg
    funext i
    simp_arith

def append (r r' : Region φ) : Region φ := r.lsubst (r'.vwk1.alpha 0)

instance : Append (Region φ) := ⟨Region.append⟩

theorem append_def (r r' : Region φ) : r ++ r' = r.lsubst (r'.vwk1.alpha 0) := rfl

@[simp]
theorem append_nil (r : Region φ) : r ++ nil = r := by simp [append_def]

@[simp]
theorem nil_append (r : Region φ) : nil ++ r = r := by
  simp only [append_def, lsubst, Subst.vlift, vwk1, alpha, Function.comp_apply, Function.update_same]
  rw [<-vsubst_fromWk_apply, <-vsubst_comp_apply, <-vsubst_id r]
  congr <;> simp

theorem lsubst_alpha_let1 (k) (e : Term φ) (r r' : Region φ)
  : (r.let1 e).lsubst (r'.alpha k) = (r.lsubst (r'.vwk1.alpha k)).let1 e
  := by simp [vlift_alpha]

theorem let1_append (e : Term φ) (r r' : Region φ) : r.let1 e ++ r' = (r ++ r'.vwk1).let1 e
  := lsubst_alpha_let1 0 e _ _

theorem lsubst_alpha_let2 (k) (e : Term φ) (r r' : Region φ)
  : (r.let2 e).lsubst (r'.alpha k) = (r.lsubst ((r'.vwk (Nat.liftWk (· + 2))).alpha k)).let2 e
  := by simp only [append_def, lsubst, vlift_alpha, vliftn_alpha, vwk_vwk, vwk1, ← Nat.liftWk_comp]

theorem let2_append (e : Term φ) (r r' : Region φ) : r.let2 e ++ r' = (r ++ (r'.vwk (Nat.liftWk (· + 2)))).let2 e
  := by
  simp only [append_def, lsubst, vlift_alpha, vliftn_alpha, vwk_vwk, vwk1, ← Nat.liftWk_comp]
  rfl

theorem lsubst_alpha_case (k) (e : Term φ) (s t r : Region φ)
  : (case e s t).lsubst (r.alpha k) = (case e (s.lsubst (r.vwk1.alpha k)) (t.lsubst (r.vwk1.alpha k)))
  := by
  simp only [append_def, lsubst, vlift_alpha, vwk_vwk, vwk1, ← Nat.liftWk_comp]

theorem case_append (e : Term φ) (s t r : Region φ) : case e s t ++ r = case e (s ++ r.vwk1) (t ++ r.vwk1)
  := by simp only [append_def, lsubst, vlift_alpha, vwk_vwk, vwk1, ← Nat.liftWk_comp]

theorem lsubst_alpha_cfg (β n G k) (r : Region φ)
  : (cfg β n G).lsubst (r.alpha k) = cfg
    (β.lsubst ((r.lwk (· + n)).alpha (k + n))) n
    (lsubst ((r.lwk (· + n)).vwk1.alpha (k + n)) ∘ G)
  := by
  simp only [append_def, lsubst, vlift_alpha, vwk_vwk, vwk1, ← Nat.liftWk_comp, liftn_alpha]
  rfl

-- Note: we need this auxiliary definition because recursion otherwise won't work, since the equation compiler
-- can't tell that toEStep Γ {r₀, r₀'} is just {r₀, r₀'}
-- def EStep.lsubst_alpha' (Γ : ℕ → ε) {r₀ r₀'}
--   (p : SimpleCongruenceD (PStepD Γ) r₀ r₀') (n) (r₁ : Region φ)
--   : Quiver.Path (toEStep Γ (r₀.lsubst (alpha n r₁))) (toEStep Γ (r₀'.lsubst (alpha n r₁))) :=
--   match r₀, r₀', p with
--   | _, _, SimpleCongruenceD.step s => sorry
--   | _, _, SimpleCongruenceD.let1 e p => by
--     simp only [lsubst_alpha_let1]
--     apply EStep.let1_path e
--     apply lsubst_alpha' _ p
--   | _, _, SimpleCongruenceD.let2 e p => by
--     simp only [lsubst_alpha_let2]
--     apply EStep.let2_path e
--     apply lsubst_alpha' _ p
--   | _, _, SimpleCongruenceD.case_left e p t => by
--     simp only [lsubst_alpha_case]
--     apply EStep.case_left_path e
--     apply lsubst_alpha' _ p
--   | _, _, SimpleCongruenceD.case_right e s p => by
--     simp only [lsubst_alpha_case]
--     apply EStep.case_right_path e
--     apply lsubst_alpha' _ p
--   | _, _, SimpleCongruenceD.cfg_entry p n G => by
--     simp only [lsubst_alpha_cfg]
--     apply EStep.cfg_entry_path
--     apply lsubst_alpha' _ p
--   | _, _, SimpleCongruenceD.cfg_block β n G i p => by
--     simp only [lsubst_alpha_cfg, Function.comp_update]
--     apply EStep.cfg_block_path
--     apply lsubst_alpha' _ p

-- def EStep.lsubst_alpha (Γ : ℕ → ε) {r₀ r₀'}
--   (p : toEStep Γ r₀ ⟶ toEStep Γ r₀') (n) (r₁ : Region φ)
--   : Quiver.Path (toEStep Γ (r₀.lsubst (alpha n r₁))) (toEStep Γ (r₀'.lsubst (alpha n r₁)))
--   := EStep.lsubst_alpha' Γ p n r₁

-- -- def EStep.append_right (Γ : ℕ → ε) {r₀ r₀'}
-- --   (p : toEStep Γ r₀ ⟶ toEStep Γ r₀') (r₁ : Region φ) : toEStep Γ (r₀ ++ r₁) ⟶ toEStep Γ (r₀ ++ r₁')
-- --   := match r₀, p with
-- --   | _, SimpleCongruenceD.step s => sorry
-- --   | _, SimpleCongruenceD.let1 e p => sorry--SimpleCongruenceD.let1 e (EStep.append_right Γ p r₁)
-- --   | _, SimpleCongruenceD.let2 e p => sorry
-- --   | _, SimpleCongruenceD.case_left e p t => sorry
-- --   | _, SimpleCongruenceD.case_right e s p => sorry
-- --   | _, SimpleCongruenceD.cfg_entry p n G => sorry
-- --   | _, SimpleCongruenceD.cfg_block β n G i p => sorry

-- def EStep.append_path_right (Γ : ℕ → ε) {r₀ r₀'} (p : Quiver.Path (toEStep Γ r₀) (toEStep Γ r₀')) (r₁ : Region φ)
--   : Quiver.Path (toEStep Γ (r₀ ++ r₁)) (toEStep Γ (r₀ ++ r₁'))
--   := sorry

-- TODO: ret append ret should be alpha0 or smt...

@[simp]
theorem Subst.vwk_liftWk_comp_id : vwk (Nat.liftWk ρ) ∘ id = @id φ := rfl

@[simp]
theorem Subst.vwk_liftnWk_comp_id (n : ℕ) : vwk (Nat.liftnWk (n + 1) ρ) ∘ id = @id φ := by
  rw [Nat.liftnWk_succ']
  rfl

theorem append_assoc (r r' r'' : Region φ) : (r ++ r') ++ r'' = r ++ (r' ++ r'')
  := by
  simp only [append_def, lsubst_lsubst]
  congr
  funext ℓ
  simp only [
    Subst.comp, Subst.vlift, vwk1, alpha, Function.comp_apply, Function.comp_update,
    Subst.vwk_liftWk_comp_id, vwk_vwk
  ]
  cases ℓ with
  | zero =>
    simp only [
      Function.update_same, vwk_lsubst, Function.comp_update, Subst.vwk_liftWk_comp_id, vwk_vwk]
    apply congrFun
    apply congrArg
    apply congrArg
    congr
    funext n
    cases n <;> rfl
  | succ => rfl

def lappend (r r' : Region φ) : Region φ := r ++ r'.let1V0

instance : ShiftRight (Region φ) := ⟨Region.lappend⟩

theorem lappend_def (r r' : Region φ) : r >>> r' = r ++ r'.let1V0 := rfl

theorem lappend_nil (r : Region φ) : r >>> nil = r ++ nil.let1V0 := rfl

-- def EStep.lappend_nil_id (Γ : ℕ → ε) (r : Region φ) : Quiver.Path (toEStep Γ (r >>> nil)) (toEStep Γ r)
--   := sorry

theorem nil_lappend (r : Region φ) : nil >>> r = r.let1V0 := nil_append _

def wappend (r r' : Region φ) : Region φ := cfg r 1 (λ_ => r'.lwk Nat.succ)

theorem wappend_def (r r' : Region φ) : r.wappend r' = cfg r 1 (λ_ => r'.lwk Nat.succ) := rfl

theorem wappend_nil (r : Region φ) : r.wappend nil = cfg r 1 (λ_ => br 1 (Term.var 0)) := rfl

theorem nil_wappend (r : Region φ) : nil.wappend r = cfg nil 1 (λ_ => r.lwk Nat.succ) := rfl

def Subst.left_label_distrib (e : Term φ) : Subst φ
  := λℓ => br ℓ (Term.pair (e.wk Nat.succ) (Term.var 0))

def Subst.right_label_distrib (e : Term φ) : Subst φ
  := λℓ => br ℓ (Term.pair (Term.var 0) (e.wk Nat.succ))

def left_label_distrib (r : Region φ) (e : Term φ) : Region φ
  := r.lsubst (Subst.left_label_distrib e)

def right_label_distrib (r : Region φ) (e : Term φ) : Region φ
  := r.lsubst (Subst.right_label_distrib e)

def left_distrib (r : Region φ) : Region φ
  := ((r.vwk Nat.succ).left_label_distrib (Term.var 0)).let2 (Term.var 0)

def right_distrib (r : Region φ) : Region φ
  := ((r.vwk (Nat.liftWk Nat.succ)).right_label_distrib (Term.var 1)).let2 (Term.var 0)

-- TODO: label threading vs. distribution, equal if fvi ≤ 1

def associator : Region φ :=
  let2 (Term.var 0) $
  let2 (Term.var 0) $
  ret (Term.pair (Term.var 0) (Term.pair (Term.var 1) (Term.var 2)))

def associator_inv : Region φ :=
  let2 (Term.var 0) $
  let2 (Term.var 1) $
  ret (Term.pair (Term.pair (Term.var 2) (Term.var 0)) (Term.var 1))

def proj_left : Region φ :=
  let2 (Term.var 0) $
  ret (Term.var 0)

def proj_right : Region φ :=
  let2 (Term.var 0) $
  ret (Term.var 1)

def left_unitor_inv : Region φ := ret (Term.pair Term.unit (Term.var 0))

def right_unitor_inv : Region φ := ret (Term.pair (Term.var 0) Term.unit)

def inl : Region φ := ret (Term.var 0).inl

def inr : Region φ := ret (Term.var 0).inr

def swap : Region φ :=
  let2 (Term.var 0) $
  ret (Term.pair (Term.var 1) (Term.var 0))

def let_eta : Region φ :=
  let1 (Term.var 0) $
  ret (Term.var 0)

def let2_eta : Region φ :=
  let2 (Term.var 0) $
  ret (Term.pair (Term.var 0) (Term.var 1))

def case_eta : Region φ := case (Term.var 0) (ret (Term.var 0).inl) (ret (Term.var 0).inr)

def drop : Region φ :=
  let1 (Term.var 0) $
  ret Term.unit

def join (r r' : Region φ) : Region φ := case (Term.var 0)
  (r.vwk (Nat.liftWk Nat.succ))
  (r'.lwk (Nat.liftWk Nat.succ))

def abort : Region φ := ret (Term.var 0).abort

def left_distributor : Region φ :=
  case (Term.var 0)
    (ret (Term.pair (Term.var 0) (Term.var 2).inl))
    (ret (Term.pair (Term.var 0) (Term.var 2).inr))

def left_distributor_inv : Region φ :=
  let2 (Term.var 0) $
  case (Term.var 1)
    (ret (Term.pair (Term.var 0) (Term.var 1)))
    (ret (Term.pair (Term.var 0) (Term.var 1)))

def right_distributor : Region φ :=
  case (Term.var 0)
    (ret (Term.pair (Term.var 2).inl (Term.var 0)))
    (ret (Term.pair (Term.var 2).inr (Term.var 0)))

def right_distributor_inv : Region φ :=
  let2 (Term.var 0) $
  case (Term.var 0)
    (ret (Term.pair (Term.var 2) (Term.var 0)))
    (ret (Term.pair (Term.var 2) (Term.var 0)))

def swap_sum : Region φ := case (Term.var 0) (ret (Term.var 0).inr) (ret (Term.var 0).inl)

def right_exit : Region φ :=
  case (Term.var 0)
    (br 0 (Term.var 0))
    (br 1 (Term.var 0))

def left_exit : Region φ :=
  case (Term.var 0)
    (br 1 (Term.var 0))
    (br 0 (Term.var 0))

def fixpoint (r : Region φ) : Region φ := cfg nil 1 (λ_ => r ++ left_exit)

def ite (b : Term φ) (r r' : Region φ) : Region φ := case b (r.vwk Nat.succ) (r'.vwk Nat.succ)

end Region

end BinSyntax
