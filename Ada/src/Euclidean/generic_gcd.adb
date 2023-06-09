pragma Ada_2012;
package body Generic_GCD is

   ---------
   -- GCD --
   ---------

   function GCD (A, B : Euclidean_Ring) return Euclidean_Ring is
      G, Alpha, Beta : Euclidean_Ring;
   begin
      Gcd (A     => A,
           B     => B,
           Alpha => Alpha,
           Beta  => Beta,
           Gcd   => G);

      return G;
   end GCD;

   ---------
   -- GCD --
   ---------

   procedure GCD
     (A     : Euclidean_Ring;
      B     : Euclidean_Ring;
      Alpha : out Euclidean_Ring;
      Beta  : out Euclidean_Ring;
      Gcd   : out Euclidean_Ring)
   is
      --
      --  This implementation of the algorithm for the GCD employes
      --  a matrix with two rows and three columns that can be partitioned
      --  as a 2x2 matrix next to a column vector.  At the n-th iteration
      --  we have
      --
      --     | c_n  d_n  |  a_n  |
      --     | e_n  f_n  |  b_n  |
      --
      -- Call C_n the 2x2 matrix and v_n the column vector.
      --
      -- This matrix is initialized to
      --
      --     | 1  0 |  a  |
      --     | 0  1 |  b  |
      --
      --  that is, C_1 is the identiy and v_1 has the two parameters A and B.
      --  The algorithm acts on this matrix by left-multiplication by
      --  elementary operations (row swap and sum a row to the other).
      --  Therefore, it is easy to prove that at every iteration
      --
      --     C_n  v_1  = v_n                   (*)
      --
      --   At the end of the algorithm vector v will have zero in one
      --   component and the GCD in the other.  By using (*) it is easy
      --   to get Alpha and Beta from the final C matrix
      --
      type Status_Matrix is array (1 .. 2, 1 .. 3) of Euclidean_Ring;

      Status : Status_Matrix;

      -- Swap the rows of the status (surprised? I do not think so)
      procedure Swap_Rows (Status : in out Status_Matrix);

      -- Sum to the first row the second one multiplied by Coeff
      procedure Combine_Rows (Status : in out Status_Matrix;
                              Coeff  : Euclidean_Ring);

      procedure Swap_Rows (Status : in out Status_Matrix) is
         procedure Swap (A, B : in out Euclidean_Ring) is
            Tmp : Euclidean_Ring;
         begin
            Tmp := A;
            A := B;
            B := Tmp;
         end Swap;
      begin
         for Col in Status'Range (2) loop
            Swap (Status (1, Col), Status (2, Col));
         end loop;
      end Swap_Rows;

      procedure Combine_Rows (Status : in out Status_Matrix;
                              Coeff  : Euclidean_Ring) is
      begin
         for Col in Status'Range (2) loop
            Status (1, Col) := Status (1, Col) + Coeff * Status (2, Col);
         end loop;
      end Combine_Rows;

      -- Syntactic sugar for the first component of v
      function Top (Status : Status_Matrix) return Euclidean_Ring
      is (Status (1, 3));

      -- Syntactic sugar for the second component of v
      function Bottom (Status : Status_Matrix) return Euclidean_Ring
      is (Status (2, 3));

      -- At (almost) every time of the algorithm the degree of the first
      -- compoent of v is not smaller than the degree of the second
      -- component.  This function checks that this is true.
      function Is_Ordered (Status : Status_Matrix) return Boolean
      is (Degree (Top (Status)) >= Degree (Bottom (Status)));

      -- Return true if (*) above is true
      function Is_Coherent (Status : Status_Matrix) return Boolean
      is (for all Row in 1 .. 2 =>
             Status (Row, 3)  = Status (Row, 1) * A + Status (Row, 2) * B)
        with Ghost;

      procedure GCD_Step (Status : in out Status_Matrix)
        with
          Pre =>
            Is_Coherent (Status) and
            Is_Ordered (Status) and
            Bottom (Status) /= Zero,
            Post =>
              Is_Coherent (Status) and
              Is_Ordered (Status) and
              Degree (Bottom (Status)) < Degree (Bottom (Status'Old));

      procedure GCD_Step (Status : in out Status_Matrix)
      is
         M : constant Euclidean_Ring := Top (Status) mod Bottom (Status);

         Quotient : constant Euclidean_Ring :=
                      (Top (Status) + (-M)) / Bottom (Status);
      begin
         pragma Assert
           (Top (Status) = Quotient * Bottom (Status) + M and
                Degree (M) < Degree (Bottom (Status)));

         Combine_Rows (Status, -Quotient);

         pragma Assert (Top (Status) = M);

         Swap_Rows (Status);
      end GCD_Step;

   begin
      if A = Zero or B = Zero then
         raise Constraint_Error;
      end if;

      Status := (1 => (One, Zero, A),
                 2 => (Zero, One, B));

      if not Is_Ordered (Status) then
         --  The rows are not correctly ordered: swap them
         Swap_Rows (Status);
      end if;

      pragma Assert (Is_Coherent (Status) and Is_Ordered (Status));


      while Bottom (Status) /= Zero loop
         pragma Loop_Invariant (Is_Ordered (Status) and Is_Coherent (Status));
         pragma Loop_Variant (Decreases => Degree (Bottom (Status)));

         GCD_Step (Status);
      end loop;

      pragma Assert (Is_Coherent (Status) and Bottom (Status) = Zero);

      Alpha := Status (1, 1);
      Beta  := Status (1, 2);
      Gcd   := Top (Status);
   end GCD;

   function Inv_Mod (X       : Euclidean_Ring;
                     Modulus : Euclidean_Ring) return Euclidean_Ring
   is
      Is_Unit : Boolean;
   begin
      return Inverse : Euclidean_Ring do

         Inv_Mod (X       => X,
                  Modulus => Modulus,
                  Inverse => Inverse,
                  Is_Unit => Is_Unit);

         if not Is_Unit then
            raise Constraint_Error;
         end if;

      end return;
   end Inv_Mod;

   function Is_Unit_Mod (X       : Euclidean_Ring;
                         Modulus : Euclidean_Ring)
                         return Boolean
   is
      Ignored : Euclidean_Ring;
      Is_Unit : Boolean;
   begin
      if X = Zero then
         return False;
      end if;

      Inv_Mod (X       => X,
               Modulus => Modulus,
               Inverse => Ignored,
               Is_Unit => Is_Unit);

      return Is_Unit;
   end Is_Unit_Mod;


   procedure Inv_Mod (X       : Euclidean_Ring;
                      Modulus : Euclidean_Ring;
                      Inverse : out Euclidean_Ring;
                      Is_Unit : out Boolean)
   is
      Alpha, Beta, G : Euclidean_Ring;
   begin
      if X = Zero then
         Is_Unit := False;
         return;
      end if;

      Gcd (A     => X,
           B     => Modulus,
           Alpha => Alpha,
           Beta  => Beta,
           Gcd   => G);

      if Generic_GCD.Is_Unit (G) then
         --
         --  Why do we check that G is a unit and not just One?
         --  Remember that the GCD is defined modulo the product by a unit
         --  therefore, there is no guarantee that G will be One if X
         --  and Modulus are relatively prime, but we know that it will
         --  be a unit.
         --
         Is_Unit := True;
         Inverse := Alpha / G;

      else
         Is_Unit := False;
      end if;
   end Inv_Mod;

end Generic_GCD;
