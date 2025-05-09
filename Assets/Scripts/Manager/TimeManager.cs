using UnityEngine;
using System;
using System.Collections.Generic;

public class TimerManager : MonoBehaviour
{
    public static TimerManager Instance { get; private set; }

    private class Timer
    {
        public int      id;
        public float    timeLeft;   // 剩余时间
        public float    interval;   // 重复间隔
        public bool     repeat;
        public Action   callback;
    }

    private readonly List<Timer> _timers = new List<Timer>();
    private int _nextId = 1;

    void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    void Update()
    {
        float dt = Time.deltaTime;
        for (int i = _timers.Count - 1; i >= 0; i--)
        {
            var t = _timers[i];
            t.timeLeft -= dt;
            if (t.timeLeft <= 0f)
            {
                try
                {
                    t.callback?.Invoke();
                }
                catch (Exception ex)
                {
                    Debug.LogError($"[TimerManager] Callback error (id={t.id}): {ex}");
                }

                if (t.repeat)
                {
                    t.timeLeft += t.interval;  // 支持累计误差补偿
                }
                else
                {
                    _timers.RemoveAt(i);
                }
            }
        }
    }

    /// <summary>
    /// 注册一次性定时器
    /// </summary>
    public int ScheduleOnce(float delay, Action callback)
    {
        return ScheduleInternal(delay, 0f, false, callback);
    }

    /// <summary>
    /// 注册重复定时器（<paramref name="interval"/> 秒间隔）
    /// </summary>
    public int ScheduleRepeating(float interval, Action callback)
    {
        return ScheduleInternal(interval, interval, true, callback);
    }

    /// <summary>
    /// 取消定时器
    /// </summary>
    public void Cancel(int id)
    {
        for (int i = _timers.Count - 1; i >= 0; i--)
        {
            if (_timers[i].id == id)
            {
                _timers.RemoveAt(i);
                return;
            }
        }
    }

    private int ScheduleInternal(float delay, float interval, bool repeat, Action callback)
    {
        if (delay < 0f) delay = 0f;
        var t = new Timer
        {
            id        = _nextId++,
            timeLeft  = delay,
            interval  = interval,
            repeat    = repeat,
            callback  = callback
        };
        _timers.Add(t);
        return t.id;
    }
}
