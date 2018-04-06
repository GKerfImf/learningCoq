Require Import Coq.Init.Datatypes.
Set Implicit Arguments.

Require Import List.
Import ListNotations.

Module TypeClasses.

  Definition id {A} (x: A) := x.

  Reserved Notation "f (.) g" (at level 70, right associativity). (* TODO: associativity *)
  Definition compose {A B C} (f: B -> C) (g: A -> B) := fun x => f (g x).
  Infix "(.)" := compose .

  Reserved Notation "f [=] g" (at level 70, no associativity).
  Definition extensional_equivalence {A B} (f g: A -> B) := forall x, f x = g x.
  Infix "[=]" := extensional_equivalence.

  Inductive identity {A: Type}: Type := Ident: A -> @identity A.
  (* Inductive composition {F: Type -> Type} {G: Type -> Type} := Comp: forall X, X -> omposition F G. *)

(*  Print option.
  Print identity.
  *)
  (*  Notation ...
  Definition compose f g = ... *)
  
  (* TODO: add compose *)
  
  (* TODO: Comment *)
  Class Functor (F: Type -> Type) :=
    { fmap: forall {A B}, (A -> B) -> (F A -> F B)
      ; fmap_id: forall {A}, @fmap A _ id [=] id
      ; fmap_comp: forall {A B C} (f: B -> C) (g: A -> B),
          fmap (f(.) g) [=] ((fmap f) (.) (fmap g))
    }.

  (*  (* TOOD: comment *)
  Class Contravariant (F: Type -> Type) :=
    { cmap: forall {A B}, (A -> B) -> (F B -> F A)
      ; _: True
    }.

  (* Invariant Functor *)
  Class Invariant (F: Type -> Type) :=
    { imap: forall {A B}, (B -> A) -> (A -> B) -> (F A -> F B)
      ; _: True
    }.

  (* Profunctor *) (* Instance: (->) *)
  Class Profunctor (F: Type -> Type -> Type) :=
    { dimap: forall {A B C D}, (A -> B) -> (C -> D) -> (F B C) -> (F A D)
      ; _: True
    }.
   *)
  

  Section Applicative.
    
    Reserved Notation "x <*> y" (at level 50, left associativity). 
    
    Class Applicative (F: Type -> Type) :=
      { functor :> Functor F
        ; pure: forall {A}, A -> F A
        ; app: forall {A B: Type}, F (A -> B) -> F A -> F B where "n <*> m" := (app n m)
        ; _: forall {A} (v: F A), pure id <*> v = v
        ; _: forall {A B} (f: A -> B) (x: A), pure f <*> pure x = pure (f x)
        ; _: forall {A B} (u: F(A -> B)) (y: A),
            (u <*> pure y) = (pure (fun f => f y) <*> u)
        ; _: forall {A B C} (u: F (B -> C)) (v: F (A -> B)) w,
            u <*> (v <*> w) = pure compose <*> u <*> v <*> w
      }.
    
  End Applicative.
  
  Section Monad.

    Reserved Notation "x >>= y" (at level 70).

    Class Monad (M: Type -> Type) :=
      { applicative :> Applicative M
        ; unit: forall {A}, A -> M A
        ; bind: forall {A B}, (M A) -> (A -> M B) -> M B where "n >>= m" := (bind n m)
        ; _: forall {A B: Type} (a: A) (k: A -> M B),
            (unit a) >>= k = k a
        ; _: forall {A} (m: M A), m >>= unit = m
        ; _: forall  {A B C} (m: M A) (k: A -> M B) (h: B -> M C),
            (m >>= (fun x => k x >>= h)) = ((m >>= k) >>= h)
      }.
    
  End Monad.

