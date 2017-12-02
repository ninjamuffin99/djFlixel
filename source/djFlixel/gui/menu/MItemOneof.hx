package djFlixel.gui.menu;

import djFlixel.gui.Styles;
import djFlixel.tool.DEST;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;


class MItemOneof extends MItemBase
{
	// How far out the arrows will move
	// Multiplier on the font_size, seems ok - ARBITRARY but looks ok -
	inline static var NUDGE_RATIO:Float = 0.4;
	// Default arrow loop time
	inline static var DEF_NUDGE_TIME:Float = 0.4;
	
	// Displayed text
	var label2:FlxText;

	// Hold 2 arrows and their status
	var arrows:Array<FlxSprite>;
	var arrowStat:Array<Bool>;
	
	// Animate the cursors with a tween
	var arrow_tween:NumTween;	
	
	//---------------------------------------------------;
	public function new(_s:StyleVLMenu,_w:Int)
	{
		super(_s, _w);
		
		// The variable selection
		label2 = new FlxText();
		Styles.applyTextStyle(label2, style);
		add(label2);
		
		// --
		arrows = [];
		arrowStat = [];
		
		// -- Setup the graphics ::
		
		var c = style.icons; // Shortcut
		
		if ( c && c.sliderText) // Use text for the arrows
		{
			for (a in 0...2) {
				var t = new FlxText(0, 0, 0, c.sliderText[a]);
				Styles.applyTextStyle(t, style);
				t.color = style.color;
				arrows[a] = cast t;
				arrows[a].visible = false;
				add(arrows[a]);
			}
		}
		else	// Use icons
		{
			for (a in 0...2) {
				var ics = Gui.getApproxIconSize(style.fontSize);
				var bm = Gui.getIcon(["ar_left", "ar_right"][a],
								ics,
								(c?c.image:null),
								style.color_icon_shadow,
								cast label.borderSize,	// Get thelabel size because it could be autogenerated
								cast label.borderSize);
				arrows[a] = new FlxSprite(0, 0, bm);
				arrows[a].visible = false;
				arrows[a].y = (height / 2) - (ics / 2) + 3; // Verical Align, +3 works a bit better
				arrows[a].replaceColor(0xFFFFFFFF, style.color_focused); // #COLOR
				add(arrows[a]);
			}
		}
		
		// Maximum distance to travel
		var arrow_maxNudge = Std.int(style.fontSize  * NUDGE_RATIO);
		// One complete arrow cycle in this much time, bigger->slower
		var arrow_time:Float = (c && c.sliderTime?c.sliderTime:DEF_NUDGE_TIME);

		arrow_tween = FlxTween.num(0, arrow_maxNudge, arrow_time, { type:FlxTween.LOOPING },
				function(v:Float) {
					arrows[0].x = label2.x - arrows[0].width - v;
					arrows[1].x = label2.x + label2.fieldWidth + v;
				});
		arrow_tween.active = false;
			
	}//---------------------------------------------------;
	
	// --
	override public function destroy():Void 
	{
		arrow_tween = DEST.numTween(arrow_tween);
		super.destroy();
	}//---------------------------------------------------;
	
	// Alignment Helper Flags :: 
	var flag_j:Bool;
	var flag_r:Bool;
	
	// --
	override function initElements() 
	{
		super.initElements();
	
		label2.y = label.y;
		flag_j = flag_r = false;
		
		switch(style.alignment)
		{
			case "justify":
				flag_j = true;
				
			case "right":
				flag_r = true;
				
			default:
			label2.x = label.x + EL_PADDING + label.fieldWidth + arrows[0].width;
		}

		// This will also update label pos if needed :
		updateItemData();
	}//---------------------------------------------------;
	
	// --
	// Separate function because MitemSlider uses it as well
	function updateLabel2Pos()
	{
		if (flag_j)
		{
			label2.x = x + parentWidth - arrows[0].width - label2.fieldWidth;
		}else
		if (flag_r)
		{
			label2.x = label.x - arrows[0].width - label2.fieldWidth - EL_PADDING;
		}
	}//---------------------------------------------------;
	
	// --
	override function state_default() 
	{
		super.state_default();
		label2.color = style.color_accent;
		arrows[0].visible = false;
		arrows[1].visible = false;
		arrow_tween.active = false;
	}//---------------------------------------------------;
	// --
	override function state_focused() 
	{
		super.state_focused();
		label2.color = style.color_focused;
		arrow_tween.active = true;
		// Check visibility and reset nudge
		_updateArrows();
	}//---------------------------------------------------;
	// --
	override function state_disabled() 
	{
		super.state_disabled();
		label2.color = style.color_disabled;
		arrows[0].visible = false;
		arrows[1].visible = false;
		arrow_tween.active = false;
	}//---------------------------------------------------;
	
	// --
	override function handleInput(inputName:String) 
	{
		
		switch(inputName) {
			
			case "right":
				if (opt.data.current < opt.data.pool.length - 1) {
					opt.data.previous = opt.data.current;
					opt.data.current ++;
					updateItemData();
					cb("change");
				};
				
			case "left":
				if (opt.data.current > 0) {
					opt.data.previous = opt.data.current;
					opt.data.current--;
					updateItemData();
					cb("change");
				}
				
			case "click":
				var r = collideWithCursor();
				if (r < 0) handleInput("left"); else if (r > 0) handleInput("right"); 
		}
	}//---------------------------------------------------;
	// --
	// Called once on data set, and then everytime the data changes
	function updateItemData()
	{
		arrowStat[0] = (opt.data.current > 0);
		arrowStat[1] = (opt.data.current < opt.data.pool.length - 1);	
		label2.text = opt.data.pool[opt.data.current];
		
		// Check visibility and reset nudge
		_updateArrows();
		updateLabel2Pos();
	}//---------------------------------------------------;
	
	// --
	function _updateArrows()
	{
		// Note: Arrow 2 X is calculated on update();
		// A timer of 0 forces the arrows to update on the next cycle
		
		if (isFocused)
		{
			arrows[0].visible = arrowStat[0];
			arrows[1].visible = arrowStat[1];
		}
	}//---------------------------------------------------;
	
	// Return -1 if mouse on left cursor, +1 if mouse on right cursor
	function collideWithCursor():Int 
	{
		#if debug
		if (camera.x != 0 || camera.y != 0) {
			return 0;
			trace("Error: Mouse overlaps don't work when camera isn't at (0,0). It's a flixel bug");
		}
		#end
		
		if (arrows[0].visible && FlxG.mouse.overlaps(arrows[0], camera)) return -1;
		else
		if (arrows[1].visible && FlxG.mouse.overlaps(arrows[1], camera)) return 1;
		
		return 0;
	}//---------------------------------------------------;
	

}// -- end --