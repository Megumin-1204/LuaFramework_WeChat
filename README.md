Assets/  
├── **Lua/**                       <!-- 全部 Lua 脚本 -->  
│   ├── **Core/**                  <!-- 框架核心模块 -->  
│   │   ├── `Class.lua`            <!-- 基础类定义与继承系统 -->  
│   │   ├── `EventManager.lua`     <!-- 自定义事件总线 -->  
│   │   └── `ModuleManager.lua`    <!-- 模块管理器，控制模块生命周期 -->
│   ├── **Third/**                 <!-- 第三方 Lua 库 -->  
│   │   └── `Json.lua`             <!-- JSON 编解码 -->  
│   └── **UI/**                    <!-- 各面板的 Lua 脚本 -->  
│       ├── `BasePanel.lua`        <!-- 面板基类 -->  
│       ├── `UIMgr.lua`            <!-- Lua 封装的 UI 管理接口 -->  
│       ├── `TestPanel.lua`        <!-- 示例面板逻辑 -->  
│       ├── `UILayer.lua`      <!-- 定义 UI 分层（底/中/顶层） -->  
│       ├── `UIPool.lua`       <!-- UI 对象池管理 -->  
│       └── `UIStack.lua`      <!-- 界面栈管理（入栈/出栈/回退） -->  
│  
├── **Scripts/**                   <!-- Unity C# 脚本 -->  
│   ├── `GameRoot.cs`              <!-- 游戏入口，Lua 环境初始化 -->  
│   ├── `XLuaGenConfig.cs`         <!-- XLua 绑定生成配置 -->  
│   ├── **Base/**                  <!-- 公共基础脚本 -->  
│   └── **Manager/**               <!-- 各类管理器 -->  
│       ├── `UIManager.cs`         <!-- Resources 异步加载 & 面板管理 -->  
│       ├── `WeChatManager.cs`     <!-- 微信平台集成 -->  
│       └── `UIMaskManager.cs`     <!-- UI 遮罩层管理 -->  
│  
├── **Resources/**                 <!-- Unity Resources（运行时加载） -->  
│   └── **UI/**                    <!-- 放 `Resources.LoadAsync("UI/…")` 的 Prefab、图集等 -->  
│  
├── **Prefabs/**                   <!-- 非 Resources 的预制体，手动/打包加载 -->  
│  
├── **XLua/**                      <!-- XLua 生成的绑定代码（LuaBinder、wraps 等） -->  
│  
├── **Plugins/**                   <!-- 第三方 Unity 插件（DLL、SO 等） -->  
│  
├── **Arts/**                      <!-- 美术资源 -->  
│   ├── **Fonts/**                 <!-- 字体文件 -->  
│   ├── **Sprites/**               <!-- 精灵图集及单张 -->  
│   └── **Textures/**              <!-- 大纹理、RawImage 用图 -->  
│  
├── **3rd/**                       <!-- 原生第三方库（其他语言/框架） -->  
│  
└── **Scenes/**                    <!-- Unity 场景 -->  
    └── `Main.unity`               <!-- 主场景入口 -->  
