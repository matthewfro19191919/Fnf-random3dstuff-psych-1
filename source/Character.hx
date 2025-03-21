package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

import away3d.events.AnimationStateEvent;
import away3d.library.Asset3DLibrary;
import away3d.core.base.data.Face;
import away3d.errors.AbstractMethodError;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var canAutoAnim:Bool = true;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var alreadyLoaded:Bool = true; //Used by "Change Character" event

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	
	// 3D
	public var isModel:Bool = false;
	public var modelView:ModelView;
	public var beganLoading:Bool = false;
	public var modelName:String = "";
	public var modelScale:Float = 1;
	public var model:ModelThing;
	public var initYaw:Float = 0;
	public var initPitch:Float = 0;
	public var initRoll:Float = 0;
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var zOffset:Float = 0;
	public var viewX:Float = 750;
	public var viewY:Float = 750;
	public var ambient:Float = 1;
	public var specular:Float = 1;
	public var diffuse:Float = 1;
	public var animSpeed:Map<String, Float> = new Map<String, Float>();
	public var noLoopList:Array<String> = [];
	public var isGlass:Bool = false;
	public var spinYaw:Bool = false;
	public var spinYawVal:Int = 0;
	public var spinPitch:Bool = false;
	public var spinPitchVal:Int = 0;
	public var spinRoll:Bool = false;
	public var spinRollVal:Int = 0;
	public var yTween:FlxTween;
	public var xTween:FlxTween;
	public var modelType:String = "md2";
	public var md5Anims:Map<String, String> = new Map<String, String>();

	public static var modelMutex:Bool = false;
	public static var modelMutexThing:ModelThing;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		var library:String = null;
		switch (curCharacter)
		{
			case 'steve':
				modelName = "steve";
				modelScale = 30;
				modelSpeed = ["default" => 126 / 75];
				isModel = true;
				loadGraphicFromSprite(Main.modelView.sprite);
				initYaw = -45;
				initY = -28;
				updateHitbox();
				noLoopList = ["idle"];
				Main.modelView.light.ambient = 1;
				Main.modelView.light.specular = 0.0;
				Main.modelView.light.diffuse = 0.0;

			case 'doll':
				modelName = "doll";
				modelScale = 15;
				modelSpeed = ["default" => 1.66, "idle" => 1];
				isModel = true;
				loadGraphicFromSprite(Main.modelView.sprite);
				initYaw = -45;
				updateHitbox();
				noLoopList = ["singUP", 'singLEFT', 'singDOWN', 'singRIGHT'];
				Main.modelView.light.ambient = 1;
				Main.modelView.light.specular = 0;
				Main.modelView.light.diffuse = 0;

			case 'crash':
				modelName = "crash";
				modelScale = 15;
				modelSpeed = ["default" => 2.6, "idle" => 1.8];
				isModel = true;
				loadGraphicFromSprite(Main.modelView.sprite);
				initYaw = -45;
				initZ = -25;
				initY = -140;
				updateHitbox();
				noLoopList = ["idle", "singUP", 'singLEFT', 'singDOWN', 'singRIGHT'];
				Main.modelView.light.ambient = 1;
				Main.modelView.light.specular = 0;
				Main.modelView.light.diffuse = 0;

			case 'endo':
				modelName = "Collection";
				modelType = "md5";
				modelScale = 25;
				initYaw = -45;
				initY = -115;
				isModel = true;
				loadGraphicFromSprite(Main.modelView.sprite);
				updateHitbox();
				noLoopList = ["singUP", 'singLEFT', 'singDOWN', 'singRIGHT'];
				md5Anims["idle"] = "Collection_11";
				md5Anims["singUP"] = "Collection_4";
				md5Anims["singLEFT"] = "Collection_17";
				md5Anims["singDOWN"] = "Collection_6";
				md5Anims["singRIGHT"] = "Collection_14";
				modelSpeed = ["default" => 1, "singRIGHT" => 1.7, "singLEFT" => 2, "singUP" => 1.5, "singDOWN" => 1.5];
				Main.modelView.light.ambient = 0.5;
				Main.modelView.light.specular = 1;
				Main.modelView.light.diffuse = 1;
			
			case 'skeleton':
				modelName = "skeleton";
				modelType = "awd";
				modelScale = 150;
				initYaw = 90;
				initY = 50;
				isModel = true;
				loadGraphicFromSprite(Main.modelView.sprite);
				updateHitbox();
				noLoopList = ["singUP", 'singLEFT', 'singDOWN', 'singRIGHT'];
				modelSpeed = ["default" => 1];
				Main.modelView.light.ambient = 0.5;
				Main.modelView.light.specular = 1;
				Main.modelView.light.diffuse = 1;

			//case 'your character name in case you want to hardcode him instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';
				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				if(Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT))) {
					frames = Paths.getPackerAtlas(json.image);
				} else {
					frames = Paths.getSparrowAtlas(json.image);
				}
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						if(animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						} else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if(anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
				//trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;

		recalculateDanceIdle();
		initWidth = width;
		initFrameWidth = frameWidth;
		initHeight = height;
		setFacingFlip((initFacing == FlxObject.LEFT ? FlxObject.RIGHT : FlxObject.LEFT), true, false);
		// if (atlasContainer != null)
		// 	atlasContainer.setFacingFlip((initFacing == FlxObject.LEFT ? FlxObject.RIGHT : FlxObject.LEFT), true, false);

		dance();

		facing = (isPlayer ? FlxObject.LEFT : FlxObject.RIGHT);

		if (isModel)
		{
			modelView = new ModelView(viewX, viewY, ambient, specular, diffuse);
			loadGraphicFromSprite(modelView.sprite);
			antialiasing = true;
		}

		if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!isModel && !curCharacter.startsWith('bf'))
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}

			/*// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
				{
					var oldRight = animation.getByName('singRIGHT').frames;
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animation.getByName('singLEFT').frames = oldRight;
				}

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}*/
		}
	}

	override function update(elapsed:Float)
	{
		tryLoadModel();

		if (isModel && model != null && model.fullyLoaded && modelView != null)
		{
			modelView.update();
			model.update();
		}

		if(!debugMode && animation.curAnim != null)
		{
			if(heyTimer > 0)
			{
				heyTimer -= elapsed;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			} else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing'))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * 0.001 * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
		if (!isPlayer && !isModel)
		{
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (curCharacter == 'dad')
				dadVar = 6.1;
			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
			{
				idleEnd();
				holdTimer = 0;
			}
		}
		else if (!isPlayer && isModel)
		{
			if (model.currentAnim.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			var dadVar:Float = 4;

			if (curCharacter == 'dad')
				dadVar = 6.1;
			if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001)
			{
				idleEnd();
				holdTimer = 0;
			}
		}
		super.update(elapsed);

		if (isModel)
		{
			if (spinYaw)
			{
				model.addYaw(elapsed * spinYawVal);
			}

			if (spinPitch)
			{
				model.addPitch(elapsed * spinPitchVal);
			}

			if (spinRoll)
			{
				model.addRoll(elapsed * spinRollVal);
			}
		}
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(animation.getByName('idle' + idleSuffix) != null) {
					playAnim('idle' + idleSuffix);
			}
			if (isModel && model == null)
			{
				trace("NO DANCE - NO MODEL");
				return;
			}
			if (isModel && !model.fullyLoaded)
			{
				trace("NO DANCE - NO FULLY LOAD");
				return;
			}
			if (isModel && !noLoopList.contains('idle'))
				return;
				playAnim('idle', true);
		}
	}
	
	public function idleEnd(?ignoreDebug:Bool = false)
	{
		if (!isModel && (!debugMode || ignoreDebug))
		{
			switch (curCharacter)
			{
				case 'gf' | 'gf-car' | 'gf-christmas' | 'gf-pixel' | "spooky":
					playAnim('danceRight', true, false, animation.getByName('danceRight').numFrames - 1);
				default:
					playAnim('idle', true, false, animation.getByName('idle').numFrames - 1);
			}
		}
		else if (isModel && (!debugMode || ignoreDebug))
		{
			playAnim('idle', true, false);
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		if (isModel)
		{
			model.playAnim(AnimName, Force, Frame);
		}

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	public function recalculateDanceIdle() {
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
	public function tryLoadModel()
	{
		if (!isModel)
			return;
		if (modelMutex)
			return;
		if (isModel && beganLoading)
			return;
		if (isModel && !beganLoading)
		{
			beganLoading = true;
			modelMutex = true;
			model = new ModelThing(this);
			modelMutexThing = model;
		}
	}

	public function tryLoadModel()
	{
		if (!isModel)
			return;
		if (modelMutex)
			return;
		if (isModel && beganLoading)
			return;
		if (isModel && !beganLoading)
		{
			beganLoading = true;
			modelMutex = true;
			model = new ModelThing(this);
			modelMutexThing = model;
		}
	}

	override public function destroy()
	{
		if (isModel)
		{
			if (modelMutexThing == model)
			{
				modelMutexThing = null;
				modelMutex = false;
			}
			if (model != null)
				model.destroy();
			model = null;
			if (modelView != null)
				modelView.destroy();
			modelView = null;
			if (animSpeed != null)
			{
				animSpeed.clear();
				animSpeed = null;
			}
		}
		if (animRedirect != null)
		{
			animRedirect.clear();
			animRedirect = null;
		}
		if (animRedirect != null)
		{
			animRedirect.clear();
			animRedirect = null;
		}
		// atlasContainer = FlxDestroyUtil.destroy(atlasContainer);
		super.destroy();
	}
}
