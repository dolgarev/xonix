package Settings is

    --  Game field dimensions (playable area)
    --  The total window will be slightly larger to accommodate borders
    Field_Rows : constant := 20;
    Field_Cols : constant := 76;

    --  Game timing
    Game_Tick_Ms : constant := 50;

    --  Characters for rendering
    Char_Empty  : constant Character := ' ';
    Char_Filled : constant Character := '=';
    Char_Trace  : constant Character := '.';
    Char_Player : constant Character := '@';
    Char_Ball   : constant Character := 'O';
    Char_Enemy  : constant Character := 'X'; -- Land enemy

    --  Game Rules
    Initial_Lives  : constant := 3;
    Win_Percentage : constant := 75;

    --  Levels & Entities
    Max_Levels   : constant := 10;
    Max_Entities : constant := 20;

    --  Animations
    Animation_Duration_Ticks : constant := 30; -- ~1.5 seconds at 50ms tick

    --  Color Pair IDs
    Color_Empty_ID   : constant := 1; -- White on Black
    Color_Field_ID   : constant := 2; -- White on Blue
    Color_Player_ID  : constant := 3; -- Yellow on Black
    Color_Trace_ID   : constant := 4; -- Green on Black
    Color_Ball_ID    : constant := 5; -- Red on Black
    Color_Enemy_ID   : constant := 6; -- Magenta on Black
    Color_Status_ID  : constant := 7; -- Cyan on Black
    Color_Dead_ID    : constant := 8; -- Red on Black (Special)
    Color_Death_Blink_ID   : constant := 9;  -- White on Red
    Color_Victory_Blink_ID : constant := 10; -- White on Green

end Settings;
