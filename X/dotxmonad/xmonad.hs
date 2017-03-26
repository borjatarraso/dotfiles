import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO
import XMonad.Layout.NoBorders
import XMonad.Layout.Grid
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ICCCMFocus
import XMonad.StackSet hiding (workspaces)
import XMonad.Actions.SpawnOn
import XMonad.Actions.CopyWindow
import XMonad.Prompt
import XMonad.Prompt.Man
import XMonad.Prompt.RunOrRaise
import Data.List
import Data.Monoid
import Control.Concurrent
import Data.Ratio ((%))

myModMask = mod4Mask  -- rebind Mod to Super key
myTerminal = "xterm"
myBorderWidth = 1
focusColor = "red"
textColor = "#000000"
lightTextColor = "yellow"
backgroundColor = "red"
lightBackgroundColor = "white"
myUrgentColor = "red"
myNormalBorderColor = "green"
myFocusedBorderColor = "magenta"

myWorkspaces = [ "1:smart"
               , "2:smart"
               , "3:smart"
               , "4:exact"
               , "5:exact"
               , "6:exact"
               , "7:all"
               , "8:all"
               , "9:all"
               , "0:all"
               , "+:full"
               ]

myLayoutHook = onWorkspace "1:smart" smartLayout $
               onWorkspace "2:smart" smartLayout $
               onWorkspace "3:smart" smartLayout $
               onWorkspace "4:exact" dividebytwoLayout $
               onWorkspace "5:exact" dividebytwoLayout $
               onWorkspace "6:exact" dividebytwoLayout $
               onWorkspace "+:full" fullLayout $
               layouts
    where
        layouts =
                smartBorders $
                avoidStrutsOn [] $
                layoutHook defaultConfig ||| Grid ||| ThreeCol 1 (3/100) (1/2)
        smartLayout =
                smartBorders $
                avoidStrutsOn [] $
                Tall 1 (3/100) (50/100) ||| Full
        chatLayout =
                smartBorders $
                avoidStruts $
                ThreeCol 1 (3/100) (3/100)
        dividebytwoLayout =
                smartBorders $
                avoidStruts $
                Grid
        fullLayout =
                smartBorders $
                noBorders $
                Full

myManageHook = (composeAll . concat $
    [[isFullscreen                 --> doFullFloat
    , className =? "Xmessage"      --> doCenterFloat
    , className =? "XCalc"         --> doCenterFloat
    , className =? "Zenity"        --> doCenterFloat
    , className =? "Xfce4-notifyd" --> doIgnore
    , className =? "stalonetray"   --> doIgnore
    , className =? "VirtualBox"    --> doShift "+:full"
    , className =? "Pidgin"        --> doF (shift "3:chat")
    , title     =? "Save As..."    --> doCenterFloat
    , title     =? "Save File"     --> doCenterFloat
    , title     =? "Buddy List"    --> doF (shift "3:chat")
    ]]) <+> myFloats <+> manageDocks <+> manageHook defaultConfig

myFloats = composeAll . concat $
    [[ fmap (c `isInfixOf`) className --> doFloat | c <- myFloats ]
    ,[ fmap (t `isInfixOf`) title     --> doFloat | t <- myOtherFloats ]
    ]
    where
        myFloats =
                [ "TopLevelShell"
                , "Blender:Render"
                , "gimp"
                , "Gimp"
                ]
        myOtherFloats =
                ["Scope"
                , "Editor"
                , "Simulink Library Browser"
                , "Figure"
                , "Blender:Render"
                , "Chess"
                ]

myLogHook xmproc = dynamicLogWithPP $ xmobarPP {
                     ppOutput = hPutStrLn xmproc
                   , ppTitle = xmobarColor lightTextColor ""
                   , ppCurrent = xmobarColor focusColor ""
                   , ppVisible = xmobarColor lightTextColor ""
                   , ppHiddenNoWindows = xmobarColor lightBackgroundColor ""
                   , ppUrgent = xmobarColor myUrgentColor ""
                   , ppSep = " :: "
                   , ppWsSep = " "
                   }

myKeys =
    [ ((myModMask, xK_p), spawn "exe=`~/bin/pydmenu.py` && eval \"exec $exe\"")
    , ((myModMask .|. shiftMask, xK_l), spawn "slock")
    , ((myModMask .|. shiftMask, xK_s), sendMessage ToggleStruts)
    , ((myModMask .|. shiftMask, xK_p), startupPrograms)
    , ((myModMask .|. shiftMask, xK_m), spawn "bash ~/bin/laptopDock.sh")
    , ((myModMask, xK_d), spawn "emacs --daemon")
    , ((myModMask, xK_z), spawn "emacsclient -c")
    , ((myModMask .|. shiftMask, xK_d), spawn "if ! pkill trayer; then trayer; fi")
    , ((controlMask, xK_Print), spawn "scrot -s")
    , ((0, xK_Print), spawn "scrot")
    , ((0, 0x1008FF11), spawn "amixer set Master 2- && mplayer /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga") -- XF86XK_AudioLowerVolume
    , ((0, 0x1008FF13), spawn "amixer set Master 2+ && mplayer /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga") -- XF86XK_AudioRaiseVolume
    , ((0, 0x1008FF12), spawn "amixer set Master toggle && amixer set PCM unmute && mplayer /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga") -- XF86XK_AudioMute
    ]
    ++
    [((m .|. myModMask, k), windows $ f i)
    | (i, k) <- zip myWorkspaces [xK_1, xK_2, xK_3, xK_4, xK_5, xK_6, xK_7, xK_8, xK_9, xK_0, xK_plus]
    , (f, m) <- [(greedyView, 0), (shift, shiftMask)]
    ]
    -- NOTE: this is for two things: a) switch from w,e,r to q,w,e for screen selection, and b) swap screens 'locations' if necessary
    ++
    [((m .|. myModMask, k), screenWorkspace sc >>= flip whenJust (windows . f)) -- Replace 'mod1Mask' with your mod key of choice.
    | (k, sc) <- zip [xK_w, xK_e, xK_r] [1,2,0] -- was [0..] *** change to match your screen order ***, mod-{w,e,r} changed to mod-{q,w,e} *** TODO: map xK_q to somehere!
    , (f, m) <- [(view, 0), (shift, shiftMask)]
    ]


-- FIXME: this does not work for some reason
startupPrograms = do
                  spawnOn "1:smart" "xterm"
                  spawnOn "1:smart" "xterm"
                  spawnOn "2:smart" "emacs"

main = do
       xmproc <- spawnPipe "xmobar ~/.xmonad/xmobar"
       xmonad $ defaultConfig {
               terminal = myTerminal
             , manageHook = myManageHook
             , layoutHook = myLayoutHook
             , borderWidth = myBorderWidth
             , focusedBorderColor = myFocusedBorderColor
             , normalBorderColor = myNormalBorderColor
             , modMask = myModMask
             , logHook = myLogHook xmproc >> ewmhDesktopsLogHook >> setWMName "LG3D" >> takeTopFocus
             , workspaces = myWorkspaces
             } `additionalKeys` myKeys
