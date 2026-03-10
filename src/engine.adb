with Ada.Numerics.Float_Random;

package body Engine is

   Generator : Ada.Numerics.Float_Random.Generator;

   -------------------------------------------------------------------------
   function Calculate_Percentage (State : Game_State) return Integer is
      Filled_Count : Natural := 0;
      Total_Cells  : constant Natural := Settings.Field_Rows * Settings.Field_Cols;
   begin
      for R in 1 .. Settings.Field_Rows loop
         for C in 1 .. Settings.Field_Cols loop
            if State.Grid (R, C) = Filled then
               Filled_Count := Filled_Count + 1;
            end if;
         end loop;
      end loop;
      return Integer ((Float (Filled_Count) / Float (Total_Cells)) * 100.0);
   end Calculate_Percentage;

   -------------------------------------------------------------------------
   procedure Setup_Grid (Grid : out Grid_Map) is
   begin
      for R in 0 .. Max_Rows loop
         for C in 0 .. Max_Cols loop
            if R <= 1 or R >= Max_Rows - 1 or C <= 1 or C >= Max_Cols - 1 then
               Grid (R, C) := Filled;
            else
               Grid (R, C) := Empty;
            end if;
         end loop;
      end loop;
   end Setup_Grid;

   -------------------------------------------------------------------------
   procedure Init_Level (State : in out Game_State; Level : Integer) is
      use Ada.Numerics.Float_Random;
   begin
      State.Level := Level;
      Setup_Grid (State.Grid);

      -- Start position: middle of the top edge, on the safe border
      State.Player_Row := 0;
      State.Player_Col := Settings.Field_Cols / 2;
      State.Player_Dir := Stop;
      State.Pending_Dir := Stop;

      -- Balls
      State.Num_Balls := Level + 1;
      if State.Num_Balls > Ball_Array'Length then
         State.Num_Balls := Ball_Array'Length;
      end if;

      for I in 1 .. State.Num_Balls loop
         State.Balls (I).Row := Integer (Random (Generator) * Float (Settings.Field_Rows - 2)) + 1;
         State.Balls (I).Col := Integer (Random (Generator) * Float (Settings.Field_Cols - 2)) + 1;
         State.Balls (I).DR  := (if Random (Generator) > 0.5 then 1 else -1);
         State.Balls (I).DC  := (if Random (Generator) > 0.5 then 1 else -1);
      end loop;

      -- Land Enemies (tiered progression)
      if Level in 1 .. 3 or Level = 10 then
         State.Num_Land_Enemies := 0;
      elsif Level in 4 .. 6 then
         State.Num_Land_Enemies := 1;
      else -- Level 7 .. 9
         State.Num_Land_Enemies := 2;
      end if;
      if State.Num_Land_Enemies > Land_Enemy_Array'Length then
         State.Num_Land_Enemies := Land_Enemy_Array'Length;
      end if;

      for I in 1 .. State.Num_Land_Enemies loop
         -- Start on edges: top, bottom, left, or right, inside the 2-cell border
         case I mod 4 is
            when 0 => -- Top
               State.Land_Enemies (I).Row := 0;
               State.Land_Enemies (I).Col := Integer (Random (Generator) * Float (Settings.Field_Cols));
            when 1 => -- Bottom
               State.Land_Enemies (I).Row := Max_Rows;
               State.Land_Enemies (I).Col := Integer (Random (Generator) * Float (Settings.Field_Cols));
            when 2 => -- Left
               State.Land_Enemies (I).Row := Integer (Random (Generator) * Float (Settings.Field_Rows));
               State.Land_Enemies (I).Col := 0;
            when 3 => -- Right
               State.Land_Enemies (I).Row := Integer (Random (Generator) * Float (Settings.Field_Rows));
               State.Land_Enemies (I).Col := Max_Cols;
            when others => null;
         end case;
         -- Land enemies move diagonally inside the filled area
         State.Land_Enemies (I).DR := (if Random (Generator) > 0.5 then 1 else -1);
         State.Land_Enemies (I).DC := (if Random (Generator) > 0.5 then 1 else -1);
      end loop;

      State.Percent_Filled := Calculate_Percentage (State);
      State.Level_Complete := False;
      State.Player_Dead    := False;
      State.Animation      := None;
      State.Animation_Timer := 0;
   end Init_Level;

   -------------------------------------------------------------------------
   procedure Init_Game (State : out Game_State) is
   begin
      Ada.Numerics.Float_Random.Reset (Generator);
      State.Lives := Settings.Initial_Lives;
      State.Score := 0;
      State.Frame_Count := 0;
      State.Game_Over := False;
      Init_Level (State, 1);
   end Init_Game;

   -------------------------------------------------------------------------
   procedure Set_Direction (State : in out Game_State; Dir : Direction) is
   begin
      State.Pending_Dir := Dir;
   end Set_Direction;

   -------------------------------------------------------------------------
   procedure Process_Capture (State : in out Game_State) is
      type Mark_Grid is array (0 .. Max_Rows, 0 .. Max_Cols) of Boolean;
      Reachable : Mark_Grid := [others => [others => False]];

      procedure Flood (R, C : Integer) is
         type Stack_Item is record R, C : Integer; end record;
         Stack : array (1 .. (Max_Rows + 1) * (Max_Cols + 1)) of Stack_Item;
         Top : Natural := 0;
      begin
         if R < 1 or R > Settings.Field_Rows or C < 1 or C > Settings.Field_Cols then
            return;
         end if;
         if State.Grid (R, C) /= Empty or Reachable (R, C) then
            return;
         end if;

         Top := Top + 1;
         Stack (Top) := (R, C);
         Reachable (R, C) := True;

         while Top > 0 loop
            declare
               Curr : constant Stack_Item := Stack (Top);
            begin
               Top := Top - 1;
               for DR in -1 .. 1 loop
                  for DC in -1 .. 1 loop
                     if (DR = 0 or else DC = 0) and then DR /= DC then
                        declare
                           NR : constant Integer := Curr.R + DR;
                           NC : constant Integer := Curr.C + DC;
                        begin
                           if NR >= 1 and then NR <= Settings.Field_Rows and then
                              NC >= 1 and then NC <= Settings.Field_Cols and then
                              State.Grid (NR, NC) = Empty and then not Reachable (NR, NC)
                           then
                              Top := Top + 1;
                              Stack (Top) := (NR, NC);
                              Reachable (NR, NC) := True;
                           end if;
                        end;
                     end if;
                  end loop;
               end loop;
            end;
         end loop;
      end Flood;

   begin
      -- 1. Convert Trace to Filled
      for R in 0 .. Max_Rows loop
         for C in 0 .. Max_Cols loop
            if State.Grid (R, C) = Trace then
               State.Grid (R, C) := Filled;
               State.Score := State.Score + 10;
            end if;
         end loop;
      end loop;

      -- 2. Mark all areas reachable by balls
      for I in 1 .. State.Num_Balls loop
         Flood (State.Balls (I).Row, State.Balls (I).Col);
      end loop;

      -- 3. Fill anything not reachable
      for R in 1 .. Settings.Field_Rows loop
         for C in 1 .. Settings.Field_Cols loop
            if State.Grid (R, C) = Empty and then not Reachable (R, C) then
               State.Grid (R, C) := Filled;
               State.Score := State.Score + 20;
            end if;
         end loop;
      end loop;

      -- 4. Check for trapped balls (shouldn't happen with correct Flood, but for safety)
      for I in 1 .. State.Num_Balls loop
         if State.Grid (State.Balls (I).Row, State.Balls (I).Col) = Filled then
            -- Find nearest empty cell or just reset its position
            -- For simplicity, reset to a known empty cell if possible, or just keep it there
            -- and let bounce handle it, but it might be stuck forever.
            -- Better: if it's trapped, it should have been filled anyway?
            -- No, balls are in Empty area. If a ball's area is filled, it means multiple balls
            -- were in separate areas and this one was "trapped".
            null;
         end if;
      end loop;

      State.Percent_Filled := Calculate_Percentage (State);
      if State.Percent_Filled >= Settings.Win_Percentage then
         State.Animation      := Victory;
         State.Animation_Timer := Settings.Animation_Duration_Ticks;
      end if;
   end Process_Capture;

   -------------------------------------------------------------------------
   procedure Move_Player (State : in out Game_State) is
      New_R : Integer := State.Player_Row;
      New_C : Integer := State.Player_Col;
      Current_On_Filled : constant Boolean := State.Grid (State.Player_Row, State.Player_Col) = Filled;
   begin
      if State.Pending_Dir /= Stop then
         -- Only allow 90 degree turns or starting to move
         case State.Pending_Dir is
            when Up    => if State.Player_Dir /= Down  then State.Player_Dir := Up; end if;
            when Down  => if State.Player_Dir /= Up    then State.Player_Dir := Down; end if;
            when Left  => if State.Player_Dir /= Right then State.Player_Dir := Left; end if;
            when Right => if State.Player_Dir /= Left  then State.Player_Dir := Right; end if;
            when others => null;
         end case;
         State.Pending_Dir := Stop;
      end if;

      if State.Player_Dir = Stop then return; end if;

      case State.Player_Dir is
         when Up    => New_R := New_R - 1;
         when Down  => New_R := New_R + 1;
         when Left  => New_C := New_C - 1;
         when Right => New_C := New_C + 1;
         when Stop  => null;
      end case;

      -- Boundary check
      if New_R < 0 or New_R > Max_Rows or New_C < 0 or New_C > Max_Cols then
         State.Player_Dir := Stop;
         return;
      end if;

      declare
         Target_Cell : constant Cell_Type := State.Grid (New_R, New_C);
      begin
         if Target_Cell = Trace then
            -- Hit own trace
            State.Player_Dead := True;
            return;
         end if;

         if Target_Cell = Empty then
            State.Grid (New_R, New_C) := Trace;
            State.Player_Row := New_R;
            State.Player_Col := New_C;
         elsif Target_Cell = Filled then
            if not Current_On_Filled then
               -- Just finished a trace
               State.Player_Row := New_R;
               State.Player_Col := New_C;
               State.Player_Dir := Stop;
               Process_Capture (State);
            else
               -- Moving on filled area
               State.Player_Row := New_R;
               State.Player_Col := New_C;
            end if;
         end if;
      end;
   end Move_Player;

   -------------------------------------------------------------------------
   procedure Move_Balls (State : in out Game_State) is
   begin
      for I in 1 .. State.Num_Balls loop
         declare
            Ball : Ball_Record renames State.Balls (I);
            Next_R : constant Integer := Ball.Row + Ball.DR;
            Next_C : constant Integer := Ball.Col + Ball.DC;
         begin
            -- Bounce logic
            declare
               Bounced : Boolean := False;
            begin
               -- Check horizontal wall/filled
               if Next_R < 0 or else Next_R > Max_Rows or else State.Grid (Next_R, Ball.Col) = Filled then
                  Ball.DR := -Ball.DR;
                  Bounced := True;
               end if;

               -- Check vertical wall/filled
               if Next_C < 0 or else Next_C > Max_Cols or else State.Grid (Ball.Row, Next_C) = Filled then
                  Ball.DC := -Ball.DC;
                  Bounced := True;
               end if;

               -- If no horizontal/vertical bounce but diagonal is filled, bounce both
               if not Bounced then
                   if Next_R >= 0 and then Next_R <= Max_Rows and then
                      Next_C >= 0 and then Next_C <= Max_Cols and then
                      State.Grid (Next_R, Next_C) = Filled
                   then
                      Ball.DR := -Ball.DR;
                      Ball.DC := -Ball.DC;
                   end if;
               end if;
            end;

            Ball.Row := Ball.Row + Ball.DR;
            Ball.Col := Ball.Col + Ball.DC;

            -- Safety check: if we're still in Filled area (unlikely with correct bounce), don't move
            if Ball.Row < 0 or else Ball.Row > Max_Rows or else Ball.Col < 0 or else Ball.Col > Max_Cols
               or else State.Grid (Ball.Row, Ball.Col) = Filled
            then
               -- Revert movement if somehow we ended up in Filled area
               Ball.Row := Ball.Row - Ball.DR;
               Ball.Col := Ball.Col - Ball.DC;
               -- Try to find a way out or just stay put
            end if;

            -- Check if hit player or trace
            if Ball.Row = State.Player_Row and Ball.Col = State.Player_Col then
               State.Player_Dead := True;
            elsif State.Grid (Ball.Row, Ball.Col) = Trace then
               State.Player_Dead := True;
            end if;
         end;
      end loop;
   end Move_Balls;

   -------------------------------------------------------------------------
   procedure Move_Land_Enemies (State : in out Game_State) is
   begin
      for I in 1 .. State.Num_Land_Enemies loop
         declare
            Enemy : Land_Enemy_Record renames State.Land_Enemies (I);
            -- Land enemies bounce off Empty and Trace cells
            Next_R : constant Integer := Enemy.Row + Enemy.DR;
            Next_C : constant Integer := Enemy.Col + Enemy.DC;
            Bounced : Boolean := False;
         begin
            -- Boundary/Type check for Row movement
            if Next_R < 0 or else Next_R > Max_Rows or else (Next_C >= 0 and then Next_C <= Max_Cols and then State.Grid (Next_R, Enemy.Col) /= Filled) then
               Enemy.DR := -Enemy.DR;
               Bounced := True;
            end if;

            -- Boundary/Type check for Column movement
            if Next_C < 0 or else Next_C > Max_Cols or else (Enemy.Row >= 0 and then Enemy.Row <= Max_Rows and then State.Grid (Enemy.Row, Next_C) /= Filled) then
               Enemy.DC := -Enemy.DC;
               Bounced := True;
            end if;

            -- Diagonal bounce if no axial bounce occurred
            if not Bounced then
               if Next_R >= 0 and then Next_R <= Max_Rows and then
                  Next_C >= 0 and then Next_C <= Max_Cols and then
                  State.Grid (Next_R, Next_C) /= Filled
               then
                  Enemy.DR := -Enemy.DR;
                  Enemy.DC := -Enemy.DC;
               end if;
            end if;

            Enemy.Row := Enemy.Row + Enemy.DR;
            Enemy.Col := Enemy.Col + Enemy.DC;

            -- Safety check: ensure enemy stays in Filled area
            if Enemy.Row < 0 or else Enemy.Row > Max_Rows or else Enemy.Col < 0 or else Enemy.Col > Max_Cols
               or else State.Grid (Enemy.Row, Enemy.Col) /= Filled
            then
               Enemy.Row := Enemy.Row - Enemy.DR;
               Enemy.Col := Enemy.Col - Enemy.DC;
            end if;

            -- Check if hit player
            if Enemy.Row = State.Player_Row and Enemy.Col = State.Player_Col then
               State.Player_Dead := True;
            end if;
         end;
      end loop;
   end Move_Land_Enemies;

   -------------------------------------------------------------------------
   procedure Update (State : in out Game_State) is
   begin
      -- Handle animations
      if State.Animation /= None then
         State.Animation_Timer := State.Animation_Timer - 1;
         if State.Animation_Timer <= 0 then
            if State.Animation = Death then
               State.Lives := State.Lives - 1;
               if State.Lives = 0 then
                  State.Game_Over := True;
               else
                  -- Clean up traces and reset positions
                  for R in 0 .. Max_Rows loop
                     for C in 0 .. Max_Cols loop
                        if State.Grid (R, C) = Trace then
                           State.Grid (R, C) := Empty;
                        end if;
                     end loop;
                  end loop;
                  State.Player_Row := 0;
                  State.Player_Col := Settings.Field_Cols / 2;
                  State.Player_Dir := Stop;
                  State.Pending_Dir := Stop;
                  State.Player_Dead := False;
               end if;
            elsif State.Animation = Victory then
               State.Level_Complete := True;
            end if;
            State.Animation := None;
         end if;
         return;
      end if;

      if State.Player_Dead then
         State.Animation := Death;
         State.Animation_Timer := Settings.Animation_Duration_Ticks;
         return;
      end if;

      State.Frame_Count := State.Frame_Count + 1;

      Move_Player (State);

      -- Balls move every tick
      Move_Balls (State);

      -- Land enemies move every 2 ticks
      if State.Frame_Count mod 2 = 0 then
         Move_Land_Enemies (State);
      end if;
   end Update;

end Engine;
