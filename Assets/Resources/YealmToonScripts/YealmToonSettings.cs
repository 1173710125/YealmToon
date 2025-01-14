using System;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenu("YealmToon/GlobalSettings")]
public class YealmToonSettings : VolumeComponent, IPostProcessComponent
{
    public ClampedFloatParameter shadowThreshold = new ClampedFloatParameter(0.5f, 0f, 1f);


    public bool IsActive()
    {
        return true;
    }

    public bool IsTileCompatible()
    {
        return false;
    }
}
