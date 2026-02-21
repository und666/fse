package fse.display
{
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.text.TextField;
	
	import fse.core.FSE;
	import fse.conf.*;
import fse.utils.FSEProfiler;

/**
	 * 场景监控器
	 */
	public class Watcher
	{
		// [修改] 改为 internal 以便 Scanner 访问，或者你也可以使用 getter
		internal var _nodeMap:Dictionary;
		internal var _rootNode:Node;
		internal var _controller:Controller;
		internal var _scanner:Scanner;
		public function Watcher(controller:Controller,scanner:Scanner)
		{
			_nodeMap = new Dictionary(true);
			_controller = controller;
			// 此时 scanContainer 已经移入 Scanner，这里通过闭包或代理关联
			// 如果 controller 需要直接调用 scan，建议修改 controller 逻辑
			// 或者在这里做一个代理:
			_controller.scanContainer = this.scan;
			_controller.getNode = getNode;
			_scanner=scanner;
			_scanner.setWatcher(this);
		}
		
		// [新增] 供 Scanner 访问的 getter/setter
		internal function get nodeMap():Dictionary { return _nodeMap; }
		internal function get controller():Controller { return _controller; }
		
		internal function get rootNode():Node { return _rootNode; }
		internal function set rootNode(v:Node):void { _rootNode = v; }
		
		
		
		public function setNodeCacheConfig(target:DisplayObject, enable:Boolean):void
		{
			// 直接存入 StatusSaver，这样 Node 无论何时创建都能读到配置
			StatusSaver.setCacheConfig(target, enable);
			
			var node:Node = _nodeMap[target];
			
			if (node)
			{
				// 情况1: Node 已经存在，直接设置
				node.enableCache = enable;
				if(Config.TRACE_WATCHER)trace("[Watcher] 立即设置缓存策略: " + target.name + " = " + enable);
			}
		
			// --- 2. [新增] 递归处理所有子对象 ---
			// 无论 Node 是否存在，只要它是 Flash 容器，我们就遍历它的原生子对象
			if (target is DisplayObjectContainer)
			{
				var container:DisplayObjectContainer = target as DisplayObjectContainer;
				var num:int = container.numChildren;
				for (var i:int = 0; i < num; i++)
				{
					try {
						var child:DisplayObject = container.getChildAt(i);
						// 递归调用自己，这样子节点的子节点也会被设置
						setNodeCacheConfig(child, enable);
					} catch(e:Error) {
						// 防止个别奇怪的对象访问出错
					}
				}
			}
		}
	
		// [新增] 公开获取 Node 的方法，供 FSE_Manager 调用
        public function getNode(target:DisplayObject):Node
        {
            return _nodeMap[target];
        }
		
		public function addIgnore(target:DisplayObject):void
		{
			if (target) {
				//trace("忽略",target.name);
				// [修改] 存入 StatusSaver
				StatusSaver.setIgnore(target, true);
				var node:Node = getNode(target);
				if (node) {
					if(node.enable()){
					//如果是活动节点 则卸载等等待下一帧死节点的自动创建
					//node 相关操作 对于已经绑定成功的Node节点进行遍历恢复操作
					node.restoreVisible();
					
					//这里先删除一遍,节点会在下一帧重建，但不会再创建纹理
					node.dispose();
					}
				}
				
				function traverse(container:DisplayObjectContainer):void {
					//子剪辑忽略
					for (var i:int = 0; i < container.numChildren; i++) {
						var child:DisplayObject = container.getChildAt(i);
						addIgnore(child);
					}
				}
				
				if(target is DisplayObjectContainer){
					//如果是容器剪辑
					//给子肉剪辑设置特例
					traverse(target as DisplayObjectContainer);
				}else{
					//这里的逻辑,我想的是,如果当前节点不是容器节点,在获得例外后直接删除节点并恢复显示
					/*
					if(node){
						var parentNode:Node = node.parentNode;
						if(parentNode){
							var j:int = parentNode.children.indexOf(node);
							if (j !== -1) { 
								parentNode.children.splice(j, 1);
							}
						}
						node.dispose();
						delete _nodeMap[node.source];
					}
					*/
					
				}
				
				if(Config.TRACE_WATCHER)trace("[FSE Watcher] 🚫 忽略对象: " + target.name);
			}
		}
		
		public function removeIgnore(target:DisplayObject):void
		{
			if (target)
			{
				StatusSaver.setIgnore(target, false);
				var node:Node = getNode(target);
				if (node) {
					node.dispose();
				}
				
				function traverse(container:DisplayObjectContainer):void {
					//子剪辑忽略
					for (var i:int = 0; i < container.numChildren; i++) {
						var child:DisplayObject = container.getChildAt(i);
						removeIgnore(child);
					}
				}
				
				if(target is DisplayObjectContainer){
					//如果是容器剪辑
					//给子肉剪辑设置特例
					traverse(target as DisplayObjectContainer);
				}else{
					//这里的逻辑,我想的是,如果当前节点不是容器节点,在获得例外后直接删除节点并恢复显示
					/*
					if(node){
						var parentNode:Node = node.parentNode;
						if(parentNode){
							var j:int = parentNode.children.indexOf(node);
							if (j !== -1) {
								parentNode.children.splice(j, 1);
							}
						}
						node.dispose();
						delete _nodeMap[node.source];
					}
					*/
				}
			}
		}
		
		public function scan(targetRoot:DisplayObjectContainer):void
		{
			FSEProfiler.begin("Scanner_scan");
			_scanner.scan(targetRoot);
			FSEProfiler.end("Scanner_scan");
		}
		
		public function isIgnore(mc:DisplayObject):Boolean{
			// [修改] 查询 StatusSaver
			if(StatusSaver.isIgnore(mc)){
				return true;
			}
			return false;
		}
		
		
		
		
		
		// [修改] 改为 internal 供 Scanner 调用
		internal function createNode(target:DisplayObject , parentNode:Node):Node
		{
			var enableCache1:Boolean = StatusSaver.getCacheConfig(target);
			var enableCache2:Boolean = false
			if(target.parent){
				enableCache2 = StatusSaver.getCacheConfig(target.parent);
			}
			var enableCache:Boolean = enableCache1 || enableCache2;
			
			if(target is TextField){
				enableCache=false;
			}
			var node:Node = new Node(target, parentNode , deleteNodeFromMap, enableCache);
			_nodeMap[target] = node;
			return node;
		}
		
		// [修改] 改为 internal 供 Scanner 调用
		internal function deleteNodeFromMap(target:DisplayObject):void
		{
			if (target && _nodeMap[target])
			{
				delete _nodeMap[target];
			}
		}
	}
}