using System.IO;  // 新增的命名空间
using UnityEngine;
using XLua;

public class GameRoot : MonoBehaviour
{
    private LuaEnv luaEnv;

    void Awake()
    {
        DontDestroyOnLoad(gameObject);
        luaEnv = new LuaEnv();
        
        luaEnv.AddLoader((ref string filepath) => {
            string path = Application.dataPath + "/Lua/" + filepath.Replace('.', '/') + ".lua";
            
            if (File.Exists(path)) {
                return File.ReadAllBytes(path);
            } else {
                Debug.LogError($"Lua file not found: {path}");
                return null;
            }
        });
        
        luaEnv.DoString("require 'Main'");
    }

    void OnDestroy()
    {
        luaEnv.Dispose();
    }
}