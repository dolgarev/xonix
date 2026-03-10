with Engine; use Engine;

package Renderer is

    -- Initialize ncurses color pairs
    procedure Initialize_Colors;

    -- Draw the full game screen (map + status bar)
    procedure Draw_Game (State : Game_State);

    -- Show full-screen splash / title screen
    procedure Show_Splash;

    -- Show screen for level complete
    procedure Show_Level_Complete (State : Game_State);

    -- Show screen for game over
    procedure Show_Game_Over (State : Game_State);

    procedure Show_Level_Selection (Selected_Level : out Integer);

end Renderer;
