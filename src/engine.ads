with Settings;

package Engine is

    -- The grid includes the boundary (0 and Max_Rows/Max_Cols)
    Max_Rows : constant Integer := Settings.Field_Rows + 1;
    Max_Cols : constant Integer := Settings.Field_Cols + 1;

    type Cell_Type is (Empty, Filled, Trace);

    type Grid_Map is array (0 .. Max_Rows, 0 .. Max_Cols) of Cell_Type;

    type Direction is (Stop, Up, Down, Left, Right);

    type Ball_Record is record
        Row, Col : Integer;
        DR, DC   : Integer; -- -1 or 1 for diagonal movement
        Speed    : Integer; -- Movement speed (1 = normal, 2 = fast on higher levels)
    end record;

    -- Land enemies move along the edge of the filled area
    type Land_Enemy_Record is record
        Row, Col : Integer;
        DR, DC   : Integer;
    end record;

    type Ball_Array is array (1 .. Settings.Max_Entities) of Ball_Record;
    type Land_Enemy_Array is array (1 .. Settings.Max_Entities) of Land_Enemy_Record;

    type Animation_Type is (None, Death, Victory);

    type Game_State is record
        Grid : Grid_Map;

        Player_Row  : Integer;
        Player_Col  : Integer;
        Player_Dir  : Direction; -- Current movement direction
        Pending_Dir : Direction; -- Next requested direction

        Balls     : Ball_Array;
        Num_Balls : Integer;

        Land_Enemies     : Land_Enemy_Array;
        Num_Land_Enemies : Integer;

        Lives          : Integer;
        Level          : Integer;
        Score          : Integer;
        Percent_Filled : Integer;

        Game_Over      : Boolean;
        Level_Complete : Boolean;
        Player_Dead    : Boolean;

        Animation       : Animation_Type;
        Animation_Timer : Integer;

        Frame_Count : Integer;
    end record;

    -- Initialize the state for the whole game
    procedure Init_Game (State : out Game_State);

    -- Initialize the state for a specific level
    procedure Init_Level (State : in out Game_State; Level : Integer);

    -- Update direction based on user input
    procedure Set_Direction (State : in out Game_State; Dir : Direction);

    -- Advance the game state by one tick
    procedure Update (State : in out Game_State);

private

    -- Internal logic
    procedure Move_Player (State : in out Game_State);
    procedure Move_Balls (State : in out Game_State);
    procedure Move_Land_Enemies (State : in out Game_State);

    -- Logic to fill territory when player returns to Filled area
    procedure Process_Capture (State : in out Game_State);

    -- Calculate percentage of field captured
    function Calculate_Percentage (State : Game_State) return Integer;

end Engine;
