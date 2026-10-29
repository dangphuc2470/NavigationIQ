import Toybox.Graphics;
import Toybox.Lang;

// =============================================================================
// UI CONSTANTS & DESIGN SYSTEM TOKENS (Easily Configurable)
// =============================================================================

const APP_VERSION_STR = "v1.0.4";

// 1. Device Screen
const SCREEN_W = 320;
const SCREEN_H = 360;

// 2. Main Navigation Card Layout (Edge-to-Edge Flush, Distinct Rounded Cards)
const CARD_X = 0;
const CARD_Y = 0;
const CARD_W = 320;
const CARD_H = 294;
const CARD_RADIUS = 28;

// 3. Turn Badge Geometry
const BADGE_OFFSET_X = 52;
const BADGE_OFFSET_Y = 52;
const BADGE_RADIUS = 36;
const BADGE_SPINNER_PEN_WIDTH = 6;

// 4. Distance Row Layout
const DIST_OFFSET_X = 104;
const DIST_UNIT_GAP = 6;

// 5. Divider Line
const DIVIDER_OFFSET_Y = 106;
const DIVIDER_PADDING_X = 14;

// 6. Navigation Text Box Geometry
const NAV_TEXT_PADDING_X = 14;
const NAV_TEXT_OFFSET_Y = 0;
const NAV_TEXT_BOTTOM_PADDING = 14;

// 7. Bottom Pill Bar Layout (Distinct Rounded Pill Card - Compact & Balanced)
const BAR_Y = 302;
const BAR_H = 52;
const BAR_RADIUS = 26;

// 8. ETA Capsule Badge (Symmetric in left half of 320px screen)
const ETA_BADGE_W = 138;
const ETA_BADGE_H = 38;
const ETA_BADGE_RADIUS = 19;
const ETA_BADGE_PADDING_X = 10;

// 9. Ambient Glow Radial Gradient (AMOLED Subtle Bloom)
const GLOW_STEPS = 24;
const GLOW_RADIUS_FACTOR = 0.8;

// 10. Color Tokens
const COLOR_BG_AMOLED = 0x000000;
const COLOR_BG_CARD = 0x18181B;
const COLOR_BORDER_CARD = 0x27272A;
const COLOR_DIVIDER = 0x27272A;

const COLOR_TEXT_WHITE = 0xFFFFFF;
const COLOR_TEXT_SILVER = 0xE4E4E7;
const COLOR_TEXT_MUTED = 0x71717A;
const COLOR_TEXT_UNIT = 0x94A3B8; // Muted slate grey

// Theme Palettes (Milky Desaturated Pastel for True Aero HUD)
// Straight / 2nd-3rd Exit (Teal/Cyan Theme)
const COLOR_THEME_CYAN_ACCENT = 0x06B6D4;
const COLOR_THEME_CYAN_BADGE = 0x4A858F;
const COLOR_THEME_CYAN_ETA_BG = 0x1E3B42;
const GLOW_RGB_CYAN = [0x06, 0x88, 0x99];

// Turn Left / U-turn (Amber/Warm Theme)
const COLOR_THEME_AMBER_ACCENT = 0xF59E0B;
const COLOR_THEME_AMBER_BADGE = 0x9E7852;
const COLOR_THEME_AMBER_ETA_BG = 0x3E3022;
const GLOW_RGB_AMBER = [0xA8, 0x62, 0x18];

// Turn Right / 1st Exit (Green Theme)
const COLOR_THEME_GREEN_ACCENT = 0x10B981;
const COLOR_THEME_GREEN_BADGE = 0x5C8E74;
const COLOR_THEME_GREEN_ETA_BG = 0x243E30;
const GLOW_RGB_GREEN = [0x10, 0x90, 0x55];

// Warning / Disconnected (Red Theme)
const COLOR_THEME_RED_ACCENT = 0xFF453A;
const COLOR_THEME_RED_BADGE = 0x7A2A2A;

// -----------------------------------------------------------------------------
// Theme Palette Selector (Bright Milky Desaturated Pastel Badge + Glow)
// -----------------------------------------------------------------------------
function getNavTheme(dir as Number) as Array<Object> {
    if (dir == DIR_STRAIGHT || dir == DIR_ROUNDABOUT_2 || dir == DIR_ROUNDABOUT_3) {
        return [COLOR_THEME_GREEN_ACCENT, COLOR_THEME_GREEN_BADGE, GLOW_RGB_GREEN, COLOR_THEME_GREEN_ETA_BG] as Array<Object>;
    } else if (dir == DIR_LEFT || dir == DIR_SLIGHT_LEFT || dir == DIR_SHARP_LEFT ||
               dir == DIR_ROUNDABOUT_4 || dir == DIR_ROUNDABOUT_5 || dir == DIR_UTURN) {
        return [COLOR_THEME_AMBER_ACCENT, COLOR_THEME_AMBER_BADGE, GLOW_RGB_AMBER, COLOR_THEME_AMBER_ETA_BG] as Array<Object>;
    } else if (dir == DIR_RIGHT || dir == DIR_SLIGHT_RIGHT || dir == DIR_SHARP_RIGHT ||
               dir == DIR_ROUNDABOUT_1) {
        return [COLOR_THEME_GREEN_ACCENT, COLOR_THEME_GREEN_BADGE, GLOW_RGB_GREEN, COLOR_THEME_GREEN_ETA_BG] as Array<Object>;
    } else {
        return [COLOR_THEME_GREEN_ACCENT, COLOR_THEME_GREEN_BADGE, GLOW_RGB_GREEN, COLOR_THEME_GREEN_ETA_BG] as Array<Object>;
    }
}
