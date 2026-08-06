## Style d'interface V4.4 (réf. 03/04/05 du pack V4, §17.1) — LA source unique
## des plaques, chips et couleurs de l'UI : ardoise sombre translucide, filet
## d'or pâle, ivoire, rubis pour la vie, turquoise pour l'endurance, cyan très
## limité. Constructeurs statiques : chaque panneau demande son StyleBox ici,
## aucun style recopié à la main.
class_name HudStyle
extends RefCounted

const IVORY: Color = Color(0.93, 0.91, 0.85)
const GOLD: Color = Color(0.847, 0.702, 0.416)        # #D8B36A
const SLATE: Color = Color(0.075, 0.085, 0.11, 0.82)  # plaque translucide
const SLATE_SOLID: Color = Color(0.09, 0.10, 0.13, 0.95)
const RUBY: Color = Color(0.78, 0.20, 0.26)
const RUBY_DARK: Color = Color(0.24, 0.09, 0.11, 0.85)
const TURQUOISE: Color = Color(0.086, 0.561, 0.608)   # #168F9B
const TURQUOISE_DARK: Color = Color(0.05, 0.15, 0.17, 0.8)
## Cyan électrique (#22D9EC) et son cœur clair — RÉSERVÉS à la Résonance
## active (P3 §1.4 : « moins de 5 % de cyan saturé simultanément à l'écran »).
## Aucun autre élément de HUD ne doit les employer.
const CYAN: Color = Color(0.133, 0.851, 0.925)
const CYAN_CORE: Color = Color(0.925, 1.0, 1.0)


## Plaque d'ardoise au filet d'or — le fond de tout élément de HUD.
static func plaque(border_alpha: float = 0.55) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SLATE
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, border_alpha)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


## Chip de touche (« E », « Tab ») : petit cartouche au bord ivoire.
static func chip() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SLATE_SOLID
	style.border_color = IVORY
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


## Remplissage de jauge (rubis, turquoise, or) sur fond assorti.
static func gauge_fill(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


static func gauge_background(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


## Applique la teinte ivoire + plaque aux boutons d'un panneau (pause, mort,
## inventaire) — focus au filet d'or (§17.3 : « focus visible »).
static func style_button(button: Button) -> void:
	button.add_theme_color_override(&"font_color", IVORY)
	button.add_theme_color_override(&"font_hover_color", GOLD)
	button.add_theme_color_override(&"font_focus_color", GOLD)
	var focus: StyleBoxFlat = plaque(1.0)
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override(&"focus", focus)
