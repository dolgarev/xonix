with Ada.Strings.Fixed;
with Ada.Strings;
with Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;

package body Renderer is


    -------------------------------------------------------------------------
    procedure Initialize_Colors is
    begin
        if Has_Colors then
            Start_Color;
            Init_Pair (Pair => Color_Pair (Settings.Color_Empty_ID), Fore => White, Back => Black);
            Init_Pair (Pair => Color_Pair (Settings.Color_Field_ID), Fore => White, Back => Blue);
            Init_Pair (Pair => Color_Pair (Settings.Color_Player_ID), Fore => Yellow, Back => Black);
            Init_Pair (Pair => Color_Pair (Settings.Color_Trace_ID), Fore => Green, Back => Black);
            Init_Pair (Pair => Color_Pair (Settings.Color_Ball_ID), Fore => Red, Back => Black);
            Init_Pair (Pair => Color_Pair (Settings.Color_Enemy_ID), Fore => Magenta, Back => Black);
            Init_Pair (Pair => Color_Pair (Settings.Color_Status_ID), Fore => Cyan, Back => Black);
            Init_Pair (Pair => Color_Pair (Settings.Color_Dead_ID), Fore => Red, Back => Black);
            -- Blinking pairs (Background colors)
            Init_Pair (Pair => Color_Pair (Settings.Color_Death_Blink_ID), Fore => White, Back => Red);
            Init_Pair (Pair => Color_Pair (Settings.Color_Victory_Blink_ID), Fore => White, Back => Green);
        end if;
    end Initialize_Colors;

    -------------------------------------------------------------------------
    procedure Center_Text (Win : Window; Row : Line_Position; Text : String) is
        L : Line_Count;
        C : Column_Count;
    begin
        Get_Size (Win, L, C);
        declare
            Text_Len : constant Integer := Text'Length;
            Win_Cols : constant Integer := Integer (C);
            Col      : Column_Position;
        begin
            if Win_Cols > Text_Len then
                Col := Column_Position ((Win_Cols - Text_Len) / 2);
                Move_Cursor (Win, Row, Col);
                Add (Win, Text);
            elsif Win_Cols > 0 then
                Move_Cursor (Win, Row, 0);
                if Text_Len > Win_Cols then
                    Add (Win, Text (Text'First .. Text'First + Win_Cols - 1));
                else
                    Add (Win, Text);
                end if;
            end if;
        exception
            when others => null; -- Prevent crash if Row/Col still out of bounds
        end;
    end Center_Text;

    -------------------------------------------------------------------------
    function Pad_Zero (Val : Integer; Width : Positive := 2) return String is
        use Ada.Strings.Fixed;
        use Ada.Strings;
        S : constant String := Trim (Val'Image, Both);
    begin
        if S'Length < Width then
            return [1 .. Width - S'Length => '0'] & S;
        else
            return S;
        end if;
    end Pad_Zero;

    -------------------------------------------------------------------------
    procedure Draw_Game (State : Game_State) is
        Win : constant Window := Standard_Window;
        L   : Line_Count;
        C   : Column_Count;

        Map_Display_Rows : constant Integer := Settings.Field_Rows + 2;
        Map_Display_Cols : constant Integer := Settings.Field_Cols + 2;

        L_Off : Line_Position;
        C_Off : Column_Position;

        procedure Put_Char
           (R, C : Integer; Ch : Character; Color_Pair_Index : Integer := 1)
        is
            Attr_Ch : Attributed_Character;
        begin
            if Has_Colors then
                Attr_Ch :=
                   (Ch    => Ch,
                    Attr  => Normal_Video,
                    Color => Color_Pair (Color_Pair_Index));
                Add (Win, Line_Position (R), Column_Position (C), Attr_Ch);
            else
                Add (Win, Line_Position (R), Column_Position (C), Ch);
            end if;
        end Put_Char;

    begin
        Get_Size (Win, L, C);
        Erase (Win);

        L_Off :=
           Line_Position
              (Integer'Max (0, (Integer (L) - (Map_Display_Rows + 1)) / 2));
        C_Off :=
           Column_Position
              (Integer'Max (0, (Integer (C) - Map_Display_Cols) / 2));

        for R in 0 .. Engine.Max_Rows loop
            for Col in 0 .. Engine.Max_Cols loop
                case State.Grid (R, Col) is
                    when Empty  =>
                        Put_Char
                           (Integer (L_Off) + R,
                            Integer (C_Off) + Col,
                            Settings.Char_Empty,
                            Settings.Color_Empty_ID);

                    when Filled =>
                        Put_Char
                           (Integer (L_Off) + R,
                            Integer (C_Off) + Col,
                            Settings.Char_Filled,
                            Settings.Color_Field_ID);

                    when Trace  =>
                        Put_Char
                           (Integer (L_Off) + R,
                            Integer (C_Off) + Col,
                            Settings.Char_Trace,
                            Settings.Color_Trace_ID);
                end case;
            end loop;
        end loop;

        Put_Char
           (Integer (L_Off) + State.Player_Row,
            Integer (C_Off) + State.Player_Col,
            Settings.Char_Player,
            Settings.Color_Player_ID);

        for I in 1 .. State.Num_Balls loop
            if State.Balls (I).Row >= 0 and then State.Balls (I).Col >= 0 then
                Put_Char
                   (Integer (L_Off) + State.Balls (I).Row,
                    Integer (C_Off) + State.Balls (I).Col,
                    Settings.Char_Ball,
                    Settings.Color_Ball_ID);
            end if;
        end loop;

        for I in 1 .. State.Num_Land_Enemies loop
            if State.Land_Enemies (I).Row >= 0
               and then State.Land_Enemies (I).Col >= 0
            then
                Put_Char
                   (Integer (L_Off) + State.Land_Enemies (I).Row,
                    Integer (C_Off) + State.Land_Enemies (I).Col,
                    Settings.Char_Enemy,
                    Settings.Color_Enemy_ID);
            end if;
        end loop;

        if State.Player_Dead then
            Put_Char
               (Integer (L_Off) + State.Player_Row,
                Integer (C_Off) + State.Player_Col,
                'X',
                Settings.Color_Dead_ID);
        end if;

        -- Apply blinking during animations (Background color flash)
        if State.Animation = Death then
            if (State.Animation_Timer / 4) mod 2 = 0 then
                -- Flash player with White on Red background
                Put_Char
                   (Integer (L_Off) + State.Player_Row,
                    Integer (C_Off) + State.Player_Col,
                    Settings.Char_Player,
                    Settings.Color_Death_Blink_ID); -- White on Red
            end if;
        elsif State.Animation = Victory then
            if (State.Animation_Timer / 4) mod 2 = 0 then
                -- Flash enemies with White on Green background
                for I in 1 .. State.Num_Balls loop
                    Put_Char
                       (Integer (L_Off) + State.Balls (I).Row,
                        Integer (C_Off) + State.Balls (I).Col,
                        Settings.Char_Ball,
                        Settings.Color_Victory_Blink_ID); -- White on Green
                end loop;
                for I in 1 .. State.Num_Land_Enemies loop
                    Put_Char
                       (Integer (L_Off) + State.Land_Enemies (I).Row,
                        Integer (C_Off) + State.Land_Enemies (I).Col,
                        Settings.Char_Enemy,
                        Settings.Color_Victory_Blink_ID); -- White on Green
                end loop;
            end if;
        end if;

        declare
            Status_Row : constant Line_Position :=
               L_Off + Line_Position (Map_Display_Rows);
            Bar        : constant String :=
               " LEVEL: "
               & Pad_Zero (State.Level, 2)
               & "  SCORE: "
               & Pad_Zero (State.Score, 6)
               & "  FILLED: "
               & Pad_Zero (State.Percent_Filled, 2)
               & "%"
               & "  LIVES: "
               & Pad_Zero (State.Lives, 2)
               & " ";
            Bar_Len    : constant Integer :=
               Integer'Min (Bar'Length, Map_Display_Cols);
            Pad_Len    : constant Integer := (Map_Display_Cols - Bar_Len) / 2;
            S          : String (1 .. Map_Display_Cols) := [others => ' '];
        begin
            S (Pad_Len + 1 .. Pad_Len + Bar_Len) :=
               Bar (Bar'First .. Bar'First + Bar_Len - 1);
            Move_Cursor (Win, Status_Row, C_Off);
            Set_Character_Attributes (Win, Color => Color_Pair (Settings.Color_Status_ID));
            Add (Win, S);
        end;

        Refresh (Win);
    end Draw_Game;

    -------------------------------------------------------------------------
    procedure Show_Splash is
        Win : constant Window := Standard_Window;
        L   : Line_Count;
        C   : Column_Count;
        Row : Line_Position;
    begin
        Get_Size (Win, L, C);
        Row := Line_Position (Integer'Max (0, Integer (L) / 2 - 8));
        Erase (Win);

        Set_Character_Attributes (Win, Color => Color_Pair (3));
        Center_Text (Win, Row,     "__  __  ____   _   _  ___ __  __");
        Center_Text (Win, Row + 1, "\ \/ / / __ \ | \ | ||_ _|\ \/ /");
        Center_Text (Win, Row + 2, " >  < | |  | ||  \| | | |  >  < ");
        Center_Text (Win, Row + 3, "/_/\_\| |__| || |\  | | | /_/\_\");
        Center_Text (Win, Row + 4, "      \____/ |_| \_||___|      ");

        Set_Character_Attributes (Win, Color => Color_Pair (7));
        Center_Text (Win, Row + 6, "Cutting Corners Since 1984");

        Set_Character_Attributes (Win, Color => Color_Pair (3));
        Center_Text (Win, Row + 8, "CONTROLS:");
        Center_Text
           (Win,
            Row + Line_Position (9),
            "  Arrows / WASD - Move the player (@)");
        Center_Text
           (Win,
            Row + Line_Position (10),
            "  Trace lines to capture the field");
        Center_Text
           (Win,
            Row + Line_Position (11),
            "  Avoid Balls (O) and Enemies (X)");

        Set_Character_Attributes (Win, Color => Color_Pair (2));
        declare
            use Ada.Strings.Fixed;
            use Ada.Strings;
        begin
            Center_Text
               (Win,
                Row + Line_Position (13),
                "GOAL: Capture "
                & Trim (Settings.Win_Percentage'Image, Both)
                & "% of the territory!");
        end;

        Set_Character_Attributes (Win, Color => Color_Pair (7));
        Center_Text
           (Win, Row + Line_Position (15), "R - restart     Q - quit");

        Set_Character_Attributes (Win, Color => Color_Pair (4));
        Center_Text
           (Win, Row + Line_Position (17), ">>>  Press any key to start  <<<");

        Refresh (Win);
    end Show_Splash;

    -------------------------------------------------------------------------
    procedure Show_Level_Complete (State : Game_State) is
        Win : constant Window := Standard_Window;
        L   : Line_Count;
        C   : Column_Count;
        Row : Line_Position;
    begin
        Get_Size (Win, L, C);
        Row := Line_Position (Integer'Max (0, Integer (L) / 2 - 3));
        Erase (Win);

        Set_Character_Attributes (Win, Color => Color_Pair (2));
        Center_Text (Win, Row, "  L E V E L   C O M P L E T E !  ");

        Set_Character_Attributes (Win, Color => Color_Pair (3));
        Center_Text
           (Win, Row + Line_Position (2), "Level: " & State.Level'Image);
        Center_Text
           (Win, Row + Line_Position (3), "Score: " & State.Score'Image);

        Set_Character_Attributes (Win, Color => Color_Pair (7));
        if State.Level < Settings.Max_Levels then
            Center_Text
               (Win, Row + Line_Position (5), "Press any key to continue");
        else
            Set_Character_Attributes (Win, Color => Color_Pair (2));
            Center_Text
               (Win,
                Row + Line_Position (4),
                "All levels cleared! You are a Xonix Master!");
            Set_Character_Attributes (Win, Color => Color_Pair (7));
            Center_Text
               (Win, Row + Line_Position (6), "Press any key to continue");
        end if;
        Refresh (Win);
    end Show_Level_Complete;

    procedure Show_Game_Over (State : Game_State) is
        Win : constant Window := Standard_Window;
        L   : Line_Count;
        C   : Column_Count;
        Row : Line_Position;
    begin
        Get_Size (Win, L, C);
        Row := Line_Position (Integer'Max (0, Integer (L) / 2 - 3));
        Erase (Win);

        Set_Character_Attributes (Win, Color => Color_Pair (8));
        Center_Text (Win, Row, "  G A M E   O V E R  ");

        Set_Character_Attributes (Win, Color => Color_Pair (3));
        Center_Text
           (Win, Row + Line_Position (2), "Level reached: " & State.Level'Image);
        Center_Text
           (Win, Row + Line_Position (3), "Final Score: " & State.Score'Image);

        Set_Character_Attributes (Win, Color => Color_Pair (7));
        Center_Text
           (Win, Row + Line_Position (5), "Press any key to continue");

        Refresh (Win);
    end Show_Game_Over;

    -------------------------------------------------------------------------
    procedure Show_Level_Selection (Selected_Level : out Integer) is
        Win : constant Window := Standard_Window;
        L   : Line_Count;
        C   : Column_Count;
        Row : Line_Position;
        Key : Key_Code;
        Current : Integer := 1;
    begin
        Get_Size (Win, L, C);
        Row := Line_Position (Integer'Max (0, Integer (L) / 2 - 4));

        loop
            Erase (Win);
            Set_Character_Attributes (Win, Color => Color_Pair (7));
            Center_Text (Win, Row, "  S E L E C T   L E V E L  ");

            Set_Character_Attributes (Win, Color => Color_Pair (3));
            Center_Text (Win, Row + 2, "Choose starting level (1-" & Settings.Max_Levels'Image & ")");

            Set_Character_Attributes (Win, Color => Color_Pair (2));
            Center_Text (Win, Row + 4, ">>>  Level " & Pad_Zero(Current, 2) & "  <<<");

            Set_Character_Attributes (Win, Color => Color_Pair (7));
            Center_Text (Win, Row + 6, "Arrows - Change    Enter - Start    Q - Quit");

            Refresh (Win);

            Key := Get_Keystroke (Win);
            case Key is
                when Key_Cursor_Up | Key_Cursor_Right =>
                    if Current < Settings.Max_Levels then
                        Current := Current + 1;
                    end if;
                when Key_Cursor_Down | Key_Cursor_Left =>
                    if Current > 1 then
                        Current := Current - 1;
                    end if;
                when Character'Pos (ASCII.LF) | Character'Pos (ASCII.CR) =>
                    Selected_Level := Current;
                    exit;
                when Character'Pos ('q') | Character'Pos ('Q') =>
                    Selected_Level := 0;
                    exit;
                when others => null;
            end case;
        end loop;
    end Show_Level_Selection;

end Renderer;
