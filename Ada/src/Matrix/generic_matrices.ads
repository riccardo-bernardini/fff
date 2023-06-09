with Ada.Containers.Vectors;
with Element_Printers;

--
-- This package provides functions for working with matrices with entries
-- in a ring.
--
generic
   type Ring_Type is private;

   Ring_Zero : Ring_Type;
   Ring_One  : Ring_Type;

   with function "+" (X, Y : Ring_Type) return Ring_Type is <>;
   with function "-" (X : Ring_Type) return Ring_Type is <>;
   with function "*" (X, Y : Ring_Type) return Ring_Type is <>;
package Generic_Matrices is
   type Matrix is tagged private
     with
       Constant_Indexing => Value,
       Variable_Indexing => Reference;

   subtype Index_Type is Positive;

   function N_Rows (X : Matrix) return Positive;
   function N_Cols (X : Matrix) return Positive;

   subtype Column_Vector is Matrix
     with
       Dynamic_Predicate => Column_Vector.N_Cols = 1;

   subtype Row_Vector is Matrix
     with
       Dynamic_Predicate => Row_Vector.N_Rows = 1;

   subtype Square_Matrix is Matrix
     with
       Dynamic_Predicate => Square_Matrix.N_Rows = Square_Matrix.N_Cols;

   function Empty_Matrix return Matrix;

   function Total_Size (X : Matrix) return Natural
   is (X.N_Rows * X.N_Cols);

   function Is_Empty (X : Matrix) return Boolean
   is (X.Total_Size = 0);

   function Is_Vector (X : Matrix) return Boolean
   is (X.N_Rows = 1 or X.N_Cols = 1);

   function Is_Column_Vector (X : Matrix) return Boolean
   is (X.N_Cols = 1);

   function Is_Row_Vector (X : Matrix) return Boolean
   is (X.N_Rows = 1);

   function Length (X : Matrix) return Positive
   is (Positive'Max (X.N_Rows, X.N_Cols));

   --
   -- Indexing function with a single index.  X must be a vector
   --
   function Value (X : Matrix; N : Index_Type) return Ring_Type
     with
       Pre => X.Is_Vector and X.Length >= N;


   --
   -- Indexing function with two indeces
   --
   function Value (X : Matrix; Row, Col : Index_Type) return Ring_Type
     with
       Pre => Row <= X.N_Rows and Col <= X.N_Cols;

   type Reference_Type (Element : not null access Ring_Type) is private
     with Implicit_Dereference => Element;

   --
   -- Indexing function (variable indexing, that is, used to update an
   -- entry) with one index
   --
   function Reference (X : aliased in out Matrix;
                       N : in Index_Type)
                       return Reference_Type
     with
       Pre => X.Is_Vector and N <= X.Length;

   --
   -- Indexing function (variable indexing) with two indexes
   --
   function Reference (X        : aliased in out Matrix;
                       Row, Col : in Index_Type)
                       return Reference_Type
     with
       Pre => Row <= X.N_Rows and Col <= X.N_Cols;

   --
   --  Usual Ada two-dimensional array of ring elements and functions
   --  to convert back and forth from/to Matrix
   --
   type Ring_Array is array (Positive range <>, Positive range <>) of Ring_Type;

   function To_Matrix (X : Ring_Array) return Matrix
     with
       Post =>
         To_Matrix'Result.N_Rows = X'Length (1) and
         To_Matrix'Result.N_Cols = X'Length (2);

   function To_Array (X : Matrix) return Ring_Array
     with
       Post =>
         X.N_Rows = To_Array'Result'Length (1) and
         X.N_Cols = To_Array'Result'Length (2);

   --
   -- Constructors for the zero matrix
   --

   function Zero (N : Index_Type) return Matrix
     with
       Post =>
         Zero'Result.N_Rows = N and
         Zero'Result.N_Cols = N;

   function Zero (N_Rows, N_Cols : Index_Type) return Matrix
     with
       Post =>
         Zero'Result.N_Rows = N_Rows and
         Zero'Result.N_Cols = N_Cols;

   function Zero (X : Matrix) return Matrix
     with
       Post =>
         Zero'Result.N_Rows = X.N_Rows and
         Zero'Result.N_Cols = X.N_Cols;

   --
   -- Constructors for the identity matrix
   --

   function Identity (N : Index_Type) return Matrix
     with
       Post =>
         Identity'Result.N_Rows = N and
         Identity'Result.N_Cols = N;

   function Identity (X : Matrix) return Matrix
     with
       Post =>
         Identity'Result.N_Rows = X.N_Rows and
         Identity'Result.N_Cols = X.N_Cols;


   function Identity (N_Rows, N_Cols : Index_Type) return Matrix
     with
       Post =>
         Identity'Result.N_Rows = N_Rows and
         Identity'Result.N_Cols = N_Cols;

   --
   -- Constructors for the "reverse identity" matrix, that is,
   -- the matrix that is equal to 1 only on the non-main diagonal.
   -- Something like this:
   --
   --   0  0  0  1
   --   0  0  1  0
   --   0  1  0  0
   --   1  0  0  0
   --
   --  Yes, you can get the same with Flip_UD(Identity(...)). Yes,
   --  it is just syntactic sugar.
   --


   function Reverse_Identity (N : Index_Type) return Matrix
     with
       Post =>
         Reverse_Identity'Result.N_Rows = N and
         Reverse_Identity'Result.N_Cols = N;

   function Reverse_Identity (X : Matrix) return Matrix
     with
       Post =>
         Reverse_Identity'Result.N_Rows = X.N_Rows and
         Reverse_Identity'Result.N_Cols = X.N_Cols;


   function Reverse_Identity (N_Rows, N_Cols : Index_Type) return Matrix
     with
       Post =>
         Reverse_Identity'Result.N_Rows = N_Rows and
         Reverse_Identity'Result.N_Cols = N_Cols;

   --
   --  Flip horizontally the matrix (LR=Left-right, named after a similar
   --  octave/matlab function)
   --
   function Flip_Lr (X : Matrix) return Matrix
     with
       Post =>
         Flip_Lr'Result.N_Rows = X.N_Rows and
         Flip_Lr'Result.N_Cols = X.N_Cols;

   --
   --  Flip vertically the matrix (UD=Up-Down, named after a similar
   --  octave/matlab function)
   --
   function Flip_Ud (X : Matrix) return Matrix
     with
       Post =>
         Flip_Ud'Result.N_Rows = X.N_Rows and
         Flip_Ud'Result.N_Cols = X.N_Cols;

   function Transpose (X : Matrix) return Matrix
     with
       Post =>
         Transpose'Result.N_Rows = X.N_Cols and
         Transpose'Result.N_Cols = X.N_Rows;

   function Trace (X : Matrix) return Ring_Type;



   function "+" (X, Y : Matrix) return Matrix
     with
       Pre =>
         X.N_Rows = Y.N_Rows and
         X.N_Cols = Y.N_Cols,
         Post =>
           X.N_Rows = "+"'Result.N_Rows and
           X.N_Cols = "+"'Result.N_Cols;

   function "-" (X, Y : Matrix) return Matrix
     with
       Pre =>
         X.N_Rows = Y.N_Rows and
         X.N_Cols = Y.N_Cols,
         Post =>
           X.N_Rows = "-"'Result.N_Rows and
           X.N_Cols = "-"'Result.N_Cols;

   function "-" (X : Matrix) return Matrix
     with
       Post =>
         X.N_Rows = "-"'Result.N_Rows and
         X.N_Cols = "-"'Result.N_Cols;

   function "*" (X, Y : Matrix) return Matrix
     with
       Pre => X.N_Cols = Y.N_Rows,
       Post =>
         X.N_Rows = "*"'Result.N_Rows and
         Y.N_Cols = "*"'Result.N_Cols;

   function "*" (C : Ring_Type; X : Matrix) return Matrix
     with
       Post =>
         X.N_Rows = "*"'Result.N_Rows and
         X.N_Cols = "*"'Result.N_Cols;

   function "**" (X : Matrix; Exponent : Natural) return Matrix
     with
       Pre =>
         X.N_Rows = X.N_Cols,
         Post =>
           X.N_Rows = "**"'Result.N_Rows and
           X.N_Cols = "**"'Result.N_Cols;

   ---
   -- Extract a row from X
   --
   function Row (X : Matrix; R : Index_Type) return Matrix
     with
       Pre => R <= X.N_Rows,
       Post =>
         Row'Result.N_Rows = 1 and
         Row'Result.N_Cols = X.N_Cols and
         (for all Col in 1 .. X.N_Cols => X (R, Col) = Row'Result (1, Col));

   ---
   -- Extract a column from X
   --
   function Column (X : Matrix; C : Index_Type) return Matrix
     with
       Pre => C <= X.N_Cols,
       Post =>
         Column'Result.N_Cols = 1 and
         Column'Result.N_Rows = X.N_Rows and
         (for all Row in 1 .. X.N_Rows => X (Row, C) = Column'Result (Row, 1));


   --
   --  Scalar product between vectors.  In theory this should be defined
   --  only for vector of the same type (row or column vectors); nevertheless,
   --  for the sake of convenience, we are not picky and the function
   --  accepts any combination of vectors
   --
   function Scalar_Product (X, Y : Matrix) return Ring_Type
     with
       Pre => X.Is_Vector and Y.Is_Vector and X.Length = Y.Length;

   --
   --  Ring printer interface.  In order to be able to print a matrix,
   --  we need to know how to print a ring element.   This can be
   --  done via a callback function (Ring_Printer_Function) or via
   --  an object descendant of Ring_Printer_Interface.  The former is
   --  simpler, the latter gives more flexibility (the printer can
   --  have an internal state)
   --

   package Ring_Printers is
     new Element_Printers (Ring_Type);

   subtype Ring_Printer_Function is Ring_Printers.Printer_Function;

   function To_String (X     : Matrix;
                       Image : Ring_Printer_Function)
                       return String;

   function To_String (X       : Matrix;
                       Printer : Ring_Printers.Printer_Interface'Class)
                       return String;

   function To_String (X : Matrix) return String;

   procedure Register_Printer (Printer : Ring_Printer_Function);

   procedure Register_Printer (Printer : Ring_Printers.Printer_Interface'Class);
private
   use Ada.Containers;

   package Ring_Vectors is
     new Ada.Containers.Vectors (Index_Type   => Index_Type,
                                 Element_Type => Ring_Type);

   type Matrix is tagged
      record
         N_Rows : Natural := 0;
         N_Cols : Natural := 0;
         --
         --  Yes, matrix data are not stored in a 2-dimensional array,
         --  but in a 1-dimensional vector, addressed in the usual way.
         --  This is a bit more flexible and, moreover, it does not
         --  require Matrix to be an indefinite type.  We need to
         --  be sure to have enough space and the Type_Invariant
         --  takes care of this
         --
         Data   : Ring_Vectors.Vector := Ring_Vectors.Empty_Vector;
      end record
     with
       Type_Invariant => Data.Length = Count_Type (N_Rows * N_Cols);


   function To_Index (M : Matrix; Row, Col : Index_Type) return Index_Type
   is (Row + (Col - Index_Type'First) * M.N_Rows)
     with
       Pre => Row <= M.N_Rows and Col <= M.N_Cols,
     Post => To_Index'Result <= M.Data.Last_Index;

   type Reference_Type (Element : not null access Ring_Type) is null record;

   --  Empty_Matrix : constant Matrix := Matrix'(N_Rows => 0,
   --                                            N_Cols => 0,
   --                                            Data   => Ring_Vectors.Empty_Vector);
   --
   --  type Ring_Printer_Callback is
   --    new Ring_Printer_Interface  with
   --     record
   --        Callback : Ring_Printer_Function;
   --     end record;
   --
   --  function Image (Printer : Ring_Printer_Callback;
   --                  Item    : Ring_Type)
   --                  return String;

end Generic_Matrices;
