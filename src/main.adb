with Engine;                    use Engine;
with Renderer;
with Settings;
with Terminal_Interface.Curses; use Terminal_Interface.Curses;
with Terminal_Interface.Curses_Constants;
with Ada.Text_IO;
with Ada.Calendar;
with Ada.Exceptions; use Ada.Exceptions;

procedure Main is
    State : Game_State;
    Ch    : Key_Code;
    Quit  : Boolean := False;

    -- Timing variables
    use type Ada.Calendar.Time;
    Next_Tick     : Ada.Calendar.Time;
    Tick_Interval : constant Duration :=
       Duration (Settings.Game_Tick_Ms) / 1000.0;


    procedure Display_Error (Message : String) is
    begin
        Ada.Text_IO.Put_Line ("Error: " & Message);
        Ada.Text_IO.Put_Line ("Press ENTER to exit.");
        begin
            Ada.Text_IO.Skip_Line;
        exception
            when others =>
                null;
        end;
    end Display_Error;

    function To_Key_Code (C : Character) return Key_Code is
    begin
        return Key_Code (Character'Pos (C));
    end To_Key_Code;

begin
    -- Initialize ncurses
    Init_Screen;
    Renderer.Initialize_Colors;
    Set_Echo_Mode (False);
    Set_KeyPad_Mode (Standard_Window, True);
    declare
        Vis : Cursor_Visibility := Invisible;
    begin
        Set_Cursor_Visibility (Vis);
    exception
        when others => null; -- Cursor visibility might not be supported
    end;
    Set_Raw_Mode (True);

    -- Show splash screen
    Renderer.Show_Splash;
    Set_Timeout_Mode (Standard_Window, Blocking, 0);
    Ch := Get_Keystroke;
    if Ch = To_Key_Code ('q') or else Ch = To_Key_Code ('Q') then
        End_Windows;
        return;
    end if;

    -- Outer loop to allow returning to level selection
    while not Quit loop
        -- Level Selection
        declare
            Selected : Integer;
        begin
            Renderer.Show_Level_Selection (Selected);
            if Selected = 0 then
                Quit := True;
                exit;
            end if;
            Init_Game (State);
            Init_Level (State, Selected);
        end;

        Next_Tick := Ada.Calendar.Clock;

        -- Main game loop
        while not Quit loop
        -- Handle input (non-blocking)
        Set_Timeout_Mode (Standard_Window, Non_Blocking, 0);
        Ch := Get_Keystroke;

        if Ch /= Terminal_Interface.Curses_Constants.ERR then
            if Ch = Key_Cursor_Up
               or else Ch = To_Key_Code ('w')
               or else Ch = To_Key_Code ('W')
            then
                Set_Direction (State, Up);
            elsif Ch = Key_Cursor_Down
               or else Ch = To_Key_Code ('s')
               or else Ch = To_Key_Code ('S')
            then
                Set_Direction (State, Down);
            elsif Ch = Key_Cursor_Left
               or else Ch = To_Key_Code ('a')
               or else Ch = To_Key_Code ('A')
            then
                Set_Direction (State, Left);
            elsif Ch = Key_Cursor_Right
               or else Ch = To_Key_Code ('d')
               or else Ch = To_Key_Code ('D')
            then
                Set_Direction (State, Right);
            elsif Ch = To_Key_Code ('q') or else Ch = To_Key_Code ('Q') then
                Quit := True;
            elsif Ch = To_Key_Code ('r') or else Ch = To_Key_Code ('R') then
                Init_Level (State, State.Level);
            end if;
        end if;

        -- Update game state at fixed intervals
        if Ada.Calendar.Clock >= Next_Tick then
            Update (State);
            Next_Tick := Next_Tick + Tick_Interval;

            -- Draw game only on tick or during animation
            Renderer.Draw_Game (State);

            -- Check game state
            if State.Game_Over then
                Renderer.Show_Game_Over (State);
                Set_Timeout_Mode (Standard_Window, Blocking, 0);
                Ch := Get_Keystroke;
                exit; -- Exit inner loop to go back to level selection

            elsif State.Level_Complete then
                Renderer.Show_Level_Complete (State);
                Set_Timeout_Mode (Standard_Window, Blocking, 0);
                Ch := Get_Keystroke;

                if State.Level < Settings.Max_Levels then
                    State.Level := State.Level + 1;
                    if State.Lives < 5 then
                        State.Lives := State.Lives + 1;
                    end if;
                    Init_Level (State, State.Level);
                    Next_Tick := Ada.Calendar.Clock;
                else
                    exit; -- Go back to level selection
                end if;
            end if;
        end if;

        -- Prevent CPU spinning
        delay 0.005;
    end loop;
    end loop;

    -- Cleanup
    End_Windows;

    Ada.Text_IO.Put_Line ("Thanks for playing Xonix!");
    Ada.Text_IO.Put_Line ("Final Score: " & State.Score'Image);
    Ada.Text_IO.Put_Line ("Level Reached: " & State.Level'Image);

exception
    when E : Curses_Exception =>
        End_Windows;
        Ada.Text_IO.Put_Line ("Ncurses error: " & Exception_Message (E));
        Display_Error ("Ncurses error occurred. Terminal might be too small.");
    when E : others =>
        End_Windows;
        Ada.Text_IO.Put_Line ("Unexpected error: " & Exception_Name (E));
        Ada.Text_IO.Put_Line ("Message: " & Exception_Message (E));
        Display_Error ("An unexpected error occurred.");
end Main;
