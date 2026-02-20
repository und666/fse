package fse.display
{
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import fse.core.FSE;
	import fse.conf.*;
import fse.core.FSE_Manager;

/**
	 * 动画控制器
	 * 职责：接管 Flash 原生的 play/stop，由 FSE 统一驱动帧序列
	 */
	public class Controller
	{

		public function Controller()
		{
			
		}
		
		//注入方法
		public var getNode:Function;
		public var scanContainer:Function;
		
		
		/**
		 * 注册一个 MC 到控制器 (由 Watcher 发现新对象时调用)
		 */
		public function register(target:MovieClip):void
		{
			if (!target)return;
			// 1. 记录到活跃列表 (StatusSaver 管理)
			StatusSaver.activeObjects[target] = true;
			target.stop();
			if(Config.STOP_ALL && !StatusSaver.isPlaying(target)){
				stop(target as MovieClip);
			}
		}
		
		/**
		 * 注销 MC (由 Watcher 移除对象时调用)
		 */

		public function unregister(mc:MovieClip):void
		{
			if (!mc) return;
			// 只从活跃列表移除，但不删除 StatusSaver 里的设置 (以防只是搬运)
			delete StatusSaver.activeObjects[mc];
		}

		/**
		 * API: 让某个 MC 播放
		 */
		public function play(mc:MovieClip):void
		{
			if (mc)
			{
				StatusSaver.setPlayState(mc, true);
				if(FSE.noGPU)mc.play();
			}
		}
		
		
		/**
		 * API: 让某个 MC 暂停
		 */

		public function stop(mc:MovieClip):void
		{
			if (mc)
			{
				StatusSaver.setPlayState(mc, false);
				mc.stop(); // 确保定格
			}
		}
	
		public function gotoAndStop(mc:MovieClip,frame:uint):void
		{
			if (mc)
			{
				goto(mc,frame);
				stop(mc);
			}
		}
		
		
		public function gotoAndPlay(mc:MovieClip,frame:uint):void
		{
			if (mc)
			{
				goto(mc,frame);
				play(mc);
			}
		}
		
		public function goto(mc:MovieClip,frame:uint):void {
			mc.gotoAndStop(frame);
			//这里有一个比较难理解的点,
			//当影片剪辑发生跳转,由于我们构建的影子树上的容器剪辑始终不隐藏,所以会在CPU层的某一帧渲染出一个图形导致闪现
			//所以跳转后得让影片剪辑马上渲染
			//hideAll(mc);
			
			var node:Node = FSE_Manager.watcher.getNode(mc);
			if(node) {
				FSE_Manager.scanner.scanContainer(mc,node,false);
				
				/*if (!FSE.noGPU && getNode != null) {
					node.updateFrame();
				}*/
			}
		}
		
		public function isplay(mc:MovieClip):Boolean
		{
			return StatusSaver.isPlaying(mc);
		}
		/**
		 * 设置逻辑可见性
		 * @param mc 目标影片剪辑
		 * @param value true=显示(默认), false=隐藏
		 */
		public function setVisible(target:DisplayObject,value:Boolean):void
		{
			// 1. 记录逻辑状态 (给 Starling Node 看)
			StatusSaver.setLogicalVisible(target, value);
			if(FSE.noGPU)target.visible=value;
		}


		/**
		 * 获取逻辑可见性
		 * Watcher 会调用这个方法来决定是否要把该对象加入影子树
		 */
		public function isVisible(mc:DisplayObject):Boolean
		{
			return StatusSaver.getLogicalVisible(mc);
		}
		
		
		/**
		 * [核心驱动] 每一帧由 FSE_Manager 调用
		 * 负责手动推演所有正在播放的 MC 的帧数
		 */
		public function advanceTime():void
		{
			// 遍历 StatusSaver 中的活跃对象
			for (var key:Object in StatusSaver.activeObjects)
			{
				var target:DisplayObject = key as DisplayObject;
				// 安全检查：如果对象已经被GC或者销毁
				if (! target || ! target.stage)
				{
					delete StatusSaver.activeObjects[key];
					continue;
				}
				//动画控制
				var mc:MovieClip = target as MovieClip;
				if(mc){
					// 检查是否应该播放 (通过 ID 查表)
					if (StatusSaver.isPlaying(mc))
					{
						//播放逻辑
						// --- 帧推演逻辑 ---
						if (mc.totalFrames > 1)
						{
							if (mc.currentFrame < mc.totalFrames)
							{
								// 还没到头，往后走一帧
								goto(mc,mc.currentFrame + 1);
							}
							else
							{
								// 到了末尾，循环回第一帧
								goto(mc,1);
							}
						}
					}
				}else{
					//hide(target);
				}
			}
		}
	}
}