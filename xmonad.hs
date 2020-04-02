--
-- ~/.xmonad/xmonad.hs
--

import System.Posix.Env (getEnv)
import System.IO
import System.Directory
import Data.Maybe (maybe)
import Graphics.X11.ExtraTypes.XF86

import XMonad

import XMonad.Config.Desktop
import XMonad.Config.Kde

import XMonad.Layout.NoBorders
import XMonad.Layout.IM
import XMonad.Layout.SimpleFloat
import XMonad.Layout.Grid
import XMonad.Layout.Tabbed
import XMonad.Layout.ResizableTile

import XMonad.Actions.PhysicalScreens
import XMonad.Actions.CycleWS
import qualified XMonad.Actions.DynamicWorkspaceOrder as DO

import XMonad.Hooks.ManageDocks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.SetWMName

import XMonad.Util.EZConfig
import XMonad.Util.Scratchpad
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.WorkspaceCompare
import XMonad.Layout.Spacing

import qualified XMonad.StackSet as W

--
-- basic configuration
--

myModMask          = mod4Mask -- use the Windows key as mod
myBorderWidth      = 5        -- set window border size
myTerminal         = "alacritty" -- preferred terminal emulator
myFocusedBorderColor = "#689d6a"
myNormalBorderColor  = "#282828"
-- myFocusedBorderColor = "#fe8019"
-- myFocusedBorderColor = "#8ec07c"

--
-- hooks for newly created windows
-- note: run 'xprop WM_CLASS' to get className
--


--
-- startup hooks
--
-- myStartupHook = do
--     spawn "feh --bg-scale --no-xinerama --no-fehbg ~/Pictures/tree.png"
--     spawnOnce "picom --config ~/.config/picom/picom.conf"
--     spawnOnce "--no-startup-id wmctrl -c Plasma"
--     spawnOnce "unclutter"
--     spawnOnce "xcape -e 'Caps_Lock=Escape'"
--     -- spawnOnce "qdbus org.kde.kded5 /modules/networkmanagement init"


myManageHook :: ManageHook
myManageHook = manageDocks <+> coreManageHook

coreManageHook :: ManageHook
coreManageHook = composeAll . concat $
  [ [ className   =? c --> doFloat           | c <- myFloats]
  ]
  where
    myFloats      = [
       "yakuake"
     , "systemsettings"
     , "Gimp"
     , "Plasma-desktop"
     , "Plasma"
     , "win7"
     , "krunner"
     , "Kmix"
     , "Plasmoidviewer"
     , "pop-up"
     , "bubble"
     , "task_dialog"
     , "Preferences"
     , "About"
     , "dialog"
     , "menu"
     , "plasmashell"
     , "Desktop — Plasma"
     , "Klipper"
     , "Keepassx"
     ]


--
-- layout hooks
--

-- mySpacing x = spacingRaw True (Border 0 x x x) True (Border x x x x) True

myLayoutHook = smartBorders $ avoidStruts $ coreLayoutHook

coreLayoutHook = tiled ||| Mirror tiled ||| Full ||| Grid
  where
    -- default tiling algorithm partitions the screen into two panes
    tiled   = ResizableTall nmaster delta ratio []
    -- The default number of windows in the master pane
    nmaster = 1
    -- Default proportion of screen occupied by master pane
    ratio   = 1/2
    -- Percent of screen to increment by when resizing panes
    delta   = 3/100

--
-- log hook (for xmobar)
--

myLogHook xmproc = dynamicLogWithPP xmobarPP
  { ppOutput = hPutStrLn xmproc
  , ppTitle  = xmobarColor "green" "" . shorten 50
  }

--
-- desktop :: DESKTOP_SESSION -> desktop_configuration
--

desktop "kde"           = kdeConfig
desktop "kde-plasma"    = kdeConfig
desktop "plasma"        = kdeConfig
desktop _               = desktopConfig

--
-- main function (no configuration stored there)
--

main :: IO ()
main = do
  session <- getEnv "DESKTOP_SESSION"
  let defDesktopConfig = maybe desktopConfig desktop session
      myDesktopConfig = defDesktopConfig
        { modMask     = myModMask
        , terminal    = myTerminal
        , borderWidth = myBorderWidth
        , focusedBorderColor = myFocusedBorderColor
        , normalBorderColor = myNormalBorderColor
        -- , startupHook = myStartupHook
        , layoutHook  = myLayoutHook
        , manageHook  = myManageHook <+> manageHook defDesktopConfig
        } -- `additionalKeys` myKeys
  -- when running standalone (no KDE), try to spawn xmobar (if installed)
  xmobarInstalled <- doesFileExist "/usr/bin/xmobar"
  if session == Just "xmonad" && xmobarInstalled
    then do mproc <- spawnPipe "/usr/bin/xmobar ~/.xmonad/xmobar.hs"
            xmonad $ myDesktopConfig
              { logHook  = myLogHook mproc
              , terminal = myTerminal
              } --- `additionalKeys` myStandAloneKeys
    else do xmonad myDesktopConfig
