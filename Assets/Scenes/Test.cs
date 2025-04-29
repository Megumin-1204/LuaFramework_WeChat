using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        var go = Resources.Load<GameObject>("UI/TestPanel");
        Debug.Log($"[资源测试] Resources.Load<GameObject>(\"UI/TestPanel\") 返回：{go}");
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
