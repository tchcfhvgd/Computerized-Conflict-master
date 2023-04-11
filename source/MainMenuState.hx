package;

import flixel.util.FlxSave;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;
import Shaders;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxAxes;
import flixel.util.FlxTimer;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'freeplay',
		'storymode',
		'credits',
		'art_gallery',
		'options',
		'vault'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var scrollingThing:FlxBackdrop;
	var text1:FlxBackdrop;
	var text2:FlxBackdrop;
	var colorTween:FlxTween;
	public var repeatAxes:FlxAxes = XY;
	var zoomTween:FlxTween;
	var bg:FlxSprite;
	var blank:FlxSprite;
	public var camHUD:FlxCamera;
	
	public var removeShaderHandler:FlxShader;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;
		
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite(-80, 75).loadGraphic(Paths.image('mainmenu/notrbg'));
		bg.scrollFactor.set();
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		
		scrollingThing = new FlxBackdrop(Paths.image('Main_Checker'), repeatAxes, 0, 0);
		scrollingThing.scrollFactor.set(0, 0.07);
		scrollingThing.alpha = 0.8;
		scrollingThing.setGraphicSize(Std.int(scrollingThing.width * 0.8));
		add(scrollingThing);
		
		var vignette:FlxSprite = new FlxSprite();
		vignette.loadGraphic(Paths.image('mainmenu/rosevignette'));
		vignette.scrollFactor.set();
		add(vignette);
		
		blank = new FlxSprite();
		blank.loadGraphic(Paths.image('mainmenu/blank'));
		blank.scrollFactor.set();
		blank.color = 0xFFFF8A00;
		add(blank);

		
		text1 = new FlxBackdrop(Paths.image('mainmenu/text1'), X, 0, 0);
		text1.scale.set(0.55, 0.55);
		text1.y -= 20;
		text1.scrollFactor.set(0, 0);
		add(text1);
		
		text2 = new FlxBackdrop(Paths.image('mainmenu/text2'), X, 0, 0);
		text2.scale.set(0.55, 0.55);
		text2.y += 660;
		text2.scrollFactor.set(0, 0);
		add(text2);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set();
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		FlxG.mouse.visible = true;
				
		FlxG.mouse.load(Paths.image("EProcess/alt", 'chapter1').bitmap, 1.5, 0);

		if (CoolUtil.songsUnlocked == null){
			trace('null null null');
			CoolUtil.songsUnlocked = new FlxSave();
			CoolUtil.songsUnlocked.bind("Computarized-Conflict");

			if (CoolUtil.songsUnlocked.data.songs == null) {
				CoolUtil.songsUnlocked.data.songs = new Map<String, Bool>();
				for (i in 0...VaultState.codesAndShit.length){
					CoolUtil.songsUnlocked.data.songs.set(VaultState.codesAndShit[i][1], false);
				}
			}

			if (CoolUtil.songsUnlocked.data.mainWeek == null) {
				CoolUtil.songsUnlocked.data.mainWeek = false;
			}
			trace(CoolUtil.songsUnlocked.data.mainWeek);

			CoolUtil.songsUnlocked.flush();
		}

		if(!CoolUtil.songsUnlocked.data.mainWeek) optionShit.remove('vault');

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			//var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(50, 50); //with this the positions will never work
			menuItem.loadGraphic(Paths.image('mainmenu/' + optionShit[i]));
			menuItem.ID = i;
			menuItem.x += i * 450 ;//with this the positions will never work
			//menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			var off = 0;
			if(CoolUtil.songsUnlocked.data.mainWeek) off = -100;
			switch(i){
				case 0:
					menuItem.x = 50;
					menuItem.y = 50 + off;
				case 1:
					menuItem.x = 450;
					menuItem.y = 50 + off;
				case 2:
					menuItem.x = 850;
					menuItem.y = 100 + off;
				case 3:
					menuItem.x = 245 + off;
					menuItem.y = 400 + off;
				case 4:
					menuItem.x = 645 + off;
					menuItem.y = 400 + off;
				case 5:
					menuItem.x = 1045 + off;
					menuItem.y = 400 + off;
			}
			menuItem.updateHitbox();
		}

		/*for (i in 0...VaultState.codesAndShit.length){
			CoolUtil.songsUnlocked.data.songs.set(VaultState.codesAndShit[i][1], false);
		}
		CoolUtil.songsUnlocked.flush();*/

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem(1-curSelected);

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end
		
		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		
		scrollingThing.x -= 0.45;
		scrollingThing.y -= 0.16;
		
		text1.x -= 0.45;
		text2.x -= 0.45;

		menuItems.forEach(function(menuItem:FlxSprite){
			var off = 0;
			if(CoolUtil.songsUnlocked.data.mainWeek) off = -100;
			switch(menuItem.ID){
				case 0:
					menuItem.x = 50;
					menuItem.y = 50 + off;
				case 1:
					menuItem.x = 450;
					menuItem.y = 50 + off;
				case 2:
					menuItem.x = 850;
					menuItem.y = 100 + off;
				case 3:
					menuItem.x = 245 + off;
					menuItem.y = 400 + off;
				case 4:
					menuItem.x = 645 + off;
					menuItem.y = 400 + off;
				case 5:
					menuItem.x = 1045 + off;
					menuItem.y = 400 + off;
			}
			menuItem.updateHitbox();
		});

		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				loadState();
			}
			
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end

			menuItems.forEach(function(spr:FlxSprite)
			{
				if (FlxG.mouse.overlaps(spr) && !selectedSomethin)
				{
					changeItem();

					FlxG.sound.play(Paths.sound('mouseClick'));
					
					curSelected = spr.ID;

					if (FlxG.mouse.justPressed){
						loadState();
					}
				}
			});
		}

		super.update(elapsed);
	}
	
	function loadState()
	{
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (curSelected != spr.ID)
			{
				FlxTween.tween(spr, {alpha: 0}, 0.4, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						spr.kill();
					}
				});
			}
			else
			{
				
				new FlxTimer().start(1.5, function(tmr:FlxTimer)
				{
					var daChoice:String = optionShit[curSelected];

					switch (daChoice)
					{
						case 'storymode':
							MusicBeatState.switchState(new TCOStoryState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayMenu());
						case 'awards':
							MusicBeatState.switchState(new AchievementsMenuState());
						case 'art_gallery':
							MusicBeatState.switchState(new FanArtState());
						case 'credits':
							MusicBeatState.switchState(new LanguageSelectState());
						case 'options':
							LoadingState.loadAndSwitchState(new options.OptionsState());
						case 'vault':
							MusicBeatState.switchState(new VaultState());
							FlxG.sound.playMusic(Paths.music('secret_menu'), 0);
					}
				});
			}
			
			/*if (curSelected == spr.ID)
			{
				spr.acceleration.y = 5550;
				spr.velocity.y -= 5550;
			}*/
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
			
		if(zoomTween != null) {
			zoomTween.cancel();
		}
		
		if(colorTween != null) {
			colorTween.cancel();
		}
		
		switch(optionShit[curSelected])
		{
			case 'storymode':
				
				colorTween = FlxTween.color(blank, 1, blank.color, 0xFFFF7E00, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
			    });
				
			case 'freeplay':
				
				colorTween = FlxTween.color(blank, 1, blank.color, 0xFF0AB5FF, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
			    });
				
			case 'credits':
				
				colorTween = FlxTween.color(blank, 1, blank.color, 0xFF4EFF00, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
			    });
				
			case 'art_gallery':
				
				colorTween = FlxTween.color(blank, 1, blank.color, 0xFFEAFF00, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
			    });
				
			case 'options':
				
				colorTween = FlxTween.color(blank, 1, blank.color, 0xFFFF0000, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
			    });
				
			case 'vault':
				
				colorTween = FlxTween.color(blank, 1, blank.color, 0xFF5E4F4F, {
					onComplete: function(twn:FlxTween) {
						colorTween = null;
					}
				});
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			if(ClientPrefs.shaders) spr.shader = new Shaders.GreyscaleShader();
			spr.alpha = 0.5;
			spr.updateHitbox();
			
			if (spr.ID != curSelected){
				zoomTween = FlxTween.tween(spr, {"scale.x": 0.25, "scale.y": 0.25}, 0.2, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween) {
						zoomTween = null;
					}
				});
			}
			//spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.shader = removeShaderHandler;
				
				zoomTween = FlxTween.tween(spr, {"scale.x": 0.3, "scale.y": 0.3}, 0.2, {ease: FlxEase.quadOut});
				
				spr.alpha = 1;
				spr.centerOffsets();
			}else{
				FlxTween.tween(spr, {"scale.x": 0.25, "scale.y": 0.25}, 0.2, {ease: FlxEase.quadOut});
			}

		});
	}
}