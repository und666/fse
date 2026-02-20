<div align="center">

# FSE (Flash Starling Enhance) Hybrid Rendering Framework

**A lightweight GPU hybrid rendering framework for Flash AS3. It aims to quickly build 2D high-frame-rate applications with an experience close to Unity using traditional Flash development methods.**

[![GitHub stars](https://img.shields.io/github/stars/und666/FlashStarlingEnhance?style=social)](https://github.com/und666/FlashStarlingEnhance/stargazers)
![visitors](https://visitor-badge.laobi.icu/badge?page_id=FlashStarlingEnhance&left_color=green&right_color=red)


https://github.com/user-attachments/assets/65afb2fe-926f-4096-930b-0b4742105d73


</div>


**Features**

- Quick start, integrates with traditional AS3 projects.
- Easily create Starling projects without writing Starling code.
- Suitable for rapid development of personal-level, lightweight high-frame-rate GPU projects with rich bitmaps.
- Supports traditional Flash window adaptive strategies.
- Supports traditional filters like glow, blur, and drop shadow.

**Author's Notes**

- What year is it? That's right, it's 2026, five years since Flash technology officially exited the stage. It is precisely at this point in time that the FSE (Flash Starling Enhance) hybrid rendering framework is born, like a technological "echo" across time and space.

- I am a junior from China who loves indie game creation and is gradually transitioning to the Unity tech stack. This year marks my tenth year of working with ActionScript 3.0 development. Throughout these years, I have always carried a sense of regret—despite having a considerable understanding of this technology, I have never created anything remarkable with it.

- Recently, I immersed myself in the Starling Wiki and numerous resources about the Starling framework on GitHub, while also hitting a bottleneck. I gradually realized that creating outstanding work with Flash in today's environment is quite challenging. But as an Ascr, I still want to draw a more complete conclusion for my younger self and for this technological journey.

- Sometimes, we need to find a way to make peace with ourselves, don't we? This framework is my answer.

- **Alright, to put it plainly: This framework is developed by me for learning purposes. Discussion and learning are welcome.**

**Foreword**

If you are a seasoned Flash development engineer, you are probably familiar with the GPU mode of the Adobe AIR SDK.
Let me briefly introduce this mode. In AIR for Android/AIR for iOS configurations, the GPU setting is available.
Enabling this mode can indeed make the entire screen appear smoother, but the frame rate is still limited to 60 FPS, and there are compatibility bugs with some features like filters.
For AIR for Desktop, the GPU mode is actually hidden. According to rumors, Adobe pushed it halfway but abandoned it due to many compatibility bugs.
Moreover, this mode is not available in the export settings of the traditional Flash IDE.

\------------------ Cute Dividing Line ------------------

So, as an Ascr, when quickly building high-performance, high-frame-rate Flash applications, we often encounter these issues.
**Flash IDE development** for traditional applications offers a poor experience {**frame rate capped at 60, unstable frame rate**, **large-resolution scene bitmap movement causing direct frame skips**}.
After switching to the **Starling framework**, performance improves, but creating animations becomes exceptionally tricky—**lack of mature, visual animation solutions** is almost a fatal shortcoming.
Is it possible to balance **GPU's high-frame rendering efficiency** with **Flash IDE's existing animation solutions** when developing personal-level **mobile, desktop applications, or games**?
Answer: Yes, brother, yes~ **FSE officially enters the stage (a pun)**.

**Getting Started Guide**

**1. First, prepare the FSE framework.**
- It consists of 3 files in total.
  ```
  fse
  starling
  fse.as
  (Note: This starling package has been adjusted by me and is not compatible with the official Starling version.)
  (The fse.as file is a quick entry file for FSE.as.)
  ```

**2. Copy the FSE framework into your project.**
- In a Flash IDE project:
  ```
  /your_project_path
  ===========================
  fse
  starling
  fse.as
  ===========================
  xxx.fla
  xxx.swf
  ```

- In IDEA/FB/FD projects:
  ```
  /your_project_path/src
  ===========================
  fse
  starling
  fse.as
  ===========================
  YourMainClass.as
  ```

**3. Inject the Starling framework into your project.**
- In a Flash IDE project:
  ```haxe
  // On the first frame of the stage root directory.
  import fse.core.FSE;
  FSE.init(stage, this);
  // These two lines are equivalent to:
  fse.init(stage, this);

  // Please ensure the second parameter you provide is the root of the stage container clip.
  ```

- In IDEA/FB/FD projects:
  ```haxe
  // In your class file.
  package {
      import flash.display.Sprite;
      import flash.events.Event;
      import fse.core.FSE;

      public class Main extends Sprite {

          public function Main() {
             if (stage) {
                 onAddedToStage();
              } else {
                  addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
              }
          }
          private function onAddedToStage(event:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            FSE.init(stage, this);
            // Your code.
          }
      }
  }
  ```

**API**

- **Features**
  - After FSE takes over, all MovieClips will be forced to pause playback by default.
  - Playback is driven by FSE's built-in animation manager.
  - By default, FSE automatically manages the playback of all MovieClips, but you can manually control playback using the following methods.

- **Common APIs**
  ```haxe
  //===== Initialization ================================================================

  fse.init(stage, Object(root));
  // Regular initialization.

  fse.init(stage, Object(root), false);
  // Special initialization: does not perform GPU rendering, only boosts frame rate and takes over the animation system.


  //===== Animation Control =============================================================

  mc.play();
  // Must be rewritten as:
  fse.play(mc);
  // Play animation.

  mc.stop();
  // Must be rewritten as:
  fse.stop(mc);
  // Stop animation.

  mc.gotoAndStop(index);
  // Must be rewritten as:
  fse.gotoAndStop(mc, index);
  // Jump to a specified frame.

  mc.gotoAndPlay(index);
  // Must be rewritten as:
  fse.gotoAndPlay(mc, index);
  // Jump to a specified frame and play.

  var v:Boolean = mc.visible;
  // Must be rewritten as:
  var v:Boolean = fse.getVisible(mc);
  // Get MovieClip object visibility.

  mc.visible = false;
  // Must be rewritten as:
  fse.visible(mc, false);
  // Change MovieClip object visibility.

  //===== Loop Control =================================================================

  // High-frequency loop (refreshes 240 times per second at 240 FPS).

  // Start:
  mc.addEventListener(Event.ENTER_FRAME, Update);

  // Stop:
  mc.removeEventListener(Event.ENTER_FRAME, Update);


  // Low-frequency loop (runs at 60 times per second regardless of situation [frequency adjustable in Config.as]).

  // Start:
  fse.addEventListener(mc, FSE_Event.FIX_ENTER_FRAME, Update);
  fse.addLoop(mc, Update);
  fse.loop(Update);
  // The above 3 lines are equivalent.

  // Stop:
  fse.removeEventListener(mc, FSE_Event.FIX_ENTER_FRAME, Update);
  fse.removeLoop(mc, Update);
  fse.stopLoop(Update);
  // The above 3 lines are equivalent.
  ```

- **Layer "Sandwich" Issue**
  ```
    In the runtime architecture of Flash Player / AIR:
    Top Layer: Native Display List (CPU).
    Bottom Layer: Stage3D (GPU/Starling).
    Video Layer: StageVideo (if present, usually at the very bottom).

    Therefore, based on this, the FSE framework divides the Stage3D layer into 3 layers.
    Each layer is a starling.display.Sprite container.

    On the 1st layer of the stage, the bottommost layer, there is a back user operation layer, accessible via fse.starlingRootBack.
    On the 2nd layer of the stage, the core mapping layer, the FSE framework maps your stage structure to this layer.
    On the 3rd layer of the stage, there is a front user operation layer, accessible via fse.starlingRoot.
    On the CPU rendering layer, the topmost layer, because the CPU layer covers the GPU rendering layer, elements with compatibility issues can be rendered using the CPU layer.
  ```

- **Advanced APIs**
  ```haxe
  fse.cpu(mc:MovieClip);
  fse.ban(mc:MovieClip); // Equivalent to the line above.
  fse.isIgnore(mc:MovieClip):Boolean // Get the special status of the mc object.
  // Use CPU rendering.
  /*
      To solve certain compatibility issues,
      clips marked by the user will not be rendered on FSE's Starling stage but will be rendered directly on the traditional stage.
      Note: Doing so will cause the mc to always appear above the GPU layer.
  */



  fse.setKeyRole(mc:MovieClip);
  // Set the current movie clip as a key role.
  fse.getKeyRole():String
  // Get the set key role.
  /*
      The FSE framework allows users to register a key role clip. Once this clip changes, Starling immediately renders the next frame.
      This method is generally applied to clips related to player input operations, such as mouse following, keyboard-controlled movement, etc.,
      to achieve immediate response upon user input.
  */



  fse.setNodeCached(mc:MovieClip, v:Boolean);
  // Set caching exception.
  /*
      After setting an exception, this object and all child nodes (Bitmap, Shape) of the current container node do not participate in the caching system.
  */



  fse.gpuClear();
  // Force clear all caches on the cache panel.



  //===== Mixing with Starling ==========================================================
  fse.starlingRoot: starling.display.Sprite
  // Top-level Starling stage root container provided for users (recommended for adding particle effects and special effects).

  fse.starlingRootBack: starling.display.Sprite
  // Bottom-level Starling stage root container provided for users (recommended for adding background and other low-level content elements).

  ```

**Config.as**
```haxe
package fse.conf
{
    import flash.system.Capabilities;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.display.DisplayObject;
    import flash.display.SimpleButton;

    import starling.textures.TextureSmoothing;

    /**
     * FSE Global Configuration Class
     * Used to uniformly manage static parameters like logic frame rate and rendering precision.
     */
    public class Config
    {

        // -------------------------------------------------
        // Stage Display Related
        // -------------------------------------------------
        public static const DEVICE_W:uint = Capabilities.screenResolutionX; // Device window size.
        public static const DEVICE_H:uint = Capabilities.screenResolutionY;

        public static const FULL_SCREEN:Boolean = false;
        public static var AUTO_ADAPT:String = "AUTO"; // Stage adaptive strategy.
        // ***Options:
        //"FULL" Fill window adaptation, fills the window regardless (does not guarantee stage ratio).
        //"SYN_HEIGHT" Stage image snug against top and bottom of the screen, maintaining stage ratio.
        //"SYN_WIDTH" Stage image snug against left and right sides of the screen, maintaining stage ratio.
        // "AUTO" Scaling boundary automatically decided, always maintains stage ratio.
        // "NONE" Framework does not interfere with adaptation behavior, but still controls rendering window and stage width/height synchronization (I'm not sure what this option is for either).


        // Stage alignment. Generally, do not modify this setting unless for special development needs.
        // Special note: If the stage adaptive strategy conflicts with this setting, this setting is invalid (e.g., if your stage is always snug against the left and right sides, setting left alignment loses meaning).
        public static var ALIGN_X:String = "CENTER";
        // ***Options:
        //"CENTER" Anchor to the center of the screen. This is the most recommended setting.
        //"LEFT" Snug against the left side of the screen.
        //"RIGHT" Snug against the right side of the screen.


        public static var ALIGN_Y:String = "CENTER";
        // ***Options:
        //"CENTER" Anchor to the center of the screen. This is the most recommended setting.
        //"TOP" Snug against the top of the screen.
        //"BOTTOM" Snug against the bottom of the screen.


        public static const BG_COLOR:uint = 0x211F20; // Background color.

        public static const EXT_FPS:uint = 400; // Starling maximum frame limit (usually set higher than most screen refresh rates).



        // -------------------------------------------------
        // Graphics Configuration Related (Quality)
        // -------------------------------------------------
        public static var TEXTURE_SMOOTHING:String = TextureSmoothing.BILINEAR; // Texture smoothing setting.
        // ***Options:
        //TextureSmoothing.NONE (No smoothing / nearest-neighbor interpolation) ### Recommended for pixel art style games.
        //TextureSmoothing.BILINEAR (Bilinear filtering - default).
        //TextureSmoothing.TRILINEAR (Trilinear filtering).



        // -------------------------------------------------
        // Cache Policy Related
        // -------------------------------------------------
        public static const CACHE_THRESHOLD:uint = 3; // Persistence threshold: If more than this number of identical textures appear simultaneously in the scene, the texture will be persisted in the cache.
        public static const WATCHER_COLD_TIME:uint = 20;


        // -------------------------------------------------
        // Debug Related
        // -------------------------------------------------
        public static const TRACE_CORE:Boolean = false; // Some non-critical startup information.
        public static const TRACE_DEBUG:Boolean = true; // Starling GPU performance information.
        public static const TRACE_WATCHER:Boolean = false; // Node count monitoring debug information.
        public static const TRACE_NODE:Boolean = false; // Single node behavior debug information.
        public static const TRACE_CACHE:Boolean = false; // Cache manager information.

        // ------------------------------------------------
        // Game Configuration
        // ------------------------------------------------
        public static const STOP_ALL:Boolean = true; // Pause all movie clips by default after takeover.

        private static var _logicFrameRate:int = 60; // Logic frame rate.
        private static var _logicTimestep:Number = 1000.0 / _logicFrameRate;

        private static var _case_render:Array = [isInputText, isSimpleButton]; // If assertions pass, do not render with Starling.

        // Input text assertion.
        private static function isInputText(obj:DisplayObject):Boolean {
            if (obj is TextField) {
                var textField:TextField = obj as TextField;
                // TextFieldType.INPUT is a static constant with value "input".
                return textField.type == TextFieldType.INPUT;
            }
            return false;
        }

        // Button assertion.
        private static function isSimpleButton(obj:*):Boolean{
            // Check if it's an instance of flash.display.SimpleButton.
            return obj is SimpleButton;
        }

        // ------------------------------------------------
        // Public Parameters
        // ------------------------------------------------

        /**
         * Maximum catch-up time (milliseconds).
         * If the device is extremely laggy, process only this much logic per frame at most to prevent infinite loops.
         * Default 200ms (i.e., worst-case catching up about 12 logic frames per frame).
         */
        public static var maxAccumulator:Number = 200;

        /**
         * Texture scaling factor (for future Retina/high-DPI screen support).
         * 1 = original, 2 = 2x high-definition.
         */
        public static var contentScaleFactor:Number = 1.0;

        // ------------------------------------------------
        // Getter / Setter
        // ------------------------------------------------

        public static function get case_render():Array{
            return _case_render;
        }

        /**
         * Target logic frame rate (default 60).
         * Modifying this value automatically updates timestep.
         */
        public static function get logicFrameRate():int
        {
            return _logicFrameRate;
        }

        public static function set logicFrameRate(value:int):void
        {
            if (value < 1) value = 1; // Safety limit.
            if (_logicFrameRate == value) return;

            _logicFrameRate = value;
            _logicTimestep = 1000.0 / _logicFrameRate;

            trace("[FSE_Config] Logic FPS set to: " + _logicFrameRate + " (Timestep: " + _logicTimestep.toFixed(2) + "ms)");
        }

        /**
         * [Read-only] Time step per logic frame (milliseconds).
         * e.g., 60fps = 16.666ms.
         */
        public static function get logicTimestep():Number
        {
            return _logicTimestep;
        }
    }
}
```

**Notes**

- If compatibility issues arise in your project, add rendering exceptions as needed.

**Basic Principles**

- We all know that in Flash projects using Starling, traditional CPU rendering is on a layer above Starling, and once GPU rendering starts, the Flash project frame limit increases from 60fps to match the refresh rate (e.g., can reach 400fps on a 400hz monitor).

- So, let's create a hybrid rendering solution for games:
    - For **simple static content**, like high-resolution background images, or simply moving scene images, I plan to use **Starling for rendering**.
    - For **complex dynamic content**, like animations nested within animations (e.g., a gun firing animation bound to a character's hand animation), we will use the traditional Flash CPU method for rendering. However, we will forcibly hide all traditional clips on the CPU rendering layer (visible=false). Only when a flash.display.MovieClip updates (i.e., a frame change in the movie clip or its sub-clips) will we update and draw the bitmap data as a display texture, which is then rendered by Starling.

- At this point, some might ask:
    - "Won't the Starling framework cause performance explosions if it doesn't use texture atlases and uploads textures at high frequency?"
    - "How to put it? This framework isn't intended for developing professional applications. For personal-level projects, if you can ensure minimal dynamic updates and control texture size (within a few hundred pixels), I believe it won't affect performance.
    Moreover, the framework I've built includes some performance optimization algorithms to address some of your concerns."

- So, essentially, what I've actually done is the following:
    - **Logic-driven control**
        - For example, some intended animations can only play at 60fps.
        - Some logic code can only execute at 60fps.
        - After using the framework, all logic and animations must be driven by the new 60-frame logic.
        - The program's running effect/animation effect should not differ due to subjective device differences (screen refresh rate).

    - **Stage monitoring**
        - Generate a real-time managed scene structure tree for the traditional Flash Stage.
        - Each node on the scene tree corresponds to a flash.display.DisplayObject object and stores all its states (e.g., currentFrame, visible, alpha, x, y, scaleX, scaleY, rotation, etc.). Most importantly, **anchor point information**.
        - Traverse and inspect the scene tree, comparing each sub-clip for changes. **Changes are of two types**:
            - **1. Morphological changes (movie clip frame number, sub-clip set changes, content changes, etc.)**
            - **2. Property value changes (transform property changes, synchronize values only).**

    - **Starling rendering**
        - For the real-time managed scene tree generated from the traditional Flash stage, the Starling stage must synchronize changes that occur on the scene tree's movie clips in real-time to the Starling stage.
        - The layer order of all starling.display.DisplayObject objects within the same parent clip can be displayed and sorted according to the childrenIndex value synchronized from traditional clips.

    - **Texture cache management**
        - To reduce DrawCalls, this framework uses the MaxRects algorithm for 2D space UV bin packing.
        - Generate a corresponding unique hash string for each frame/each DisplayObject object in the scene.

    - **Input event forwarding**
        - Since all content on the CPU layer is hidden, mouse click events registered on them become invalid.
        - The input forwarder I designed can forward mouse input events to the corresponding flash.display.DisplayObject.

**Framework Structure**

- Package/class structure:
- **fse**
    - **core package**
        - **FSE** (Core static class, interface encapsulation)
        - **FSE_Kernel** (The true body of the core static class)
        - **FSE_Manager** (Does all the heavy lifting, this class needs instantiation, uses singleton pattern)
        - **FSE_Input** (Input event forwarder)
    - **display package**
        - **Watcher** (Scene tree monitoring)
        - **Node** (Stores detailed information for a single movie clip and contains child Nodes)
        - **Scanner** (Used to scan the scene tree on the traditional stage)
        - **Controller** (Animation clip logic controller)
        - **StatusSaver** (State saver)
    - **events package**
        - **FSE_Event** (This doesn't have much effect, just defines some event constants, e.g., FIX_ENTER_FRAME)
    - **conf package**
        - **Config** (Configuration class)
    - **starling package**
        - **StarlingMain** (Initializes the Starling stage)
        - **StarlingVO** (Starling movie clip root)
        - **StarlingManager** (Responsible for synchronization and management)
    - **cache package**
        - **AtlasPage** (Atlas page manager)
        - **CacheManager** (Texture cache manager)
        - **Cache** (Texture cache entity class)
    - **utils package**
        - **Hash** (BitmapData fast hash)
        - **MD5** (Hash encryption)

**Contact the Author**

- Author: undefined (An aspiring independent game developer)
- WeChat: hbx098hbx123 (Welcome to make friends)
- Email: 2199182141@qq.com
- You can add the author on WeChat to report bugs or give suggestions.

---
> Wishing everyone success in the Year of the Horse, 2026. **Code may age, but the heart of creation remains forever young.**\
> If this framework allows you, someday in the future, to create what you envision more lightly and freely, that is its entire purpose.\
> Thanks to AS3, and thanks to you who are still here.\
> **January 29, 2026**\
> On a day just before spring is about to bloom.