(*  Section Transformers.

    Class MonadTrans (M: Type -> Type) (T: _) :=
      { monadM :> Monad M
        ; monadTM :> Monad (T M)
        ; lift: forall {A}, M A -> (T M) A
        ; _: (lift (.) unit) [=] unit
        ; _: True
      }.

    Instance j : (MonadTrans 2) := n.
    
  End Transformers. *)

  Section Monoid.

    Class Monoid (M: Type) :=
      { mempty: M
        ; mappend: M -> M -> M
        ; _: forall x, mappend mempty x = x
        ; _: forall x, mappend x mempty = x
        ; _: forall x y z, mappend (mappend x y) z = mappend x (mappend y z)
      }.
        
  End Monoid.
  
  Section Foldable.

    Class Foldable (T: Type -> Type) :=
      { foldMap: forall {M} `{! Monoid M} a,  (a -> M) -> T a -> M }.
    
  End Foldable.
  
  Section Traversable.

    Class ApplicativeTransformation
          {T} `{! Applicative T}
          {F} `{! Applicative F} (t: forall {A}, T A -> F A) :=
      { 
         _: forall {A} (x: A),
          t (pure x) = pure x
        ; _: forall {A B: Type} (x:_ ) (y: _),
            t (app x y) = @app F _ A B (t x) (t y)
      }.
 

    Instance identity_functor: (Functor (@identity)) :=
      { fmap A B f a := 
          match a with
          | Ident a => Ident (f a)
          end
      }.
    Proof.
      { intros A a; destruct a; reflexivity. }
      { intros ? ? ? ? ? ?; destruct x; reflexivity. }
    Defined.

    Instance identity_applicative: (Applicative (@identity)) :=
      { pure A a := Ident a
        ; app A B f a :=
            match f, a with
            | Ident f, Ident a => Ident (f a)
            end
      }.
    Proof.
      { intros; destruct v; reflexivity. } 
      { intros; reflexivity. }
      { intros; destruct u; reflexivity.  }
      { intros; destruct u, v, w; reflexivity. }
    Defined.    
      
  
     Class Traversable (T: Type -> Type) :=
      { functorTraversable :> Functor T 
        ; foldableTraversable :> Foldable T
        ; traverse: forall {A} {B} {F} `{! Applicative F},
            (A -> F B) -> T A -> F (T B)
        (* ; _: traverse (Compose.fmap g . f) =Compose . fmap (traverse g) . traverse f *)

        ; _: forall (A B: Type) (F: Type -> Type) `{Applicative F} 
                    (f: A -> F B) (t: forall {A}, F A -> F A)
                    `{! ApplicativeTransformation (@t)},
            (* `{! ApplicativeTransformation t} *)
            
            ((t (.) (traverse f))) [=] ((traverse (t (.) f))) 

        ; _: forall {A: Type}, (@traverse A _ _ _ (Ident)) [=] Ident
        ; _: True
      }.


    Instance option_functor: (Functor option) :=
      { fmap A B f a :=
          match a with
          | None => None
          | Some a => Some (f a)
          end
      }.
    Proof.
      intros. intros x. destruct x; reflexivity.
      intros. intros x. 
      compute. destruct x; reflexivity.
    Defined.

    Instance list_functor: (Functor list) :=
      { fmap A B f a := map f a }.
    Proof.
      { intros A xs.
        induction xs.
        - reflexivity.
        - simpl; rewrite IHxs; compute; reflexivity.
      }
      { intros ? ? ? ? ? xs; unfold compose.
        induction xs.
        - reflexivity.
        - simpl; rewrite IHxs; compute; reflexivity.
      }
    Defined.
    
    Instance option_applicative: (Applicative option) :=
      { pure {A} (x: A) := Some x
        ; app {A B} f x :=
            match f, x with
            | Some f, Some x => Some (f x)
            | _, _ => None
            end
      }.
    Proof.
      - intros; destruct v; reflexivity.
      - intros; reflexivity. 
      - intros; destruct u; reflexivity.
      - intros; destruct u, v, w; reflexivity.
    Defined.
    
    Instance option_traversable: (Traversable option) :=
      { traverse {A B} {F} _ (f: A -> F B) (some: option A) := 
          match some with
          | None => pure None : F (option B)
          | Some x => app (pure (Some ) ) (f x) : F (option B)
          end
      }.
    Proof.
      { admit. }
      { intros ? ? ? ? ? ? ? ?; destruct x; unfold compose.
        - destruct ApplicativeTransformation0.
          rewrite H1, H0; reflexivity. 
        - destruct ApplicativeTransformation0; eauto.
      }
      { intros ? ?; destruct x; reflexivity. } 
      {  }
    Defined.
       
  End Traversable.
  
  Section Option.
    
    
    Instance option_monad: (Monad option) :=
      { unit A a := Some a;
        bind A B a f :=
          match a with
          | Some a => f a
          | _ => None
          end
      }.
    Proof.
      all: intros.
      - reflexivity.
      - destruct m; reflexivity.
      - destruct m; try destruct (k a); reflexivity.
    Defined.


  End Option.

  Goal
    forall m,
      Monad m ->
      Applicative m
  .
  Proof.
    intros. 
    destruct Monad.

    
End TypeClasses.